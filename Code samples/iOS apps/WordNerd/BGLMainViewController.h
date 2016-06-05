//
//  BGLMainViewController.h
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import "BGLFlipsideViewController.h"
#import "BGLWordViewController.h"
#import "BGLResultsViewController.h"
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@class BGLAppDelegate;

@interface BGLMainViewController : UIViewController <BGLFlipsideViewControllerDelegate, BGLWordViewControllerDelegate, BGLResultsViewControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIAccelerometerDelegate> {
    BGLAppDelegate *appDel;
    BOOL remix;
    BOOL resize;
    BOOL reorient;
    
    BOOL ninja;
    int lastButton;
    
    UITextChecker *textChecker;
    IBOutlet UITextField *letterSelect;
    
    IBOutlet UIActivityIndicatorView *generatingBoard;
    
    NSInteger lastButtonIndex, wordCount, pointCount, maxWord, bestPoints;
    float timeCount;
        
    NSArray *foundList;
    NSMutableArray *blockCollector, *PBCList;
    NSMutableDictionary *foundDict;
    char boardArray[25];
    char bestBoard[25];
    
    NSIndexPath *wordIndex;
    
    NSTimer *countdown;
    IBOutlet UIButton *timeButton;
    
    UIView *blocker;
    UINavigationController *navCon;
    
    IBOutlet UIImageView *backgroundImage;
    AVAudioPlayer *player;
}

@property (nonatomic) BOOL remix;
@property (nonatomic) BOOL resize;
@property (nonatomic) BOOL reorient;
@property (nonatomic) NSInteger wordCount;
@property (nonatomic) NSInteger pointCount;
@property (nonatomic) NSInteger maxWord;
@property (nonatomic, retain) IBOutlet UITextField *letterSelect;
@property (nonatomic, retain) NSArray *foundList;
@property (nonatomic, retain) NSMutableArray *PBCList;
@property (nonatomic, retain) NSMutableArray *blockCollector;
@property (nonatomic, retain) NSMutableDictionary *foundDict;
@property (nonatomic, retain) NSIndexPath *wordIndex;
@property (nonatomic, retain) NSTimer *countdown;
@property (nonatomic, retain) UINavigationController *navCon;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImage;
@property (nonatomic, retain) AVAudioPlayer *player;

- (IBAction)showInfo:(id)sender;
- (IBAction)showStats;
- (void)showWords;

- (IBAction)shakeBusily:(id)sender;
- (void)shakeBoard;
- (void)genBoard;
- (void)assignBoard:(BOOL)doRotate;

- (IBAction)requestAnalysis;
- (void)analyzeBoard:(BOOL)makeList;
- (void)getStats;

- (IBAction)editLetter:(UIButton *)sender;

- (IBAction)setTimer:(id)sender;
- (void)updateTimeLabel;
- (void)makeBeep:(int)type;

- (NSArray *)arrayToList:(NSArray *)array;
- (BOOL)adjacencyBetween:(NSInteger)current and:(NSInteger)previous;
- (void)incrementIndex;

- (void)startAcceleration;
- (void)stopAcceleration;

- (void)blackOut;
- (void)ninjagram;
- (void)sparkle;
- (BOOL)isNinjaDay;
- (void)deliverGram;
- (void)evacuateNinjas;

@end