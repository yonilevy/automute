#import <Foundation/Foundation.h>


@interface MJUserDefaults : NSObject

-(void)setSawWelcomeScreen;
-(BOOL)didSeeWelcomeScreen;

- (void)setSawLaunchAtLoginPopup;
- (BOOL)didSeeLaunchAtLoginPopup;

- (BOOL)isMutingDisabled;
- (void)setMutingDisabled:(BOOL)b;

- (void)setScheduledTimeToEnableMuting:(NSTimeInterval)date;
- (NSTimeInterval)getScheduledTimeToEnableMuting;

- (BOOL)isSetToMuteOnSleep;
- (void)setMuteOnSleep:(BOOL)muteOnSleep;

- (BOOL)isSetToMuteOnLock;
- (void)setMuteOnLock:(BOOL)muteOnLock;

- (BOOL)isSetToMuteOnHeadphones;
- (void)setMuteOnHeadphones:(BOOL)muteOnHeadphones;

- (BOOL)areMuteNotificationsEnabled;
- (void)setMuteNotificationsEnabled:(BOOL)muteNotificationsEnabled;
@end
