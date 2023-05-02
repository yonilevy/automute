#import "MJDisableMuteManager.h"
#import "MJUserDefaults.h"


@interface MJDisableMuteManager ()
@property(nonatomic, weak) id <MJDisableMuteManagerDelegate> delegate;
@end

@implementation MJDisableMuteManager

- (instancetype)initWithDelegate:(id<MJDisableMuteManagerDelegate>)delegate
{
    self = [super init];
    if (!self) return nil;

    self.delegate = delegate;

    [self.delegate disableMuteManager_updateDisabledMuting:MJUserDefaults.shared.isMutingDisabled];

    [NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(enableMutingTimerFired)
                                   userInfo:nil
                                    repeats:YES];
    [self enableMutingTimerFired];

    return self;
}

- (void)enableMutingIn:(NSUInteger)hours
{
    [self cancelEnableMutingTimer];
    NSTimeInterval fireDate = [[NSDate date] timeIntervalSince1970] + (hours * 60 * 60);
    [MJUserDefaults.shared setScheduledTimeToEnableMuting:fireDate];
}

- (void)cancelEnableMutingTimer
{
    [MJUserDefaults.shared setScheduledTimeToEnableMuting:0];
}

- (void)enableMutingTimerFired
{
    NSTimeInterval timeToEnableMuting = [MJUserDefaults.shared getScheduledTimeToEnableMuting];
    if (timeToEnableMuting != 0 && [[NSDate date] timeIntervalSince1970] > timeToEnableMuting) {
        NSLog(@"Enabling muting (from timer)");
        [MJUserDefaults.shared setScheduledTimeToEnableMuting:0];
        [self enableMuting];
    }
}

- (void)enableMuting
{
    [self cancelEnableMutingTimer];
    [MJUserDefaults.shared setMutingDisabled:NO];
    [self.delegate disableMuteManager_updateDisabledMuting:NO];
}

- (void)disableMuting
{
    [self cancelEnableMutingTimer];
    [MJUserDefaults.shared setMutingDisabled:YES];
    [self.delegate disableMuteManager_updateDisabledMuting:YES];
}

@end
