//
//  BGLResultsViewController.h
//  WordNerd
//
//  Created by Elana Bogdan on 12/12/11.
//

#import <UIKit/UIKit.h>

@class BGLMainViewController;

@protocol BGLResultsViewControllerDelegate
- (void)modalViewControllerDidFinish;
@end

@interface BGLResultsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray *stats;
    NSArray *statNames;
}

@property (nonatomic, assign) IBOutlet id <BGLResultsViewControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *stats;
@property (nonatomic, retain) NSArray *statNames;

- (IBAction)done;
- (id)initWithNibName:(NSString *)nibNameOrNil andSender:(BGLMainViewController *)mainDel;

@end