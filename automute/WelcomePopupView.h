#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface WelcomePopupView : NSView

@property (weak) IBOutlet NSButton *gotItButton;
@property (weak) IBOutlet NSImageView *connectedImage;
@property (weak) IBOutlet NSImageView *disconnectedImage;

@end
