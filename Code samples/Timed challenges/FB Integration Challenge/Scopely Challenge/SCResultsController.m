//
//  SCResultsController.m
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import "SCResultsController.h"

@implementation SCResultsController

@synthesize sortedFriends, column1, column2;

- (id)initWithFriends:(NSArray *)friends
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.sortedFriends = friends;
    }
    return self;
}

- (void)dealloc {
    self.column1 = nil;
    self.column2 = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    
    for (int i = 0; i < self.sortedFriends.count; i++) {
        NSString *name = [[self.sortedFriends objectAtIndex:i] objectAtIndex:1];
        if (name.length > 13) name = [NSString stringWithFormat:@"%@...",[name substringToIndex:11]];
        
        if (i < 5) {
            self.column1.text = [NSString stringWithFormat:@"%@\n#%i %@ -\t%@", self.column1.text, i+1, name, [[self.sortedFriends objectAtIndex:i] objectAtIndex:0]];
        } else {
            self.column2.text = [NSString stringWithFormat:@"%@\n#%i %@ -\t%@", self.column2.text, i+1, name, [[self.sortedFriends objectAtIndex:i] objectAtIndex:0]];
        }
    }
    [super viewDidLoad];
}
    
- (void)handleTapGesture:(UIGestureRecognizer *)tapRecognizer {
    SCAppDelegate *appDel = [[UIApplication sharedApplication] delegate];
    [appDel.viewController popToRootViewControllerAnimated:NO];
    
    SCFunController *newFun = [[SCFunController alloc] init];
    [appDel.viewController pushViewController:newFun animated:YES];
    [newFun release];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
