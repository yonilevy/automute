#import <Foundation/Foundation.h>

@class MJUserDefaults;

@protocol MJDisableMuteManagerDelegate
- (void)disableMuteManager_updateDisabledMuting:(BOOL)isDisabled;
@end

@interface MJDisableMuteManager : NSObject

- (instancetype)initWithDelegate:(id<MJDisableMuteManagerDelegate>)delegate
                    userDefaults:(MJUserDefaults *)userDefaults;
- (void)enableMuting;
- (void)disableMuting;
- (void)enableMutingIn:(NSUInteger)hours;
@end