#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface YLStatusItemPopupDisplayer : NSObject

- (id)initWithStatusItem:(NSStatusItem *)statusItem;

- (void)displayPopoverWithView:(NSView *)view
   shouldCloseOnOutsideTouches:(BOOL)shouldCloseOnOutsideTouches;
- (void)hidePopoverWithAnimate:(BOOL)animate;
@end
