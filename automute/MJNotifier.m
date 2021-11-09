#import "MJNotifier.h"
#import "MJUserDefaults.h"

@interface MJNotifier() <NSUserNotificationCenterDelegate>
@property(nonatomic, strong) MJUserDefaults *userDefaults;
@end

@implementation MJNotifier

- (instancetype)initWithUserDefaults:(MJUserDefaults *)userDefaults
{
    self = [super init];
    if (!self) return nil;

    self.userDefaults = userDefaults;

    return self;
}

- (void)showHeadphonesDisconnectedMuteNotification
{
    [self showNotificationWithTitle:@"Headphones Disconnected" body:@"Sound Muted."];
}

- (void)showSleepMuteNotification
{
    [self showNotificationWithTitle:@"Woke up from sleep" body:@"Sound Muted."];
}

- (void)showLockMuteNotification
{
    [self showNotificationWithTitle:@"Unlocked" body:@"Sound Muted."];
}

- (void)showNotificationWithTitle:(NSString *)title
                             body:(NSString *)body
{
    if (![self.userDefaults areMuteNotificationsEnabled]) return;

    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = body;

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
