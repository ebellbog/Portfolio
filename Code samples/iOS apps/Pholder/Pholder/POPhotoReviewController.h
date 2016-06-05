//
//  POPhotoReviewController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/16/14.
//
//

#import <UIKit/UIKit.h>
#import "POScrollController.h"

@class POPhotoReviewController;

@protocol POPhotoReviewControllerDelegate
-(void)reviewControllerDidFinishWithDeletion:(BOOL)doDelete andFavorite:(BOOL)favorite;
@end


@interface POPhotoReviewController : UIViewController

@property (nonatomic) BOOL isFavorited;
@property (weak, nonatomic) id <POPhotoReviewControllerDelegate> delegate;

- (IBAction)done:(id)sender;
- (id)initWithPhoto:(UIImage *)photo;

@end
