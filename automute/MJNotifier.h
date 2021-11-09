#import <Foundation/Foundation.h>

@class MJUserDefaults;

@interface MJNotifier : NSObject

- (instancetype)initWithUserDefaults:(MJUserDefaults *)userDefaults;

- (void)showHeadphonesDisconnectedMuteNotification;
- (void)showSleepMuteNotification;
- (void)showLockMuteNotification;

@end
