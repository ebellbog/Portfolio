//
//  BGLFlipsideViewController.m
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import "BGLFlipsideViewController.h"
#import "BGLMainViewController.h"
#import "BGLAppDelegate.h"

@implementation BGLFlipsideViewController

@synthesize delegate = _delegate;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    appDel = (BGLAppDelegate *)[[UIApplication sharedApplication] delegate];
    doRotate.on = appDel.doRotate;
    setPBC.on = appDel.setPBC;
    boardSize.selectedSegmentIndex = appDel.boardSize;
    letterDistribution.selectedSegmentIndex = appDel.letterDistribution;
    minWords.text = [NSString stringWithFormat:@"%i",appDel.minWords];
    minPoints.text = [NSString stringWithFormat:@"%i",appDel.minPoints];
    minLength.text = [NSString stringWithFormat:@"%i",appDel.minLength];

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [minWords release];
    [minLength release];
    [minPoints release];
    [doRotate release];
    [setPBC release];
    [boardSize release];
    [letterDistribution release];
    [super dealloc];
}


#pragma mark - Actions

- (IBAction)done:(id)sender
{
    int length, points, words;
    length = [minLength.text intValue];
    points = [minPoints.text intValue];
    words = [minWords.text intValue];
    
    if (appDel.letterDistribution != letterDistribution.selectedSegmentIndex || appDel.minPoints != points || appDel.minLength != length || appDel.minWords != words || appDel.setPBC != setPBC.on) [(BGLMainViewController *)self.delegate setRemix: YES];
    if (appDel.boardSize != boardSize.selectedSegmentIndex) [(BGLMainViewController *)self.delegate setResize:YES];
    if (appDel.doRotate != doRotate.on) [(BGLMainViewController *)self.delegate setReorient:YES];
    
    appDel.doRotate = doRotate.on;
    appDel.setPBC = setPBC.on;
    appDel.boardSize = boardSize.selectedSegmentIndex;
    appDel.letterDistribution = letterDistribution.selectedSegmentIndex;
    
    appDel.minLength = length;
    appDel.minPoints = points;
    appDel.minWords = words;

    [self.delegate modalViewControllerDidFinish];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateFlipView:113+39*textField.tag+self.view.frame.origin.y-20];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {              
    [self animateFlipView:-(113+39*textField.tag)];
    [textField endEditing:YES];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([textField.text isEqualToString:@""]) textField.text = @"0";
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *digitSet = [NSCharacterSet decimalDigitCharacterSet];
    return [[string stringByTrimmingCharactersInSet:digitSet] isEqualToString:@""];
}

- (void)animateFlipView:(NSInteger)dist {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect = self.view.frame;
    rect.origin.y -= dist;
    rect.size.height += dist;
    
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

@end
