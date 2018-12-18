#import "NSImage+YLUtil.h"

@implementation NSImage (YLUtil)

- (NSImage *)imageTintedWithColor:(NSColor *)tint
{
    NSImage *image = [self copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
        [image unlockFocus];
    }
    image.template = NO;
    return image;

}

@end
