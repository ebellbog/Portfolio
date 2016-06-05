//
//  BGLAppDelegate.m
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import "BGLAppDelegate.h"
#import "BGLMainViewController.h"
#import "BGLBlock.h"

@implementation BGLAppDelegate

@synthesize window = _window;
@synthesize mainViewController = _mainViewController;
@synthesize blocks, smallBlocks;
@synthesize doRotate, setPBC, letterDistribution, boardSize, minWords, minPoints, minLength;
@synthesize versionNumber;

- (char)freqLetter:(int)letterRequest {
    return freqLetters[letterRequest];
}

- (char)alphaLetter:(int)letterRequest {
    return alphabet[letterRequest];
}

- (void)dealloc
{
    [_window release];
    [_mainViewController release];
    [blocks release];
    [smallBlocks release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    NSString *versionString = [[UIDevice currentDevice] systemVersion];
    NSArray *versionBits = [versionString componentsSeparatedByString:@"."];
    for (int i = 0; i < versionBits.count; i++) {
        versionNumber += [[versionBits objectAtIndex:i] intValue]*pow(10,2-i);
    }
    NSLog(@"Running on iOS version %i",versionNumber);
    
    doRotate = YES;
    setPBC = NO;
    boardSize = 1;
    letterDistribution = 0;
    minWords = 0;
    minPoints = 0;
    minLength = 0;
    blocks = [[NSMutableArray alloc] initWithCapacity:25];
    smallBlocks = [[NSMutableArray alloc] initWithCapacity:16];
    
    NSString *letters = [@"USENSSWTNUOOEEEEMAOTOUOTNNNEDARDHOHLDLONHRTTOTEMIIEITTORWGRVMUAEEGTESCNCYPRIRREIICTLFRYSIAAEAEEESCTIPEGNAMENAFAASRIPCETLYRFSPINDLOHRNHDTODARASFIQKZXBJ" lowercaseString];
    NSString *smallLetters = [@"IROFBXOCATAINWDSOEQOMABJACRSELORSMHAGTNVIEYIBLTAPCAEDMUIGWLROTNDUKYBTLAIYFHIEEETSPULIENPSHEAVNZD" lowercaseString];
    char faces[6];
    for (int i = 0; i<25; i++) {
        for (int j = 0; j<6; j++) {
            faces[j]  = [letters characterAtIndex:(6*i+j)];
        };
        [blocks addObject:[[BGLBlock alloc] initWithFaces:faces]];
    };
    for (int i = 0; i<16; i++) {
        for (int j = 0; j<6; j++) {
            faces[j] = [smallLetters characterAtIndex:(6*i+j)];
        };
        [smallBlocks addObject:[[BGLBlock alloc] initWithFaces:faces]];
    };
    
    int freqs[26] = {82,15,28,43,127,22,20,61,70,1,8,40,24,68,75,19,1,60,63,90,27,10,24,1,20,1};
    char alphaLetters[26] = "abcdefghijklmnopqrstuvwxyz";
    
    int c = 0;
    for (int i = 0; i < 26; i++) {
        alphabet[i] = alphaLetters[i];
        for (int j = 0; j < freqs[i]; j++) {
            freqLetters[c] = alphabet[i];
            c++;
        }
    }
        
    self.mainViewController = [[[BGLMainViewController alloc] initWithNibName:@"BGLMainViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
