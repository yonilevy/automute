#import <Foundation/Foundation.h>

@protocol MJDisableMuteManagerDelegate
- (void)disableMuteManager_updateDisabledMuting:(BOOL)isDisabled;
@end

@interface MJDisableMuteManager : NSObject

- (instancetype)initWithDelegate:(id<MJDisableMuteManagerDelegate>)delegate;
- (void)enableMuting;
- (void)disableMuting;
- (void)enableMutingIn:(NSUInteger)hours;
@end