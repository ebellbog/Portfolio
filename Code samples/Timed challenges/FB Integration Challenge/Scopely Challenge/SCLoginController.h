//
//  SCViewController.h
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import <UIKit/UIKit.h>
#import "SCFunController.h"

@class SCAppDelegate;

@interface SCLoginController : UIViewController {
    IBOutlet UIButton *loginButton;
    SCAppDelegate *appDel;
}

- (IBAction) loginFB;
- (void)sessionStateChanged:(NSNotification*)notification;
- (void)loadFun;

@property (retain, nonatomic) UIButton *loginButton;
@property (retain, nonatomic) SCAppDelegate *appDel;

@end
