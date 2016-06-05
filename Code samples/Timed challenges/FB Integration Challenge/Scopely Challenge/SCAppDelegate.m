//
//  SCAppDelegate.m
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import "SCAppDelegate.h"

NSString *const FBSessionStateChangedNotification = @"Scopely.Challenge.Login:FBSessionStateChangedNotification";

@implementation SCAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize session = _session;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    UINavigationController *navCon = [[[UINavigationController alloc] init] autorelease];
    [navCon setNavigationBarHidden:YES];
    
    SCLoginController *viewCon = [[[SCLoginController alloc] init] autorelease];
    
    [navCon pushViewController:viewCon animated:NO];

    if (FBSession.activeSession.isOpen) {
        SCFunController *funCon = [[[SCFunController alloc] init] autorelease];
        [navCon pushViewController:funCon animated:NO];
    }

    self.viewController = navCon;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [FBSession.activeSession close];
}


#pragma mark - Facebook methods


- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"user_photos",
                            nil];
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session,
                                                             FBSessionState state,
                                                             NSError *error) {
                                             [self sessionStateChanged:session
                                                                 state:state
                                                                 error:error];
                                         }];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)closeSession {
    [FBSession.activeSession closeAndClearTokenInformation];
}

@end
