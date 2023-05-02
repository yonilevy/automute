#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

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
- (void)menuBarController_toggleHideMenuBarIcon;
@end


@interface MJMenuBarController : NSObject

- (instancetype)initWithDelegate:(id<MJMenuBarControllerDelegate>)delegate
             headphonesConnected:(BOOL)headphonesConnected;

- (void)showWelcomePopup;
- (void)showLaunchAtLoginPopup;
- (void)updateMenuIcon:(BOOL)headphonesConnected;
- (void)forceRemoveFromMenuBar;
@end
