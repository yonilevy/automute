#import "AppDelegate.h"
#include "MJHeadphoneDetector.hpp"
#import "MJMenuBarController.h"
#import "MJUserDefaults.h"
#import "MJDisableMuteManager.h"
#import "StartAtLoginController.h"
#import "MJConstants.h"
#import "MJNotifier.h"
#import "MJSystemEventObserver.h"
#import "MJAudioUtils.hpp"
#import "MJLog.h"

@interface AppDelegate () <MJMenuBarControllerDelegate, MJDisableMuteManagerDelegate, MJSystemEventHandlerDelegate>

@property (nonatomic) HeadPhoneDetector *headphoneDetector;
@property(nonatomic, strong) MJNotifier *notifier;
// Note: nil when the menu bar icon is hidden.
@property(nonatomic, strong) MJMenuBarController *menuBarController;
@property(nonatomic, strong) MJDisableMuteManager *disableMuteManager;
@property(nonatomic, strong) StartAtLoginController *startAtLoginController;
@property(nonatomic) BOOL isMutingDisabled;
@property(nonatomic, strong) MJSystemEventObserver *systemEventObserver;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];

    BOOL didLaunchAtLogin = [self checkAndClearDidLaunchAtLogin];

    self.notifier = [[MJNotifier alloc] init];

    self.headphoneDetector = new HeadPhoneDetector();
    __weak AppDelegate *weakSelf = self;
    self.headphoneDetector->listen(^(bool headphonesConnected) {
        [weakSelf onHeadphoneStateChangedTo:headphonesConnected];
    });

    /// If the app was launched by the user (rather than auto launch
    ///  on login) -> force show the menu bar icon.
    if (!didLaunchAtLogin) {
        [MJUserDefaults.shared setMenuBarIconHidden:NO];
    }

    self.menuBarController = MJUserDefaults.shared.isMenuBarIconHidden
            ? nil
            : [self buildMenuBarController];
    self.disableMuteManager = [[MJDisableMuteManager alloc] initWithDelegate:self];
    self.startAtLoginController = [[StartAtLoginController alloc] initWithIdentifier:MJ_HELPER_BUNDLE_ID];
    self.systemEventObserver = [[MJSystemEventObserver alloc] initWithDelegate:self];

    if (!MJUserDefaults.shared.didSeeWelcomeScreen) {
        [self.menuBarController showWelcomePopup];
    } else if (!MJUserDefaults.shared.didSeeLaunchAtLoginPopup) {
        [self.menuBarController showLaunchAtLoginPopup];
    }

    [self.systemEventObserver start];
}

- (MJMenuBarController *)buildMenuBarController
{
    return [[MJMenuBarController alloc] initWithDelegate:self
                                     headphonesConnected:self.headphoneDetector->areHeadphonesConnected()];
}

- (BOOL)checkAndClearDidLaunchAtLogin
{
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:MJ_SHARED_GROUP_ID];
    BOOL didLaunchAtLogin = [groupDefaults boolForKey:MJ_DID_LAUNCH_AT_LOGIN_KEY];
    [groupDefaults setBool:NO forKey:MJ_DID_LAUNCH_AT_LOGIN_KEY];
    [groupDefaults synchronize];
    return didLaunchAtLogin;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    // If the user relaunches the app -> force show the menu bar icon
    //  (that's the only way to make it reappear).
    if (MJUserDefaults.shared.isMenuBarIconHidden) {
        [MJUserDefaults.shared setMenuBarIconHidden:NO];
        self.menuBarController = [self buildMenuBarController];
    }

    return NO;
}

- (BOOL)systemEventsHandler_muteIfAppropriateForEvent:(MJSystemEvent)event
{
    if ([self doesUserWantMuteOnEvent:event]) {
        return [self tryMuteAllOutputDevices];
    } else {
        return false;
    }
}

- (void)systemEventsHandler_notifyMutedOnEvent:(MJSystemEvent)event
{
    /// We use a bit of delay to decrease the chance the OS isn't ready
    /// to display notifications. (happens a lot e.g. on manual sleep -> awake).
    __weak AppDelegate *weakSelf = self;
    int64_t delay = static_cast<int64_t>([self notificationDelayForEvent:event] * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), ^{
        [weakSelf showNotificationForEvent:event];
    });
}

- (BOOL)doesUserWantMuteOnEvent:(MJSystemEvent)event
{
    switch (event) {
        case MJSystemEventNone: return false;
        case MJSystemEventSleep: return MJUserDefaults.shared.isSetToMuteOnSleep;
        case MJSystemEventLock: return MJUserDefaults.shared.isSetToMuteOnLock;
        case MJSystemEventPowerOff: return MJUserDefaults.shared.isSetToMuteOnSleep;
    }
}

- (NSTimeInterval)notificationDelayForEvent:(MJSystemEvent)event
{
    switch (event) {
        case MJSystemEventNone: return 0.0;
        case MJSystemEventSleep: return 0.5;
        case MJSystemEventLock: return 0.3;
        case MJSystemEventPowerOff: return 0.0;
    }
}

- (void)showNotificationForEvent:(MJSystemEvent)event
{
    switch (event) {
        case MJSystemEventNone:
        case MJSystemEventPowerOff:
            break;
        case MJSystemEventSleep:
            [self.notifier showSleepMuteNotification];
            break;
        case MJSystemEventLock:
            [self.notifier showLockMuteNotification];
            break;
    }
}

- (void)onHeadphoneStateChangedTo:(bool)connected
{
    [self.menuBarController updateMenuIcon:connected];
    if (!connected && [self menuBarController_isSetToMuteOnHeadphones]) {
        /// - Here lies an OS weirdness: the output device has "officially" changed, but
        ///     attempting to mute it at this stage will fail. It seems to take the OS a short while
        ///     (lets call it T) before volume changes actually apply to the new device.
        /// - That time T varies widely (3X ; tens of milliseconds) depending on the specific
        ///     headphone model. For example, T(AirPods Pro 2) >> T(Sony WH-1000XM4) ¯\_(ツ)_/¯.
        /// - There is no way for us to query the OS whether T passed already (AFAIK).
        ///
        /// - So: if we mute too early, our mute has no effect and we fail entirely,
        ///     while if we mute too late, the Mac speakers would manage to produce some audible noise
        ///     prior to our mute -> a smaller but still very significant fail.
        ///
        /// - The only reasonable approach therefore is to try and mute many times, with tiny
        ///     intervals between attempts. That way we bring the late-mute delay to a minimum
        ///     (in practice, zero audible noise) while also ~never failing to mute by being too early.
        __weak AppDelegate *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf tryMuteDefaultOutputDeviceWithNumAttempts:30 attemptIntervalyMs:10];
        });
    }
}

- (void)tryMuteDefaultOutputDeviceWithNumAttempts:(int)attemptsLeft attemptIntervalyMs:(int64_t)intervalMs
{
    if (![self tryMuteDefaultOutputDevice]) {
        return;
    }

    /// This is the last attempt, we assume we succeeded by now, time to show the notification.
    if (attemptsLeft <= 1) {
        [self.notifier showHeadphonesDisconnectedMuteNotification];
        return;
    }

    __weak AppDelegate *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, intervalMs * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [weakSelf tryMuteDefaultOutputDeviceWithNumAttempts:attemptsLeft - 1 attemptIntervalyMs:intervalMs];
    });
}

- (BOOL)tryMuteDefaultOutputDevice
{
    if (self.isMutingDisabled) return false;

    OSStatus res = AudioUtils::mute(AudioUtils::fetchDefaultOutputDeviceId());
    MJLOG("Mute default output device -> %d\n", res);

    return true;
}

- (BOOL)tryMuteAllOutputDevices
{
    if (self.isMutingDisabled) return false;

    MJLOG("Mute all output devices:\n");
    for (const auto& deviceId : AudioUtils::fetchAllOutputDeviceIds()) {
        OSStatus res = AudioUtils::mute(deviceId);
        MJLOG("\tMute device %u -> %d\n", deviceId, res);
    }

    return true;
}

- (void)menuBarController_disableMutingFor:(NSInteger)hours
{
    [self.disableMuteManager disableMuting];
    if (hours < 0) return;

    [self.disableMuteManager enableMutingIn:(NSUInteger) hours];
}

- (void)menuBarController_enableMuting
{
    [self.disableMuteManager enableMuting];
}

- (void)menuBarController_quit
{
    delete self.headphoneDetector;
    [NSApp terminate:self];
}

- (BOOL)menuBarController_isSetToLaunchAtLogin
{
    return self.startAtLoginController.startAtLogin;
}

- (void)menuBarController_setLaunchAtLogin:(BOOL)launchAtLogin
{
    self.startAtLoginController.startAtLogin = launchAtLogin;
}

- (BOOL)menuBarController_isSetToMuteOnSleep
{
    return MJUserDefaults.shared.isSetToMuteOnSleep;
}

- (void)menuBarController_setMuteOnSleep:(BOOL)muteOnSleep
{
    [MJUserDefaults.shared setMuteOnSleep:muteOnSleep];
}

- (BOOL)menuBarController_isSetToMuteOnLock
{
    return MJUserDefaults.shared.isSetToMuteOnLock;
}

- (void)menuBarController_setMuteOnLock:(BOOL)muteOnLock
{
    [MJUserDefaults.shared setMuteOnLock:muteOnLock];
}

- (BOOL)menuBarController_isSetToMuteOnHeadphones
{
    return MJUserDefaults.shared.isSetToMuteOnHeadphones;
}

- (void)menuBarController_setMuteOnHeadphones:(BOOL)muteOnHeadphones
{
    [MJUserDefaults.shared setMuteOnHeadphones:muteOnHeadphones];
}

- (void)disableMuteManager_updateDisabledMuting:(BOOL)isDisabled
{
    self.isMutingDisabled = isDisabled;
    [self.menuBarController updateMenuIcon:self.headphoneDetector->areHeadphonesConnected()];
}

- (void)menuBarController_toggleMuteNotifications
{
    [MJUserDefaults.shared setMuteNotificationsEnabled:!MJUserDefaults.shared.areMuteNotificationsEnabled];
}

- (void)menuBarController_toggleHideMenuBarIcon
{
    if (MJUserDefaults.shared.isMenuBarIconHidden) {
        NSLog(@"Weird, how did you manage to toggle while hidden?");
        return;
    }

    [MJUserDefaults.shared setMenuBarIconHidden:YES];
    [self.menuBarController forceRemoveFromMenuBar];
    self.menuBarController = nil;
}

@end
