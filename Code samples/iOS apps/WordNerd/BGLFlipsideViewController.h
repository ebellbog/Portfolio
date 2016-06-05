//
//  BGLFlipsideViewController.h
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import <UIKit/UIKit.h>

@class BGLAppDelegate;

@protocol BGLFlipsideViewControllerDelegate
- (void)modalViewControllerDidFinish;
@end

@interface BGLFlipsideViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UISwitch *doRotate;
    IBOutlet UISwitch *setPBC;

    IBOutlet UISegmentedControl *boardSize;
    IBOutlet UISegmentedControl *letterDistribution;
    
    IBOutlet UITextField *minPoints;
    IBOutlet UITextField *minWords;
    IBOutlet UITextField *minLength;
    
    BGLAppDelegate *appDel;
}

@property (assign, nonatomic) IBOutlet id <BGLFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;
- (void)animateFlipView:(NSInteger)dist;

@end
