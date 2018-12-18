#import "MJDisableMuteManager.h"
#import "MJUserDefaults.h"


@interface MJDisableMuteManager ()
@property(nonatomic, weak) id <MJDisableMuteManagerDelegate> delegate;
@property(nonatomic, strong) MJUserDefaults *userDefaults;
@end

@implementation MJDisableMuteManager

- (instancetype)initWithDelegate:(id<MJDisableMuteManagerDelegate>)delegate
                    userDefaults:(MJUserDefaults *)userDefaults
{
    self = [super init];
    if (!self) return nil;

    self.delegate = delegate;
    self.userDefaults = userDefaults;

    [self.delegate disableMuteManager_updateDisabledMuting:[self.userDefaults isMutingDisabled]];

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
    [self.userDefaults setScheduledTimeToEnableMuting:fireDate];
}

- (void)cancelEnableMutingTimer
{
    [self.userDefaults setScheduledTimeToEnableMuting:0];
}

- (void)enableMutingTimerFired
{
    NSTimeInterval timeToEnableMuting = [self.userDefaults getScheduledTimeToEnableMuting];
    if (timeToEnableMuting != 0 && [[NSDate date] timeIntervalSince1970] > timeToEnableMuting) {
        NSLog(@"Enabling muting (from timer)");
        [self.userDefaults setScheduledTimeToEnableMuting:0];
        [self enableMuting];
    }
}

- (void)enableMuting
{
    [self cancelEnableMutingTimer];
    [self.userDefaults setMutingDisabled:NO];
    [self.delegate disableMuteManager_updateDisabledMuting:NO];
}

- (void)disableMuting
{
    [self cancelEnableMutingTimer];
    [self.userDefaults setMutingDisabled:YES];
    [self.delegate disableMuteManager_updateDisabledMuting:YES];
}

@end
