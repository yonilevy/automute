#import "YLStatusItemPopupDisplayer.h"


@interface YLStatusItemPopupDisplayer ()
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSPopover *popover;
@property(nonatomic, strong) id mouseDownMonitor;
@end

@implementation YLStatusItemPopupDisplayer

- (instancetype)initWithStatusItem:(NSStatusItem *)statusItem
{
    self = [super init];
    if (!self) return nil;

    self.statusItem = statusItem;

    return self;
}

- (void)displayPopoverWithView:(NSView *)view
   shouldCloseOnOutsideTouches:(BOOL)shouldCloseOnOutsideTouches
{
    BOOL shouldAnimate = YES;
    if (self.popover) {
        shouldAnimate = NO;
        self.popover.animates = NO;
        [self hidePopoverWithAnimate:shouldAnimate];
    }

    if (shouldCloseOnOutsideTouches) {
        __weak YLStatusItemPopupDisplayer *weakSelf = self;
        self.mouseDownMonitor =
                [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask handler:
                        ^(NSEvent *event) {
                            [weakSelf hidePopoverWithAnimate:YES];
                        }];
    }

    self.popover = [[NSPopover alloc] init];
    self.popover.animates = shouldAnimate;
    self.popover.contentViewController = [[NSViewController alloc] init];
    self.popover.contentViewController.view = view;
    [self.popover showRelativeToRect:self.statusItem.button.bounds
                              ofView:self.statusItem.button
                       preferredEdge:NSMinYEdge];
}

- (void)hidePopoverWithAnimate:(BOOL)animate
{
    self.popover.animates = animate;
    [self.popover performClose:self];
    self.popover = nil;
    [NSEvent removeMonitor:self.mouseDownMonitor];
    self.mouseDownMonitor = nil;
}

@end
