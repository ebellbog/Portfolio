//
//  BGLMainViewController.m
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import "Reachability.h"

#import "BGLMainViewController.h"
#import "BGLDefinitionContainerController.h"
#import "BGLAppDelegate.h"
#import "BGLBlock.h"
#import "BGLWord.h"
#import "BGLTest.h"


@implementation BGLMainViewController

@synthesize letterSelect, countdown;
@synthesize remix, resize, reorient;
@synthesize wordCount, pointCount, maxWord;
@synthesize foundList, foundDict, PBCList;
@synthesize blockCollector, wordIndex;
@synthesize navCon, backgroundImage, player;

- (IBAction)shakeBusily:(id)sender {
    if (!ninja) {
        [self setTimer:nil];
        [self blackOut];
        if (appDel.minWords + appDel.minPoints + appDel.minLength > 0 && sender) {        
            [(UIButton *)[self.view viewWithTag:13] setTitle:@"" forState:UIControlStateNormal];
            [self.view addSubview:blocker];
            [generatingBoard startAnimating];
            [self performSelector:@selector(shakeBoard) withObject:nil afterDelay:1];
        } else [self shakeBoard];
    } else [self deliverGram];
}

- (void)shakeBoard {
    self.foundList = nil;
    self.foundDict = nil;
    self.PBCList = nil;
    wordCount = -1;
        
    if (self.resize) {
        for (int i = 1; i < 26; i++) {
            if ((i > 20 || i%5 == 0) && appDel.boardSize == 0) boardArray[i-1] = '?';
            else boardArray[i-1] = 'a';
        }
        self.resize = NO;
    }
    [self genBoard];
    
    int attempts = 0;
    if (appDel.minWords + appDel.minPoints + appDel.minLength > 0) {
        [self getStats];
        
        NSDate *startTime = [NSDate date];
        BOOL criteriaMet = (appDel.minWords <= wordCount && appDel.minPoints <= pointCount && appDel.minLength <= maxWord);
        while (!criteriaMet && [[NSDate date] timeIntervalSinceDate:startTime] < 12) {
            if (pointCount > bestPoints) {
                for (int i = 0; i < 25; i++) {
                    bestBoard[i] = boardArray[i];
                }
                bestPoints = pointCount;
            }
            [self genBoard];
            [self analyzeBoard:NO];
            criteriaMet = (appDel.minWords <= wordCount && appDel.minPoints <= pointCount && appDel.minLength <= maxWord);
            attempts++;
            //NSLog(@"Words:%i, Points:%i, Longest:%i",wordCount,pointCount,maxWord);
        }
        
        if (!criteriaMet) {
            self.foundDict = nil;
            self.foundList = nil;
            wordCount = -1;
            
            for (int i = 0; i < 25; i++) {
                boardArray[i] = bestBoard[i];
            }
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Note" message:[NSString stringWithFormat:@"Unable to satisfy criteria after %i attempt%@; continue trying?",attempts, ((attempts == 1) ? @"" : @"s")] delegate:self cancelButtonTitle:@"No" otherButtonTitles: @"Yes",nil] autorelease];
            [alert performSelector:@selector(show) withObject:nil afterDelay:0];
        } else {
            self.foundList = [[self.foundDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
            
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"length" ascending:YES];
            self.foundList = [foundList sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            [generatingBoard stopAnimating];
            [blocker performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
            [self assignBoard:YES];
        }
        
    } else [self assignBoard:YES];
}

- (void)genBoard {
    switch (appDel.letterDistribution) {
        case 0:
            if (appDel.boardSize == 1) blockCollector = [NSMutableArray arrayWithArray:appDel.blocks];
            else blockCollector = [NSMutableArray arrayWithArray:appDel.smallBlocks];
            NSUInteger index;
            BGLBlock *block;
            
            for (int i = 0; i < 25; i++) {
                if (boardArray[i] != '?') {
                    index = arc4random()%[blockCollector count];
                    block = (BGLBlock *)[blockCollector objectAtIndex:index];
                    boardArray[i] = [block roll];
                    [blockCollector removeObjectAtIndex:index];
                }
            }
            break;
        case 1:
            for (int i = 0; i < 25; i++) {
                if (boardArray[i] != '?') boardArray[i] = [appDel freqLetter:arc4random()%1000];
            }
            break;

        case 2:
            for (int i = 0; i < 25; i++) {
                if (boardArray[i] != '?') boardArray[i] = [appDel alphaLetter:arc4random()%26];
            }
            break;
        default:
            break;
    }
}

- (void)assignBoard:(BOOL)doRotate {
    UIButton *button;
    NSString *letter;
        
    for (int i = 0; i < 25; i++) {
        button = (UIButton *)[self.view viewWithTag:i+1];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleShadowColor:nil forState:UIControlStateNormal];
        

        if (boardArray[i] == 'q') letter = @"Qu";
        else if (boardArray[i] == '?') {
            letter = @"?";
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
        else letter = [[NSString stringWithFormat:@"%c",boardArray[i]] capitalizedString];
        
        button.titleLabel.font = [UIFont fontWithName:@"Arial" size:([letter isEqualToString:@"Qu"] ? 25.0 : 30.0)];
        
        if ([letter isEqualToString:@"?"]) {
            [button setTransform:CGAffineTransformMakeRotation(0)];
        } else if (doRotate || [button.titleLabel.text isEqualToString:@"?"]){
            int angle = (arc4random()%4)*appDel.doRotate;
            button.titleLabel.shadowOffset = CGSizeMake(1-2*(angle == 2 || angle == 3),1-2*(angle == 0 || angle == 3));
            [button setTransform:CGAffineTransformMakeRotation(-M_PI/2*(float)angle)];
        }
        
        [button setTitle:letter forState:UIControlStateNormal];
    }
    bestPoints = 0;
}

- (void)analyzeBoard:(BOOL)makeList {
    /*NSString *testWord = @"mastu";
    NSRange spellRange = [textChecker rangeOfMisspelledWordInString:testWord range:NSMakeRange(0, testWord.length) startingAt:0 wrap:NO language:[[NSLocale preferredLanguages] objectAtIndex:0]];
    
    if (spellRange.location == NSNotFound) {
        NSLog(@"Word found");
    }
    else {
        NSLog(@"One or more mispellings at %i",spellRange.location);
    }
    
    NSArray *wordCompletions = [textChecker completionsForPartialWordRange:NSMakeRange(0, testWord.length) inString:testWord language:[[NSLocale preferredLanguages] objectAtIndex:0]];
    
    for (int i = 0; i < wordCompletions.count; i++) NSLog(@"Corrections %i:%@.",i,[wordCompletions objectAtIndex:i]);*/
    
    pointCount = 0;
    wordCount = 0;
    maxWord = 0;
    
    int workingLength;
    int scores[5] = {1,1,2,3,5};
    
    NSMutableArray *progressQueue = [[NSMutableArray alloc] init];
    self.foundDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    for (int i = 0; i < 25; i++) {
        [progressQueue addObject:[[[BGLWord alloc] initWithBoard:boardArray atPoint:i] autorelease]];
    }
    
    BGLWord *workingWord;
    NSArray *oldPath;
    NSMutableArray *newPath;
    
    while (progressQueue.count > 0) {
        workingWord = (BGLWord *)[progressQueue objectAtIndex:0];
        if ([workingWord isWord]) {
            workingLength = workingWord.workingString.length;
            maxWord = (maxWord > workingLength ? maxWord : workingLength);
            oldPath = [self.foundDict objectForKey:workingWord.workingString];
            if (oldPath == nil) {
                wordCount++;
                pointCount += (workingLength >= 8 ? 11 : scores[workingLength-3]);
            }
            newPath = [NSMutableArray arrayWithArray:workingWord.usedBlocks];
            [newPath addObjectsFromArray:oldPath];
            [self.foundDict setObject:newPath forKey:workingWord.workingString];
        }
        [progressQueue addObjectsFromArray:[workingWord proliferate]];
        [progressQueue removeObjectAtIndex:0];
    }
    
    [progressQueue release];
       
    if (makeList) {
        self.foundList = [[self.foundDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"length" ascending:YES];
        self.foundList = [foundList sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }

    /*NSString *foundWord;
    for (foundWord in self.foundList) {
        NSLog(@"Found: %@.",foundWord);
    }
    NSLog(@"Found %i words in total.",foundList.count);*/
}

- (IBAction) requestAnalysis {
    if (!ninja) {
        if (self.foundList == nil || self.foundDict == nil) [self analyzeBoard:YES];
        if (appDel.setPBC && self.PBCList == nil) {
            self.PBCList = [NSMutableArray arrayWithCapacity:foundList.count];
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:self.foundDict];
            NSArray *tempArray = [NSArray arrayWithArray:foundList];
            
            appDel.setPBC = NO;
            [self analyzeBoard:YES];
            appDel.setPBC = YES;
            
            NSString *word;
            
            for (word in tempArray) {
                if ([self.foundDict objectForKey:word] == nil) [PBCList addObject:[@"*" stringByAppendingString:word]];
                else [PBCList addObject:word];
            }
            
            self.foundDict = [NSMutableDictionary dictionaryWithDictionary:tempDict];
            self.foundList = [NSArray arrayWithArray:tempArray];
            wordCount = -1;
        }
        [self showWords];
    } else [self deliverGram];
}

- (NSArray *)arrayToList:(NSArray *)array {
    int count = 0;
    NSNumber *number;
    for (number in array) {
        if ([number intValue] > 0) count++;
    }
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        [returnArray addObject:[NSNull null]];
    }
    
    int i = 0, value;
    while (i < array.count) {
        value = [[array objectAtIndex:i] intValue];
        if (value > 0) [returnArray replaceObjectAtIndex:(value-1) withObject:[NSNumber numberWithInt:(i+1)]];
        i++;
    }
    return returnArray;
}

- (IBAction)editLetter:(UIButton *)sender {
    if (!ninja) {
        [self setTimer:nil];
        lastButtonIndex = sender.tag;
        if (appDel.boardSize == 0 && (sender.tag > 20 || sender.tag%5 == 0)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Editing this block will return your board size to 5x5." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: @"Okay",nil];
            [alert show];
            [alert autorelease];
        } else [self.letterSelect becomeFirstResponder];
    } else [self deliverGram];
}

#pragma mark - Timer methods

- (IBAction)setTimer:(id)sender {
    if (!ninja) {
        if (self.countdown == nil && [sender isKindOfClass:[UIButton class]]) {
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

            self.countdown = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTimeLabel) userInfo:nil repeats:YES];
            [timeButton setTitle:@"3:00" forState:UIControlStateNormal];
            [timeButton.titleLabel setFont:[UIFont fontWithName:@"DB LCD Temp" size:17]];
            timeButton.titleEdgeInsets = UIEdgeInsetsMake(4.0, 0.0, 0.0, 0.0);
            timeCount = 180.0;        
        } else {
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

            [timeButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.8] forState:UIControlStateNormal];
            [self.countdown invalidate];
            self.countdown = nil;
            [timeButton setTitle:@"START TIMER" forState:UIControlStateNormal];
            [timeButton.titleLabel setFont:(appDel.versionNumber < 500 ? [UIFont fontWithName:@"Futura" size:14] : [UIFont fontWithName:@"Futura-CondensedMedium" size:17])];
            timeButton.titleEdgeInsets = UIEdgeInsetsMake(2.0, 0.0, 0.0, 0.0);
        }
    } else [self deliverGram];
}

- (void)updateTimeLabel {
    timeCount -= 0.5;
    if (timeCount >= 0) {
        [timeButton setTitle:[NSString stringWithFormat:@"%i:%02i",(int)(timeCount+.5)/60,(int)(timeCount+.5)%60] forState:UIControlStateNormal];
        if (timeCount == 0) [self makeBeep:1];
        else if (timeCount <= 5.0) {
            [timeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [self makeBeep:0];
        }
        else if (timeCount <= 10 && timeCount == (int)timeCount) [self makeBeep:0];
        else if (timeCount <= 20 && (int)timeCount%2 == 0 && timeCount == (int)timeCount)[self makeBeep:0];
    }
    else if (timeCount > -6) {
        [timeButton setTitleColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:((int)timeCount%2 == 0)] forState:UIControlStateNormal];
    }
    else [self setTimer:nil];
}

- (void)makeBeep:(int)type {
    SystemSoundID soundID = 0;
    NSString *soundFile;
    switch (type) {
        case 0:
            soundFile = @"Beep";
            break;
        case 1:
            soundFile = @"Final_beep";
            break;
        case 2:
            soundFile = @"Shake_sound";
            break;
        case 3:
            soundFile = @"Ninja_cry";
            break;
        case 4:
            soundFile = @"Explosion";
            break;
        default:
            soundFile = @"";
            break;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:soundFile ofType:@"wav"];
    CFURLRef soundFileURL = (CFURLRef)[NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID(soundFileURL, &soundID);
    AudioServicesPlayAlertSound(soundID);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [UITextChecker learnWord:@"blood"];

    
    appDel = (BGLAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background.png"]];
        
    self.navCon = [[UINavigationController alloc] init];
    self.navCon.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    self.remix = YES;
    self.reorient = NO;
    self.resize = NO;
    textChecker = [[UITextChecker alloc] init];
    [self.letterSelect setHidden:YES];
        
    UIButton *button;
    for (int i = 1; i < 26; i++) {
        button = (UIButton *)[self.view viewWithTag:i];
        [button.titleLabel setTextAlignment:UITextAlignmentCenter];
        boardArray[i-1] = 'a';
    }
    
    [timeButton.titleLabel setFont:(appDel.versionNumber < 500 ? [UIFont fontWithName:@"Futura" size:14] : [UIFont fontWithName:@"Futura-CondensedMedium" size:17])];
    
    self.countdown = nil;
    self.wordIndex = nil;
    
    blocker = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 320, 480)];
    //[blocker setBackgroundColor:[UIColor colorWithHue:1.0 saturation:1.0 brightness:1.0 alpha:0.5]];
    
    wordCount = -1;
    bestPoints = 0;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LastExpress" ofType:@"wav"];
    self.player = [[[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil] autorelease];
    [self.player setVolume:0.5];
    [self.player setNumberOfLoops:-1];
    
    ninja = NO;
        
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
    [self startAcceleration];
    if (self.reorient) {
        [self assignBoard:YES];
        self.reorient = NO;
    }
    
    if (self.remix || self.resize) {
        [self shakeBusily:self];
        self.remix = NO;
    }

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAcceleration];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self setTimer:nil];
    [self resignFirstResponder];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc {
    self.foundDict = nil;
    self.foundList = nil;
    self.PBCList = nil;
    self.letterSelect = nil;
    self.countdown = nil;
    self.wordIndex = nil;
    self.navCon = nil;
    self.backgroundImage = nil;
    self.player = nil;
    [blocker release];
    [timeButton release];
    [generatingBoard release];
    [textChecker release];
    [super dealloc];
}

#pragma mark - Flipside View

- (IBAction)showInfo:(id)sender
{    
    BGLFlipsideViewController *controller = [[[BGLFlipsideViewController alloc] initWithNibName:@"BGLFlipsideViewController" bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
}

- (void)modalViewControllerDidFinish
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Results view

- (IBAction)showStats {
    if (!ninja) {
        if (wordCount < 0) [self getStats];
        BGLResultsViewController *controller = [[[BGLResultsViewController alloc] initWithNibName:@"BGLResultsViewController" andSender:self] autorelease];
        controller.delegate = self;
        controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:controller animated:YES];
    } else [self deliverGram];
}

- (void)getStats {
    if (!self.foundList)[self analyzeBoard:YES];
    wordCount = foundList.count;
    
    if (wordCount > 0) maxWord = [(NSString *)[foundList objectAtIndex:foundList.count-1] length];
    else maxWord = 0;
    
    pointCount = 0;
    NSString *pWord;
    int scores[5] = {1,1,2,3,5};
    
    for (pWord in foundList) {
        pointCount += (pWord.length >= 8 ? 11 : scores[pWord.length-3]);
    }
}

#pragma mark - Word view

- (void)showWords
{    
    BGLWordViewController *controller = [[BGLWordViewController alloc] initWithNibName:@"BGLWordViewController" andList:self.foundList withPBC:self.PBCList];
    controller.delegate = self;
    self.navCon.viewControllers = [NSArray arrayWithObject:controller];
    [self presentModalViewController:self.navCon animated:YES];
    
    if (self.wordIndex) {
        [controller.wordTable scrollToRowAtIndexPath:self.wordIndex atScrollPosition:(appDel.versionNumber < 500 ? UITableViewScrollPositionTop : UITableViewScrollPositionMiddle) animated:NO];
        self.wordIndex = nil;
    }
    
    if ([appDel versionNumber] < 500) [controller.sBar becomeFirstResponder];
    
    [controller release];
}

- (void)loadDefinitionView:(NSString *)word {
    if ([word characterAtIndex:0] == '*') word = [word substringFromIndex:1];
    
    BGLDefinitionContainerController *defContainer = [[BGLDefinitionContainerController alloc] initWithNibName:nil bundle:nil];
    
    if (appDel.versionNumber >= 500) {
        if ([UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:word]) {
            UIReferenceLibraryViewController *defController = [[UIReferenceLibraryViewController alloc] initWithTerm:word];
            defController.view.frame = CGRectMake(0, -75, 320, 555);
            [defContainer.view addSubview:defController.view];
            [defController release];
        }
    }
    
    if (defContainer.view.subviews.count == 0) {
        Reachability *testReach = [[Reachability reachabilityWithHostName:@"en.wiktionary.org"] retain];
        NetworkStatus wikiStat = [testReach currentReachabilityStatus];
        [testReach release];  
        
        if (wikiStat == NotReachable) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to reach Wiktionary" message:[NSString stringWithFormat:@"Internet access is required to provide %@; please check your settings.",(appDel.versionNumber < 500 ? @"word definitions" : @"a definition for this word")] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            [alert release];
        } else {
            UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)];
            [webView setScalesPageToFit:YES];
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://en.wiktionary.org/wiki/%@",word]]]];
            
            [defContainer.view addSubview:webView];
            [webView release];
        }
    }
        
    if (defContainer.view.subviews.count > 0) [self.navCon pushViewController:defContainer animated:YES];
    [defContainer release];
}

- (void)controllerFinishedWithoutWord {
    [self blackOut];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)controllerFinishedWithWord:(NSString *)word {
    [self dismissModalViewControllerAnimated:YES];
    
    NSIndexPath *indexP = self.wordIndex;
    
    [self blackOut];
    
    self.wordIndex = indexP;
    
    if (appDel.setPBC) {
        NSCharacterSet *PBCAdjust = [NSCharacterSet characterSetWithRange:NSMakeRange('*', 1)];
        word = [word stringByTrimmingCharactersInSet:PBCAdjust];
    }
    
    NSArray *path = [foundDict objectForKey:word];
    NSArray *subPath;
    NSMutableArray *subPaths = [[NSMutableArray alloc] init];
    NSNumber *index;
    UIButton *button;
    float colorCounter;
    
    int finalRun = path.count/25-1;
    for (int i = 0; i <= finalRun; i++) {
        [subPaths addObject:[self arrayToList:[path subarrayWithRange:NSMakeRange(25*i, 25)]]];
    }
    
    if (appDel.setPBC && subPaths.count > 1) {
        int current, previous;
        BOOL succeeded = NO;
        int i = 0;
        while (i < subPaths.count && succeeded == NO) {
            succeeded = YES;
            subPath = [subPaths objectAtIndex:i];
            for (int j = 1; j < subPath.count; j++) {
                current = [[subPath objectAtIndex:j] intValue];
                previous = [[subPath objectAtIndex:j-1] intValue];
                if (![self adjacencyBetween:current-1 and:previous-1]) succeeded = NO;
            }
            i++;
        } 
        if (succeeded) {
            [subPaths removeObjectAtIndex:i-1];
            [subPaths addObject:subPath];
            //NSLog(@"Successfully moved path at index %i to back of array.",i-1);
        }
    }
    
    for (int i = 0; i < subPaths.count; i++) {
        colorCounter = 0.0;
        subPath = [subPaths objectAtIndex:i];
        
        for (index in subPath) {
            button = (UIButton *)[self.view viewWithTag:[index intValue]];
            [button setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithHue:(colorCounter/(float)subPath.count) saturation:1.0-.45*(i != finalRun) brightness:0.9-0.45*(i != finalRun) alpha:1.0] forState:UIControlStateNormal];
            colorCounter++;
        }
    }
    [subPaths release];
}

- (BOOL)adjacencyBetween:(NSInteger)current and:(NSInteger)previous {
    BOOL adjacency = NO;
    int r = previous/5, c = previous%5; 
    
    for (int i = -1; i < 2; i++) {
        if (c+i < 5 && c+i > -1) {
            for (int j = -1; j < 2; j++) {
                if (r+j < 5 && r+j > -1) {
                    if (current == previous+j*5+i) adjacency = YES;
                }
            }
        }
    }
    return adjacency;
}

- (void)blackOut {
    UIButton *button;
    for (int i = 1; i < 26; i++) {
        button = (UIButton *)[self.view viewWithTag:i];
        if (![button.titleLabel.text isEqualToString:@"?"]) {
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setTitleShadowColor:nil forState:UIControlStateNormal];
        }
    }
    self.wordIndex = nil;
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self blackOut];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isFirstResponder]) {
        if ([textField.text length] > 1) {
            NSArray *spokenWords = [textField.text componentsSeparatedByString:@" "];
            NSCharacterSet *fullAlpha = [NSCharacterSet letterCharacterSet];
            for (int i = 0; i < spokenWords.count; i++) {
                if ([[spokenWords objectAtIndex:i] length] > 0) {
                    if (![[[[spokenWords objectAtIndex:i] substringToIndex:1] stringByTrimmingCharactersInSet:fullAlpha] isEqualToString:@""]) boardArray[lastButtonIndex-1] = '?';
                    else boardArray[lastButtonIndex-1] = [[spokenWords objectAtIndex:i] characterAtIndex:0];
                }
                [self incrementIndex];
            }
            
            self.foundList = nil;
            self.foundDict = nil;
            self.PBCList = nil;
            wordCount = -1;
            
            [self assignBoard:NO];
        }
        [textField endEditing:NO];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 1) {
        textField.text =  @"";

        string = [string substringToIndex:1];
        
        NSCharacterSet *alphaSet = [NSCharacterSet uppercaseLetterCharacterSet];
        NSCharacterSet *lowerAlpha = [NSCharacterSet lowercaseLetterCharacterSet];
        
        if ([[string stringByTrimmingCharactersInSet:lowerAlpha] isEqualToString:@""]) boardArray[lastButtonIndex-1] = [string characterAtIndex:0];
        else if ([[string stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""]) {
            boardArray[lastButtonIndex-1] = [[string lowercaseString] characterAtIndex:0];
            [self incrementIndex];
        }
        else boardArray[lastButtonIndex-1] = '?';
        
        self.foundList = nil;
        self.foundDict = nil;
        self.PBCList = nil;
        wordCount = -1;
        
        [self assignBoard:NO];
    }
    return YES;
}

- (void) incrementIndex {
    lastButtonIndex += ((lastButtonIndex == 25) ? -24 : 1);
    while (boardArray[lastButtonIndex-1] == '?') {
        lastButtonIndex += ((lastButtonIndex == 25) ? -24 : 1);
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Warning"]) {
        if (buttonIndex == 1) {
            appDel.boardSize = 1;
            [self.letterSelect becomeFirstResponder];
        } else [self textFieldShouldReturn:self.letterSelect];
    } else if ([alertView.title isEqualToString:@"*For your eyes only*"]) {
        [self makeBeep:4];
        [self evacuateNinjas];
    }
    else {
        if (buttonIndex == 1) [self performSelector:@selector(shakeBoard) withObject:nil afterDelay:0];
        else {
            [generatingBoard stopAnimating];
            [blocker performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1];
            [self assignBoard:YES];
        }
    }
}

#pragma mark - Shake Functions

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && ![blocker isDescendantOfView:self.view] && !ninja) [self makeBeep:2];

}


-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake && ![blocker isDescendantOfView:self.view] && !ninja)
    {
        int saveLength = appDel.minLength;
        int savePoints = appDel.minPoints;
        int saveWords = appDel.minWords;
        
        appDel.minLength = 0;
        appDel.minPoints = 0;
        appDel.minWords = 0;
        
        [self setTimer:nil];
        [self shakeBoard];
        
        appDel.minLength = saveLength;
        appDel.minLength = savePoints;
        appDel.minWords  = saveWords;
        
        self.wordIndex = nil;
    }
}

#pragma  mark - Acceleration Functions

- (void)startAcceleration {
    UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
    accel.delegate = self;
    accel.updateInterval = 0.1;
}

- (void)stopAcceleration {
    UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
    accel.delegate = nil;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    float const kThreshold = 0.1;
    if (fabsf(acceleration.x) < kThreshold && fabsf(acceleration.y) < kThreshold && fabsf(acceleration.z) < kThreshold) {
        NSLog(@"Woooo!");
        if ([self isNinjaDay]) {
            if (!ninja) [self ninjagram];
        }
        else {
            for (int i = 0; i < 25; i++) {
                if (i > 5 && i < 20 && i%5 != 0 && i%5 != 4) boardArray[i] = '?';
                else boardArray[i] = 'A';
            }
            appDel.setPBC = YES;
            appDel.boardSize = 1;
            appDel.letterDistribution = 1;
            [self shakeBusily:self];
        }
    }
}

#pragma mark - Ninja functions

- (BOOL)isNinjaDay {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    return ([components day] == 13 && [components month] == 2);
}

- (void)ninjagram {
    [self.backgroundImage setImage:[UIImage imageNamed:@"BackNINJA.png"]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [player play];
    
    NSString *message = @"NINJAGRAM!-¤-¤-FROM:ELLIE";
    UIButton *button;
    for (int i = 1; i < 26; i++) {
        button = (UIButton *)[self.view viewWithTag:i];
        
        [button setTitle:[message substringWithRange:NSMakeRange(i-1, 1)] forState:UIControlStateNormal];
        [button setTitleShadowColor:nil forState:UIControlStateNormal];
        [button setTransform:CGAffineTransformMakeRotation(0)];
        
        UIColor *color;
        if (i < 16 && i > 10) {
            if (i == 12 || i == 14) {
                color = [UIColor redColor];
                [button setTitleColor:color forState:UIControlStateHighlighted];
                [button setHighlighted:YES];
                [button setUserInteractionEnabled:NO];
            }
            else color = [UIColor whiteColor];
        } else color = [UIColor colorWithWhite:0.4 alpha:1.0];
        [button setTitleColor:color forState:UIControlStateNormal];
    }
    lastButton = -1;
    
    [self setTimer:nil];
    self.countdown = [NSTimer scheduledTimerWithTimeInterval:0.13 target:self selector:@selector(sparkle) userInfo:nil repeats:YES];
    ninja = YES;
}

- (void)sparkle {
    UIButton *button;
    if (lastButton > 0) {
        button = (UIButton *)[self.view viewWithTag:lastButton];
        [button setHighlighted:NO];
    }
    
    lastButton = 12;
    while (lastButton == 12 || lastButton == 14) lastButton = arc4random()%25+1;
    button = (UIButton *)[self.view viewWithTag:lastButton];
    [button setHighlighted:YES];
}

- (void)evacuateNinjas {
    [self.countdown invalidate];
    self.countdown = nil;
    [self.backgroundImage setImage:[UIImage imageNamed:@"Background.png"]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    UIButton *button;
    for (int i = 1; i < 26; i++) {
        button = (UIButton *)[self.view viewWithTag:i];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [button setHighlighted:NO];
        [button setUserInteractionEnabled:YES];
    }
    ninja = NO;
    [self shakeBoard];
}

- (void)deliverGram {
    [self.player stop];
    [self makeBeep:3];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"*For your eyes only*" message:@"[secret message goes here!]" delegate:self cancelButtonTitle:@"Destroy message" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
