//
//  FunController.h
//  Scopely Challenge
//
//  Created by Elana Bogdan on 2/24/13.


#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

#import "SCAppDelegate.h"
#import "SCResultsController.h"

@class SCAppDelegate;

@interface SCFunController : UIViewController <UIAlertViewDelegate> {
    IBOutlet UILabel *friendA;
    IBOutlet UILabel *friendB;
    
    IBOutlet UILabel *progressLabel;
    IBOutlet UIProgressView *progressBar;

    
    FBProfilePictureView *leftPhoto, *rightPhoto;
    SCAppDelegate *appDel;
    
    NSArray *friendList;
    int *friendScores;
    int questionNumber;
}

- (void)handleLeftSwipe:(UISwipeGestureRecognizer *)swipeRecognizer;
- (void)handleRightSwipe:(UISwipeGestureRecognizer *)swipeRecognizer;

- (void)handleLeftTap:(UITapGestureRecognizer *)tapRecognizer;
- (void)handleRightTap:(UITapGestureRecognizer *)tapRecognizer;

- (void)receiveFriends;
- (void)updateFriendPair;
- (void)incrementQuestion;


@property (nonatomic, retain) SCAppDelegate *appDel;
@property (nonatomic, retain) NSArray *friendList;
@property (nonatomic, retain) FBProfilePictureView *leftPhoto;
@property (nonatomic, retain) FBProfilePictureView *rightPhoto;

@property (nonatomic, retain) UILabel *friendA;
@property (nonatomic, retain) UILabel *friendB;
@property (nonatomic, retain) UILabel *progressLabel;
@property (nonatomic, retain) UIProgressView *progressBar;

@end
