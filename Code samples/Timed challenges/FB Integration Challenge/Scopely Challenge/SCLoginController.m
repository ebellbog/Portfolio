//
//  SCViewController.m
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import "SCLoginController.h"

@implementation SCLoginController

@synthesize loginButton, appDel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) dealloc {
    self.loginButton = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:FBSessionStateChangedNotification
     object:nil];
    
    self.appDel = [[UIApplication sharedApplication] delegate];
    [self. appDel openSessionWithAllowLoginUI:NO];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super didReceiveMemoryWarning];
}

- (IBAction)loginFB {
    if (FBSession.activeSession.isOpen) {
        [self.appDel closeSession];
    } else {
        [self.appDel openSessionWithAllowLoginUI:YES];
    }
}

- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
        [self loadFun];
    } else {
        [self.loginButton setTitle:@"Login to Facebook" forState:UIControlStateNormal];
    }
}

- (void)loadFun {
    SCFunController *funCont = [[SCFunController alloc] init];
    [self.appDel.viewController pushViewController:funCont animated:YES];
    [funCont release];
}

@end
