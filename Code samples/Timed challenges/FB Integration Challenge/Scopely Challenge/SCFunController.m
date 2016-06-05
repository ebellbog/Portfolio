//
//  FunController.m
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import "SCFunController.h"

@implementation SCFunController

@synthesize appDel, friendList, leftPhoto, rightPhoto;
@synthesize progressBar, progressLabel;
@synthesize friendA, friendB;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.appDel = [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc {
    self.appDel = nil;
    self.friendList = nil;
    self.leftPhoto = nil;
    self.rightPhoto = nil;
    self.progressLabel = nil;
    self.progressBar = nil;
    self.friendA = nil;
    self.friendB = nil;
    
    free(friendScores);
    [super dealloc];
}

- (void)viewDidLoad
{
    UISwipeGestureRecognizer *leftSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)] autorelease];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)] autorelease];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    
    questionNumber = 1;
   
    self.leftPhoto = [[[FBProfilePictureView alloc] initWithFrame:CGRectMake(46, 65, 183, 175)] autorelease];
    self.rightPhoto = [[[FBProfilePictureView alloc] initWithFrame:CGRectMake(251, 65, 183, 175)] autorelease];
    
    UITapGestureRecognizer *leftTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftTap:)] autorelease];
    UITapGestureRecognizer *rightTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightTap:)] autorelease];
    
    [self.leftPhoto addGestureRecognizer:leftTap];
    [self.rightPhoto addGestureRecognizer:rightTap];
    
    [self.view addSubview:leftPhoto];
    [self.view addSubview:rightPhoto];
    
    
    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        [self receiveFriends:[result objectForKey:@"data"]];}
     ];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)handleLeftSwipe:(UISwipeGestureRecognizer *)swipeRecognizer {
    [self updateFriendPair];
}

- (void)handleRightSwipe:(UISwipeGestureRecognizer *)swipeRecognizer {
    NSString *message = @"Swiping backwards will log you out of Facebook. Are you sure you want to proceed? (You can load new friends by swiping forwards.)";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
    [alert release];
}

- (void)handleLeftTap:(UITapGestureRecognizer *)tapRecognizer {
    friendScores[self.leftPhoto.tag] += 1;
    [self incrementQuestion];;
}

- (void)handleRightTap:(UITapGestureRecognizer *)tapRecognizer {
    friendScores[self.rightPhoto.tag] += 1;
    [self incrementQuestion];
}

- (void)receiveFriends:(NSArray *)friends {
    self.friendList = friends;
    friendScores = malloc(self.friendList.count*sizeof(int));
    for (int i = 0; i < self.friendList.count; i++) {
        friendScores[i] = 0;
    }
    
    [self updateFriendPair];
}

- (void)updateFriendPair {
    int randIndex = arc4random()%friendList.count;
    self.leftPhoto.profileID = [[self.friendList objectAtIndex:randIndex] id];
    self.friendA.text = [[self.friendList objectAtIndex:randIndex] name];
    self.leftPhoto.tag = randIndex;
    self.friendA.text = [[self.friendList objectAtIndex:randIndex] name];
    
    int newIndex = randIndex;
    while (newIndex == randIndex) newIndex = arc4random()%friendList.count; //Ensure the user receives two different friends
    self.rightPhoto.profileID = [[self.friendList objectAtIndex:newIndex] id];
    self.friendB.text = [[self.friendList objectAtIndex:newIndex] name];
    self.rightPhoto.tag = newIndex;
    
}

- (void)incrementQuestion {
    questionNumber++;
    
    if (questionNumber > 10) {
        NSMutableArray *topFriends = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.friendList.count; i++) {
            if (friendScores[i] > 0) {
                [topFriends addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:friendScores[i]], [[friendList objectAtIndex:i] name], nil]];
            }
        }
        
        NSArray *sortedFriends = [topFriends sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *first = [(NSArray *)a objectAtIndex:0];
            NSNumber *second = [(NSArray *)b objectAtIndex:0];
            return [second compare:first];
        }];
        [topFriends release];
        
        SCResultsController *results = [[SCResultsController alloc] initWithFriends:sortedFriends];
        [self.appDel.viewController pushViewController:results animated:YES];
        [results release];
    } else {
        self.progressBar.progress = (questionNumber-1)/10.0;
        self.progressLabel.text = [NSString stringWithFormat:@"%i/10", questionNumber];
        [self updateFriendPair];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.appDel closeSession];
        [self.appDel.viewController popViewControllerAnimated:YES];
    }
}

@end
