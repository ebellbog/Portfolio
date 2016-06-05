#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"

//Edit URL here to test app with different JSON data
#define jsonURL [NSURL URLWithString:@"https://s3.amazonaws.com/misc-withbuddies.com/ClientChallenge/client-data-file.json"]

@class DEViewController;

@interface DEAppDelegate : UIResponder <UIApplicationDelegate> {
    Reachability *reachTest;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DEViewController *viewController;

@property (nonatomic, retain) Reachability *reachTest;

@end
