//
//  POLibraryFullscreenCell.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/11/14.
//
//

#import "POLibraryFullscreenCell.h"
#import "POCommonMethods.h"
#import "POScrollController.h"

@interface POLibraryFullscreenCell ()

@property (nonatomic) POScrollController *scrollController;

@end


@implementation POLibraryFullscreenCell

- (id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   if (self) {
      UIImageView *photoView = [[UIImageView alloc] initWithFrame:CGRectZero];
      photoView.contentMode = UIViewContentModeScaleAspectFit;
      
      UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
      scrollView.clipsToBounds = YES;
   
      [scrollView addSubview:photoView];
      [self.contentView addSubview:scrollView];
      
      self.backgroundColor = [UIColor whiteColor];
      
      _scrollController = [[POScrollController alloc] init];
      self.scrollController.photoView = photoView;
      self.scrollController.scrollView = scrollView;
   }
   return self;
}

- (void)setPhoto:(UIImage *)photo {
   self.scrollController.photoView.image = photo;
   
   BOOL landscape = (self.scrollController.photoView.image.size.width > self.scrollController.photoView.image.size.height);
   
   int height, width;
   CGRect screenBounds = orientationIndependentScreenBounds();
   width = screenBounds.size.width;
   
   if (landscape) height = width*3/4;
   else height = width*4/3;
   
   self.scrollController.photoView.frame = CGRectMake(0, 0, width, height);
   self.scrollController.scrollView.frame = self.bounds;
   self.scrollController.scrollView.contentSize = self.scrollController.photoView.frame.size;
      
   UIDeviceOrientation myOrientation = [[UIDevice currentDevice] orientation];
   if (UIDeviceOrientationIsLandscape(myOrientation)) {
      [self.scrollController updateDisplayForOrientation:UIInterfaceOrientationLandscapeLeft];
   } else {
      [self.scrollController updateDisplayForOrientation:UIInterfaceOrientationPortrait];
   }
}

- (void)layoutSubviews {
   [super layoutSubviews];
   self.scrollController.scrollView.frame = self.bounds;
//   NSLog(@"Laying out subviews...");
   
}

//#pragma mark - UIScrollViewDelegate methods
//
//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
//   return self.scrollController.photoView;
//}
//
//#pragma mark - Helper methods
//
//- (float)zoomFactorToFit {
//   BOOL landscapePhoto = (self.photoView.image.size.width > self.photoView.image.size.height);
//   BOOL deviceLandscape = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
//   
//   CGRect screenBounds = orientationIndependentScreenBounds();
//   
//   float zoomFactor;
//   float photoAspectRatio = 4.0/3.0;
//   float screenAspectRatio = screenBounds.size.height/screenBounds.size.width;
//   
//   if ((landscapePhoto ^ deviceLandscape) || isWidescreen()) zoomFactor = self.scrollView.minimumZoomScale;
//   else zoomFactor = self.scrollView.minimumZoomScale * screenAspectRatio/photoAspectRatio;
//   
//   return zoomFactor;
//}
//
@end
