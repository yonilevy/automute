#import "AppDelegate.h"
#include "MJHeadphoneDetector.hpp"
#import "MJMenuBarController.h"
#import "MJUserDefaults.h"
#import "MJDisableMuteManager.h"
#import "StartAtLoginController.h"
#import "MJSoundMuter.h"
#import "MJConstants.h"
#import "MJNotifier.h"

@interface AppDelegate () <MJMenuBarControllerDelegate, MJDisableMuteManagerDelegate>

@property (nonatomic) SoundMuter *soundMuter;
@property (nonatomic) HeadPhoneDetector *headphoneDetector;
@property (nonatomic, strong) MJUserDefaults *userDefaults;
@property(nonatomic, strong) MJNotifier *notifier;
// Note: nil when the menu bar icon is hidden.
@property(nonatomic, strong) MJMenuBarController *menuBarController;
@property(nonatomic, strong) MJDisableMuteManager *disableMuteManager;
@property(nonatomic, strong) StartAtLoginController *startAtLoginController;
@property(nonatomic) BOOL isMutingDisabled;
@property(nonatomic) BOOL didMuteOnLastSleep;
@property(nonatomic) BOOL didMuteOnLastLock;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];

    BOOL didLaunchAtLogin = [self checkAndClearDidLaunchAtLogin];

    self.soundMuter = new SoundMuter();
    self.notifier = [[MJNotifier alloc] initWithUserDefaults:self.userDefaults];

    self.headphoneDetector = new HeadPhoneDetector();
    __weak AppDelegate *weakSelf = self;
    self.headphoneDetector->listen(^(bool headphonesConnected) {
        [weakSelf onHeadphoneStateChangedTo:headphonesConnected];
    });

    self.userDefaults = [[MJUserDefaults alloc] init];
    // If the app was launched by the user (rather than auto launch
    //  on login) -> force show the menu bar icon.
    if (!didLaunchAtLogin) {
        [self.userDefaults setMenuBarIconHidden:NO];
    }

    self.menuBarController = self.userDefaults.isMenuBarIconHidden
            ? nil
            : [self buildMenuBarController];
    self.disableMuteManager = [[MJDisableMuteManager alloc] initWithDelegate:self userDefaults:self.userDefaults];
    self.startAtLoginController = [[StartAtLoginController alloc] initWithIdentifier:MJ_HELPER_BUNDLE_ID];

    if (![self.userDefaults didSeeWelcomeScreen]) {
        [self.menuBarController showWelcomePopup];
    } else if (![self.userDefaults didSeeLaunchAtLoginPopup]) {
        [self.menuBarController showLaunchAtLoginPopup];
    }

    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
               selector:@selector(willSleep)
                   name:NSWorkspaceWillSleepNotification
                 object:nil];

    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
               selector:@selector(didWake)
                   name:NSWorkspaceDidWakeNotification
                 object:nil];

    [[NSDistributedNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(didLock)
                   name:@"com.apple.screenIsLocked"
                 object:nil];

    [[NSDistributedNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(didUnlock)
                   name:@"com.apple.screenIsUnlocked"
                 object:nil];
}

- (MJMenuBarController *)buildMenuBarController
{
    return [[MJMenuBarController alloc]
            initWithUserDefaults:self.userDefaults
                        delegate:self
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
    if ([self.userDefaults isMenuBarIconHidden]) {
        [self.userDefaults setMenuBarIconHidden:NO];
        self.menuBarController = [self buildMenuBarController];
    }

    return NO;
}

- (void)willSleep
{
    self.didMuteOnLastSleep =
            [self menuBarController_isSetToMuteOnSleep] && !self.headphoneDetector->areHeadphonesConnected() && [self mute];
}

- (void)didWake
{
    if (self.didMuteOnLastSleep) {
        [self.notifier showSleepMuteNotification];
    }
}

- (void)didLock
{
    self.didMuteOnLastLock =
            [self menuBarController_isSetToMuteOnLock] && !self.headphoneDetector->areHeadphonesConnected() && [self mute];
}

- (void)didUnlock
{
    if (self.didMuteOnLastLock) {
        [self.notifier showLockMuteNotification];
    }
}

- (void)onHeadphoneStateChangedTo:(bool)connected
{
    [self.menuBarController updateMenuIcon:connected];
    if (!connected && [self menuBarController_isSetToMuteOnHeadphones]) {
        __weak AppDelegate *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if ([weakSelf mute]) {
                [weakSelf.notifier showHeadphonesDisconnectedMuteNotification];
            }
        });
    }
}

- (BOOL)mute
{
    if (self.isMutingDisabled) return false;

    self.soundMuter->mute();
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
    delete self.soundMuter;
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
    return self.userDefaults.isSetToMuteOnSleep;
}

- (void)menuBarController_setMuteOnSleep:(BOOL)muteOnSleep
{
    [self.userDefaults setMuteOnSleep:muteOnSleep];
}

- (BOOL)menuBarController_isSetToMuteOnLock
{
    return self.userDefaults.isSetToMuteOnLock;
}

- (void)menuBarController_setMuteOnLock:(BOOL)muteOnLock
{
    [self.userDefaults setMuteOnLock:muteOnLock];
}

- (BOOL)menuBarController_isSetToMuteOnHeadphones
{
    return self.userDefaults.isSetToMuteOnHeadphones;
}

- (void)menuBarController_setMuteOnHeadphones:(BOOL)muteOnHeadphones
{
    [self.userDefaults setMuteOnHeadphones:muteOnHeadphones];
}

- (void)disableMuteManager_updateDisabledMuting:(BOOL)isDisabled
{
    self.isMutingDisabled = isDisabled;
    [self.menuBarController updateMenuIcon:self.headphoneDetector->areHeadphonesConnected()];
}

- (void)menuBarController_toggleMuteNotifications
{
    [self.userDefaults setMuteNotificationsEnabled:![self.userDefaults areMuteNotificationsEnabled]];
}

- (void)menuBarController_toggleHideMenuBarIcon
{
    if ([self.userDefaults isMenuBarIconHidden]) {
        NSLog(@"Weird, how did you manage to toggle while hidden?");
        return;
    }

    [self.userDefaults setMenuBarIconHidden:YES];
    [self.menuBarController forceRemoveFromMenuBar];
    self.menuBarController = nil;
}

@end
