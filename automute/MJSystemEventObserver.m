#import <AppKit/AppKit.h>
#import "MJSystemEventObserver.h"

@interface MJSystemEventObserver ()
@property(nonatomic, weak) id <MJSystemEventHandlerDelegate> delegate;
@property(nonatomic) MJSystemEvent muteEventPendingNotification;
@end

@implementation MJSystemEventObserver

- (instancetype)initWithDelegate:(id<MJSystemEventHandlerDelegate>)delegate
{
    self = [super init];
    if (!self) return nil;

    self.delegate = delegate;
    self.muteEventPendingNotification = MJSystemEventNone;

    return self;
}

- (void)start
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
               selector:@selector(willSleep)
                   name:NSWorkspaceWillSleepNotification
                 object:nil];

    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
               selector:@selector(didWake)
                   name:NSWorkspaceDidWakeNotification
                 object:nil];

    [[NSDistributedNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(didLock)
                   name:@"com.apple.screenIsLocked"
                 object:nil];

    [[NSDistributedNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(didUnlock)
                   name:@"com.apple.screenIsUnlocked"
                 object:nil];

    [[[NSWorkspace sharedWorkspace] notificationCenter]
            addObserver:self
               selector:@selector(willPowerOff)
                   name:NSWorkspaceWillPowerOffNotification
                 object:nil];
}

- (void)willSleep
{
    [self handleEnterEvent:MJSystemEventSleep];
}

- (void)didWake
{
    [self handleExitEvent:MJSystemEventSleep];
}

- (void)didLock
{
    [self handleEnterEvent:MJSystemEventLock];
}

- (void)didUnlock
{
    [self handleExitEvent:MJSystemEventLock];
}

- (void)willPowerOff
{
    [self handleEnterEvent:MJSystemEventPowerOff];
}

- (void)handleEnterEvent:(MJSystemEvent)event
{
    if ([self.delegate systemEventsHandler_muteIfAppropriateForEvent:event]) {
        /// If we muted, we mark the event for a future notification
        /// (but only if it takes precedence over current marking).
        self.muteEventPendingNotification = MAX(event, self.muteEventPendingNotification);
    }
}

- (void)handleExitEvent:(MJSystemEvent)event
{
    /// Display pending notification if exists for our event.
    if (self.muteEventPendingNotification == event) {
        self.muteEventPendingNotification = MJSystemEventNone;

        [self.delegate systemEventsHandler_notifyMutedOnEvent:event];
    }
}

@end
