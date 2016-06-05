//
//  POPhotoScrollController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/16/14.
//
//


/* NOTE: This class is not a UIViewController, despite having "controller"
 in its name. It is an attempt to modularize all of the logic necessary
 for handling the zoom, scroll, and rotation effects present in the Photos
 app. Currently, it is only being used in the POPhotoReviewController,
 because attempts to incorporate it into the POLibraryFullscreenController
 yielded glitchy results.
 */

#import "POScrollController.h"
#include "POCommonMethods.h"

@interface POScrollController ()

@property (nonatomic) int animationFramesRemaining;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@end


@implementation POScrollController

- (id)init {
   self = [super init];
   if (self) {
      _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(receivedTap)];
      self.tapRecognizer.numberOfTapsRequired = 2;
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplayWithNotification:) name:@"rotateScrollView" object:nil];
   }
   return self;
}


- (void)setScrollView:(UIScrollView *)scrollView {
   if (_scrollView) {
      [self.scrollView removeGestureRecognizer:self.tapRecognizer];
   }
   
   [scrollView addGestureRecognizer:self.tapRecognizer];
   scrollView.delegate = self;
   
   _scrollView = scrollView;
}


- (void)dealloc {
   self.photoView = nil;
   self.scrollView = nil;
   
   [[NSNotificationCenter defaultCenter] removeObserver:self name:@"rotateScrollView" object:nil];
}


#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
   return self.photoView;
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
   [self centerScrollViewContent];
}


- (void)centerScrollViewContent {
   CGFloat offsetX = MAX((self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5, 0.0);
   CGFloat offsetY = MAX((self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5, 0.0);
   
   //In library fullscreen view, status bar seems to displace scroll view
   if ([UIApplication sharedApplication].statusBarHidden == NO) {
      offsetY -= 20;
   };
   
   self.photoView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX,
                                          self.scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)centerScrollViewContentWithDuration:(NSTimeInterval)duration {
   int framesPerSecond = 60;
   duration = duration*.8;
   
   CGFloat offsetX = MAX((self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5, 0.0);
   CGFloat offsetY = MAX((self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5, 0.0);
   
   //In library fullscreen view, status bar seems to displace scroll view
   if ([UIApplication sharedApplication].statusBarHidden == NO) {
      offsetY -= 20;
   };
   
   self.animationFramesRemaining = duration*framesPerSecond;
   
   float deltaX = ((self.scrollView.contentSize.width * 0.5 + offsetX) - self.photoView.center.x)/self.animationFramesRemaining;
   float deltaY = ((self.scrollView.contentSize.height * 0.5 + offsetY) - self.photoView.center.y)/self.animationFramesRemaining;
   
   [NSTimer scheduledTimerWithTimeInterval:(1.0f/framesPerSecond)
                                    target:self
                                  selector:@selector(shiftScrollViewByDistance:)
                                  userInfo: @[[NSNumber numberWithFloat:deltaX], [NSNumber numberWithFloat:deltaY]]
                                   repeats:YES];
}

- (void)shiftScrollViewByDistance:(NSTimer *)timer {
   float deltaX = [[[timer userInfo] objectAtIndex:0] floatValue];
   float deltaY = [[[timer userInfo] objectAtIndex:1] floatValue];
   self.photoView.center = CGPointMake(self.photoView.center.x + deltaX,
                                          self.photoView.center.y + deltaY);
   self.animationFramesRemaining--;
   if (self.animationFramesRemaining == 0) {
      [timer invalidate];
   }
}


#pragma mark - Device orientation methods


- (float)zoomFactorToFit {
   BOOL landscapePhoto = (self.photoView.image.size.width > self.photoView.image.size.height);
   BOOL deviceLandscape = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
   
   CGRect screenBounds = orientationIndependentScreenBounds();
   
   float zoomFactor;
   float photoAspectRatio = 4.0/3.0;
   float screenAspectRatio = screenBounds.size.height/screenBounds.size.width;
   
   if ((landscapePhoto ^ deviceLandscape) || isWidescreen()) zoomFactor = self.scrollView.minimumZoomScale;
   else zoomFactor = self.scrollView.minimumZoomScale * screenAspectRatio/photoAspectRatio;
   
   return zoomFactor;
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
   [self updateDisplayForOrientation:toInterfaceOrientation withDuration:duration];
}


- (void)updateDisplayForOrientation:(UIInterfaceOrientation)newOrientation {
   [self updateDisplayForOrientation:newOrientation withDuration:0];
}

- (void)updateDisplayWithNotification:(NSNotification *)notification {
   NSLog(@"Received notification");
   NSDictionary *infoDict = [notification userInfo];
   UIInterfaceOrientation orientation = [infoDict[@"orientation"] intValue];
   float duration = [infoDict[@"duration"] floatValue];
   
   [self updateDisplayForOrientation:orientation withDuration:duration];
}

- (void)updateDisplayForOrientation:(UIInterfaceOrientation)newOrientation withDuration:(NSTimeInterval)duration {
   [UIView animateWithDuration:duration
                         delay:0.0
                       options:UIViewAnimationOptionBeginFromCurrentState //Prevents jumpy behavior
                    animations:^{
                       
                       CGRect screen_bounds = orientationIndependentScreenBounds();
                       
                       BOOL fillsDisplay = (self.photoView.frame.size.width-self.scrollView.frame.size.width >= 1.0 &&
                                            self.photoView.frame.size.height - self.scrollView.frame.size.height >= 1.0);
                       
                       float xOffset = self.scrollView.contentOffset.x;
                       float yOffset = self.scrollView.contentOffset.y;
                       
                       //Update scroll view for landscape orientation
                       if (newOrientation == UIInterfaceOrientationLandscapeLeft || newOrientation == UIInterfaceOrientationLandscapeRight) {
                          self.scrollView.frame = CGRectMake(0, 0, screen_bounds.size.height, screen_bounds.size.width);
                          self.scrollView.bounds = self.scrollView.frame;
                       }
                       
                       //For portrait orientation
                       else if (newOrientation == UIInterfaceOrientationPortrait) {
                          self.scrollView.frame = screen_bounds; //standard layout
                          self.scrollView.bounds = self.scrollView.frame;
                       }
                       
                       //Update zoom limits
                       float minZoomScale;
                       float zoomHeight = self.photoView.bounds.size.height / self.scrollView.frame.size.height;
                       float zoomWidth = self.photoView.bounds.size.width / self.scrollView.frame.size.width;
                       
                       if(zoomWidth > zoomHeight)
                       {
                          minZoomScale = 1.0 / zoomWidth;
                       }
                       else
                       {
                          minZoomScale = 1.0 / zoomHeight;
                       }
                       
                       float previousZoom = self.scrollView.zoomScale;
                       [self.scrollView setMinimumZoomScale:minZoomScale];
                       [self.scrollView setMaximumZoomScale:minZoomScale*3]; //TODO: consider increasing
                       
                       //Zoom while rotating to fit to screen as needed
                       if (minZoomScale > previousZoom || fillsDisplay == NO || duration == 0.0) {
                          [self.scrollView setZoomScale:[self zoomFactorToFit] animated:YES];
                       }
                       
                       else { //If view will not be fit to screen, instead adjust to match its previous scroll position
                          
                          float newXOffset;
                          float maxXOffset = self.scrollView.contentSize.width-self.scrollView.frame.size.width;
                          if (maxXOffset < 0) { //Photo does not fill screen width-wise
                             newXOffset = 0; //So center along x axis
                          } else {
                             newXOffset = fmin(xOffset, maxXOffset); //If offset exceeds this, we will introduce border space
                          }
                          
                          float newYOffset;
                          float maxYOffset = self.scrollView.contentSize.height-self.scrollView.frame.size.height;
                          if (maxYOffset < 0) { //Photo does not fill screen height-wise
                             newYOffset = 0; //So center along y axis
                          }
                          else {
                             newYOffset = fmin(yOffset, maxYOffset);
                          }
                          
                          [self.scrollView setContentOffset:CGPointMake(newXOffset, newYOffset) animated:NO];
                       }
                       
                       [self centerScrollViewContent];
                       
                    }
                    completion:nil];
   
//   NSLog(@"Scroll view frame: width = %f, height = %f", self.scrollView.frame.size.width, self.scrollView.frame.size.height);
//   NSLog(@"Photo view frame: width = %f, height = %f", self.photoView.frame.size.width, self.photoView.frame.size.height);
   
   //   if (duration == 0) {
   //      [self centerScrollViewContent];
   //   } else {
   //      [self centerScrollViewContentWithDuration:duration];
   //   }
}


#pragma mark - UIGestureRecognizer methods

- (void)receivedTap {
   float zoomFactor = [self zoomFactorToFit];
   if (self.scrollView.zoomScale == zoomFactor) {
      [self.scrollView setZoomScale:self.scrollView.maximumZoomScale animated:YES]; //TODO: zoom to point
   } else {
      [self.scrollView setZoomScale:[self zoomFactorToFit] animated:YES];
   }
}


@end