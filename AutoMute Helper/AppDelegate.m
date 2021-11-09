#import "AppDelegate.h"
#import "MJConstants.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self launchTopAppIfNotRunningAlready];
    [NSApp terminate:nil];
}

- (void)launchTopAppIfNotRunningAlready
{
    NSString *appPath = [self buildTopAppPath];
    if (![self isAppAlreadyRunning:appPath]) {
        // Using a shared user defaults to indicate to AutoMute that we launched it.
        // AutoMute is responsible for clearing the mark upon launch.
        // See: https://github.com/sindresorhus/LaunchAtLogin/issues/33#issuecomment-770006078
        [self markDidLaunchAtLogin];

        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }
}

- (void)markDidLaunchAtLogin
{
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:MJ_SHARED_GROUP_ID];
    [groupDefaults setBool:YES forKey:MJ_DID_LAUNCH_AT_LOGIN_KEY];
    [groupDefaults synchronize];
}

- (NSString *)buildTopAppPath
{
    NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
    pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
    NSString *path = [NSString pathWithComponents:pathComponents];
    return path;
}

- (BOOL)isAppAlreadyRunning:(NSString *)path
{
    NSString *appBundleId = [[NSBundle bundleWithPath:path] bundleIdentifier];
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([[app bundleIdentifier] isEqualToString:appBundleId]) {
            return YES;
        }
    }
    return NO;
}

@end
