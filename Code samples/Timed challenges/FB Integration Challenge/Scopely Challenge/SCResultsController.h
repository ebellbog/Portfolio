//
//  SCResultsController.h
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import <UIKit/UIKit.h>
#import "SCAppDelegate.h"
#import "SCFunController.h"

@interface SCResultsController : UIViewController {
    NSArray *sortedFriends;
    IBOutlet UITextView *column1;
    IBOutlet UITextView *column2;
}

- (id)initWithFriends:(NSArray *)friends;
- (void)handleTapGesture:(UIGestureRecognizer *)tapRecognizer;

@property (nonatomic, assign) NSArray *sortedFriends;
@property (nonatomic, retain) UITextView *column1;
@property (nonatomic, retain) UITextView *column2;

@end
