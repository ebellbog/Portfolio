//
//  POPhotoScrollController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/10/14.
//
//

#import <UIKit/UIKit.h>

@class POScrollController;

@interface POScrollController : NSObject <UIScrollViewDelegate>

@property (nonatomic) UIImageView *photoView;
@property (nonatomic) UIScrollView *scrollView;

- (void)updateDisplayForOrientation:(UIInterfaceOrientation)newOrientation;
- (void)updateDisplayForOrientation:(UIInterfaceOrientation)newOrientation withDuration:(NSTimeInterval)duration;


@end