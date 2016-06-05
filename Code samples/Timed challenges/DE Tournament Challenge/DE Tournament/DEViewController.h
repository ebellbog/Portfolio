#import <UIKit/UIKit.h>
#import "DETree.h"
#import "DESelectionController.h"
#import "DEAppDelegate.h"

@interface DEViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate, DESelectionControllerDelegate> {
    NSMutableDictionary *teamLogos;
    NSMutableDictionary *teamURLs;
    DETree *tournament;
    
    NSMutableArray *teamViews;
    UIScrollView *scrollView;
    IBOutlet UIView *bracketView;
    
    BOOL inFinals;
    BOOL alertDisplaying; //Ensures that only one alert pops up at a time, even when multiple images are missing due to connectivity
}

- (void)loadTournamentFromData:(NSData *)data;
- (void)reloadImageWithName:(NSString *)name;
- (IBAction)playTournament;


//Checks network status before trying to load JSON data; gets called whenever network status changes
- (void)proceedIfConnected;


//Updates display to reflect changes in tournament
- (void)printTreeToViews;


//Allows zooming to full (all the way out) or focus (in at point) through simple gesture
- (void)handleDoubleTap:(UIGestureRecognizer *)gesture;


//Displays team names and logos so user can select a winner
- (void)presentSelectorForTeams:(NSArray *)teamNames;

@property (nonatomic, retain) NSMutableDictionary *teamLogos;
@property (nonatomic, retain) NSMutableDictionary *teamURLs;
@property (nonatomic, retain) NSMutableArray *teamViews;
@property (nonatomic, retain) IBOutlet UIView *bracketView;
@property (nonatomic, retain) DETree *tournament;


@end
