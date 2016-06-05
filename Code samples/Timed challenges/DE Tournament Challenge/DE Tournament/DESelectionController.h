#import <UIKit/UIKit.h>

@protocol DESelectionControllerDelegate
- (void)selectionControllerDidFinishWithWin:(BOOL)win;
- (void)reloadImageWithName:(NSString *)name;
- (NSMutableDictionary *)teamLogos;

@end


@interface DESelectionController : UIViewController {
    IBOutlet UIButton *aButton;
    IBOutlet UIButton *bButton;
    
    IBOutlet UILabel *aLabel;
    IBOutlet UILabel *bLabel;
    
    NSString *aName;
    NSString *bName;
}

- (id)initWithTeamA:(NSString *)teamA andTeamB:(NSString *)teamB;
- (void)refreshButtons:(NSNotification *)notification;

- (IBAction)selectWinner:(id)sender;

@property (nonatomic, assign) id <DESelectionControllerDelegate> delegate;
@property (nonatomic, retain) UIButton *aButton;
@property (nonatomic, retain) UIButton *bButton;
@property (nonatomic, retain) UILabel *aLabel;
@property (nonatomic, retain) UILabel *bLabel;
@property (nonatomic, retain) NSString *aName;
@property (nonatomic, retain) NSString *bName;

@end
