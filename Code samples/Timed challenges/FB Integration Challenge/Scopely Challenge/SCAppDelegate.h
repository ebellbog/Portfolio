//
//  SCAppDelegate.h
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SCLoginController.h"

extern NSString *const FBSessionStateChangedNotification;

@class SCLoginController;

@interface SCAppDelegate : UIResponder <UIApplicationDelegate>


- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI;
- (void)closeSession;


@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *viewController;

@property (retain, nonatomic) FBSession *session;

@end
