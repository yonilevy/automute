#import "WelcomePopupView.h"
#import "NSImage+YLUtil.h"


@implementation WelcomePopupView

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.connectedImage.image setTemplate:YES];
    [self.disconnectedImage.image setTemplate:YES];
}

@end
