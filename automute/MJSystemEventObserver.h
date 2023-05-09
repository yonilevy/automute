#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MJSystemEvent) {
    MJSystemEventNone = 0,

    /// In reverse order of precedence for notification.
    MJSystemEventLock,
    MJSystemEventSleep,
    MJSystemEventPowerOff,
};

@protocol MJSystemEventHandlerDelegate
- (BOOL)systemEventsHandler_muteIfAppropriateForEvent:(MJSystemEvent)event;
- (void)systemEventsHandler_notifyMutedOnEvent:(MJSystemEvent)event;
@end

@interface MJSystemEventObserver : NSObject

- (instancetype)initWithDelegate:(id<MJSystemEventHandlerDelegate>)delegate;

- (void)handleEnterEvent:(MJSystemEvent)event;
- (void)handleExitEvent:(MJSystemEvent)event;

- (void)start;
@end
