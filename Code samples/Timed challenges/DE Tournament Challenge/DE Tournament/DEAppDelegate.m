#import "DEAppDelegate.h"
#import "DEViewController.h"

@implementation DEAppDelegate

@synthesize reachTest;

- (void)dealloc
{
    self.reachTest = nil;
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.reachTest = [Reachability reachabilityWithHostName:@"apple.com"];
    [reachTest startNotifier];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.viewController = [[[DEViewController alloc] initWithNibName:@"DEViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
