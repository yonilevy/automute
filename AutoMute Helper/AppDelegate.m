#import "AppDelegate.h"

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
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }
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
