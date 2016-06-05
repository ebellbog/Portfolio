//
//  BGLDefinitionContainerController.m
//  WordNerd
//
//  Created by Elana Bogdan on 12/30/11.
//

#import "BGLDefinitionContainerController.h"
#import "BGLWordViewController.h"

@implementation BGLDefinitionContainerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Definition";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewWillDisappear:(BOOL)animated {
    BGLWordViewController *wordController = (BGLWordViewController *)[[(UINavigationController *)self.parentViewController viewControllers] objectAtIndex:0];
    if (![wordController.sBar.text isEqualToString:@""]) {
        [wordController searchBarCancelButtonClicked:wordController.sBar];
        [wordController.wordTable setContentOffset:CGPointMake(0, 0)];
    } else [wordController.sBar resignFirstResponder];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
