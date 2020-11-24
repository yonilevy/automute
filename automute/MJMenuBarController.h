#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class MJUserDefaults;

@protocol MJMenuBarControllerDelegate
- (void)menuBarController_disableMutingFor:(NSInteger)hours;
- (void)menuBarController_enableMuting;
- (void)menuBarController_quit;
- (BOOL)menuBarController_isSetToLaunchAtLogin;
- (void)menuBarController_setLaunchAtLogin:(BOOL)launchAtLogin;
- (BOOL)menuBarController_isSetToMuteOnSleep;
- (void)menuBarController_setMuteOnSleep:(BOOL)muteOnSleep;
- (BOOL)menuBarController_isSetToMuteOnLock;
- (void)menuBarController_setMuteOnLock:(BOOL)muteOnLock;
- (BOOL)menuBarController_isSetToMuteOnHeadphones;
- (void)menuBarController_setMuteOnHeadphones:(BOOL)muteOnHeadphones;
- (void)menuBarController_toggleMuteNotifications;
@end


@interface MJMenuBarController : NSObject

- (instancetype)initWithUserDefaults:(MJUserDefaults *)userDefaults
                            delegate:(id<MJMenuBarControllerDelegate>)delegate;

- (void)showWelcomePopup;
- (void)showLaunchAtLoginPopup;
- (void)showHeadphonesDisconnectedMuteNotification;
- (void)showSleepMuteNotification;
- (void)showLockMuteNotification;
- (void)updateMenuIcon:(BOOL)headphonesConnected;
- (void)terminate;
@end
