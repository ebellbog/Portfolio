#import "DEViewController.h"
#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation DEViewController

@synthesize teamLogos, teamURLs, teamViews, bracketView, tournament;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    inFinals = NO;
    alertDisplaying = NO;
    
    //Label views added in tag order for direct compatibility with printTreeToViews
    int i = 0;
    UILabel *view;
    self.teamViews = [[[NSMutableArray alloc] init] autorelease];
    while ((view = (UILabel *)[self.bracketView viewWithTag:i])) {
        view.text = @"";
        [self.teamViews addObject:view];
        i++;
    }
   
    UIImageView *backgroundImage = (UIImageView *)[self.bracketView viewWithTag:-1];
    backgroundImage.image = [UIImage imageNamed:@"bracket.png"];
    
    
    CGRect fullScreen = [[UIScreen mainScreen] bounds];
    float bracketWidth = self.bracketView.bounds.size.width;
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, fullScreen.size.height, fullScreen.size.width-20)];
    scrollView.delegate = self;
    scrollView.contentSize = self.bracketView.bounds.size;
    scrollView.maximumZoomScale = 1.15;
    scrollView.minimumZoomScale = fullScreen.size.height/bracketWidth;
    scrollView.zoomScale = scrollView.minimumZoomScale;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    tapRecognizer.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    
    [scrollView addSubview:self.bracketView];
    [self.view addSubview:scrollView];
    [self.view sendSubviewToBack:scrollView];
    [scrollView release];
    
    self.teamLogos = [[[NSMutableDictionary alloc] init] autorelease];
    self.teamURLs = [[[NSMutableDictionary alloc] init] autorelease];
    self.tournament = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proceedIfConnected) name:kReachabilityChangedNotification object:nil];
}

- (void)loadTournamentFromData:(NSData *)data {
    //Parse JSON data
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return;
    }
    
    //Start async download of images; may get released and reloaded later as memory requires
    NSArray *teamsArray = [json objectForKey:@"data"];
    for (NSDictionary *team in teamsArray) {
        NSURL *teamURL = [NSURL URLWithString:[team objectForKey:@"image"]];
        [self.teamURLs setObject:teamURL forKey:[team objectForKey:@"name"]]; //Store URL in case of need for reloading
        [self reloadImageWithName:[team objectForKey:@"name"]]; //Make use of async reload method for initial load
    }
    
    //Create new tournament with names of loaded teams
    self.tournament = [[[DETree alloc] initWithTeams:self.teamURLs.allKeys] autorelease];
    [self printTreeToViews];
}

- (void)reloadImageWithName:(NSString *)name {
    DEAppDelegate *appDel = (DEAppDelegate *)[[UIApplication sharedApplication] delegate];
    NetworkStatus appStat =  [appDel.reachTest currentReachabilityStatus];
    
    if (appStat != NotReachable) {        
        NSURL *teamURL = [self.teamURLs valueForKey:name];
        if (teamURL) {
            dispatch_async(bgQueue, ^{
                UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:teamURL]];
                [self.teamLogos setObject:image forKey:name];
                NSLog(@"Downloaded image for: %@; %i keys in dictionary\n", name, self.teamLogos.count);
                
                NSNotification *note = [NSNotification notificationWithName:@"LoadedLogoForScopely" object:nil userInfo:[NSDictionary dictionaryWithObject:name forKey:@"name"]];
                [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:note waitUntilDone:NO];
            });
        } else NSLog(@"No URL for name: %@", name);
    } else if (!alertDisplaying) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                        message:@"This app requires the Internet to access team data; please reconnect."
                                                       delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alert show];
        [alert release];
        alertDisplaying = YES;
    }
}

- (IBAction)playTournament {
    
    if (!scrollView.userInteractionEnabled || self.tournament == nil) return;
    //Effectively disables button whenever scrolling is also disabled; helps prevent spamming
    //Also checks that tournament is ready for playing
    
    int match, tier, index;
    BOOL winBracket;
    UILabel *team1 = nil, *team2 = nil;
    NSString *winner;
    
    if ([self.tournament getNextMatch]) { //Playing matches within winner's and loser's brackets
        match = self.tournament.currentMatch;
        tier = self.tournament.currentTier;
        winBracket = self.tournament.currentlyInWinners;
        
        index = [self.tournament getIndexForMatch:match forTier:tier inWinnersBracket:winBracket];
        team1 = [self.teamViews objectAtIndex:index];
        team2 = [self.teamViews objectAtIndex:index+1];
                
    } else if ([[self.tournament.victors objectAtIndex:0] isEqualToString:@""]) { //Entering final
        index = [self.tournament getIndexForMatch:0 forTier:0 inWinnersBracket:NO];
        team1 = [self.teamViews objectAtIndex:index-1];
        team2 = [self.teamViews objectAtIndex:self.teamViews.count-4];
        inFinals = YES;
    
    } else if (!(winner = [self.tournament isFinished])) { //Potential second round of final
        team1 = [self.teamViews objectAtIndex:self.teamViews.count-3];
        team2 = [self.teamViews objectAtIndex:self.teamViews.count-2];
    } else if(!alertDisplaying) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Victory" message:[NSString stringWithFormat:@"The %@ came out on top in the final round! Would you like to start a new tournament?", winner] delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Yeah", nil];
        [alert show];
        [alert release];
        alertDisplaying = YES;
        return;
    }
    
    team1.textColor = [UIColor redColor];
    team2.textColor = [UIColor redColor];
    [self printTreeToViews];
    
    CGRect zoomRect = CGRectUnion(team1.frame, team2.frame);
    zoomRect.origin.y -= zoomRect.size.height*.1;
    zoomRect.origin.x += 20;
    zoomRect.size.height += zoomRect.size.height*.3;

    scrollView.userInteractionEnabled = NO; //Disables scrolling while view auto-zooms
    [scrollView zoomToRect:zoomRect animated:YES];
    
    NSArray *teamNames = [[NSArray alloc] initWithObjects:team1.text, team2.text, nil];
    [self performSelector:@selector(presentSelectorForTeams:) withObject:teamNames afterDelay:0.7];
}

- (void)printTreeToViews {
    int i = 0;
    for (NSArray *tier in self.tournament.winners) {
        for (NSString *team in tier) {
            [[self.teamViews objectAtIndex:i] setText:team];
            i++;
        }
    }
    for (NSArray *tier in self.tournament.losers) {
        for (NSString *team in tier) {
            [[self.teamViews objectAtIndex:i] setText:team];
            i++;
        }
    }
    for (NSString *team in self.tournament.victors) {
        [[self.teamViews objectAtIndex:i] setText:team];
        i++;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.teamLogos removeAllObjects];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.teamLogos = nil;
    self.teamURLs = nil;
    self.teamViews = nil;
    self.bracketView = nil;
    self.tournament = nil;
    [super dealloc];
}


#pragma mark - Reachability methods

- (void)proceedIfConnected {
    DEAppDelegate *appDel = (DEAppDelegate *)[[UIApplication sharedApplication] delegate];
    NetworkStatus appStat =  [appDel.reachTest currentReachabilityStatus];
    
    if (self.tournament == nil) {
        if (appStat != NotReachable) {
            //Load JSON file in background; load tournament when done
            dispatch_async(bgQueue, ^{
                NSData *data = [NSData dataWithContentsOfURL:jsonURL];
                if (data)[self performSelectorOnMainThread:@selector(loadTournamentFromData:) withObject:data waitUntilDone:NO];
                else NSLog(@"Bad URL; unable to load data.");
            });
        } else if (!alertDisplaying) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                            message:@"This app requires the Internet to access team data; please reconnect."
                                                           delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alert show];
            [alert release];
            alertDisplaying = YES;
        }
    }
}


#pragma mark - UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.bracketView;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture {
    CGPoint touchedAt = [gesture locationOfTouch:0 inView:self.bracketView];
    if (scrollView.zoomScale == scrollView.minimumZoomScale) [scrollView zoomToRect:CGRectMake(touchedAt.x, touchedAt.y, 100, 100) animated:YES];
    else [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
}

#pragma mark - DESelectionControllerDelegate methods

- (void)selectionControllerDidFinishWithWin:(BOOL)win {
    for (UILabel *team in self.teamViews) {
        team.textColor = [UIColor blackColor];
    }
    
    if (inFinals) [tournament settleFinalMatchAsWin:win];
    else [tournament settleCurrentMatchAsWin:win];

    [self printTreeToViews];
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *winner;
        if ((winner = [tournament isFinished])) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Victory" message:[NSString stringWithFormat:@"The %@ came out on top in the final round! Would you like to start a new tournament?", winner] delegate:self cancelButtonTitle:@"No, thanks" otherButtonTitles:@"Yeah", nil];
            [alert show];
            [alert release];
            alertDisplaying = YES;
        }
        scrollView.userInteractionEnabled = YES;
    }];
}

- (void)presentSelectorForTeams:(NSArray *)teamNames {
    DESelectionController *tSelection = [[DESelectionController alloc] initWithTeamA:[teamNames objectAtIndex:0] andTeamB:[teamNames objectAtIndex:1]];
    tSelection.delegate = self;
    tSelection.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentModalViewController:tSelection animated:YES];
    [tSelection release];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        self.tournament = [[[DETree alloc] initWithTeams:self.teamURLs.allKeys] autorelease]; //Simpler than writing reset function
        inFinals = NO;

        [self printTreeToViews];
        [scrollView setZoomScale:0 animated:YES];
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    alertDisplaying = NO;
}

@end
