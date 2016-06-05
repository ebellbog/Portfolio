//
//  POPhotoReviewController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/16/14.
//
//

#import "POPhotoReviewController.h"
#import "POCommonMethods.h"

@interface POPhotoReviewController ()

@property (nonatomic, weak) IBOutlet UIImageView *bottomBar;
@property (nonatomic) POScrollController *scrollController;

@end


@implementation POPhotoReviewController

- (id)initWithPhoto:(UIImage *)photo {
   if (self = [super init]) {
      _scrollController = [[POScrollController alloc] init];
      
      self.scrollController.scrollView = [[UIScrollView alloc] init];
      self.scrollController.photoView = [[UIImageView alloc] initWithImage:photo];
      
      BOOL landscape = (self.scrollController.photoView.image.size.width > self.scrollController.photoView.image.size.height);
      
      int height, width;
      CGRect screenBounds = orientationIndependentScreenBounds();
      width = screenBounds.size.width;
      
      if (landscape) height = width*3/4;
      else height = width*4/3;
      
      self.scrollController.photoView.frame = CGRectMake(0, 0, width, height);
   }
   return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.scrollController.scrollView.contentSize = self.scrollController.photoView.frame.size;
   [self.scrollController.scrollView addSubview:self.scrollController.photoView];
   
   [self.view insertSubview:self.scrollController.scrollView atIndex:0];

   UIDeviceOrientation myOrientation = [[UIDevice currentDevice] orientation];
   if (UIDeviceOrientationIsLandscape(myOrientation)) {
      [self.scrollController updateDisplayForOrientation:UIInterfaceOrientationLandscapeLeft];
   } else {
      [self.scrollController updateDisplayForOrientation:UIInterfaceOrientationPortrait];
   }
   
   
   self.bottomBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
   _isFavorited = NO;
}

- (BOOL)prefersStatusBarHidden {
   return YES;
}


- (NSUInteger)supportedInterfaceOrientations{
   return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate{
   return YES;
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
   NSDictionary *infoDict = @{@"orientation" : [NSNumber numberWithInt:toInterfaceOrientation], @"duration" : [NSNumber numberWithFloat:duration]};
   
   [[NSNotificationCenter defaultCenter] postNotificationName:@"rotateScrollView" object:nil userInfo:infoDict];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button methods

- (IBAction)toggleFavorite:(id)sender {
   if (self.isFavorited == NO) {
      [(UIButton *)sender setImage:[UIImage imageNamed:@"Favorite_button(filled)"] forState:UIControlStateNormal];
      self.isFavorited = YES;
   } else {
      [(UIButton *)sender setImage:[UIImage imageNamed:@"Favorite_button"] forState:UIControlStateNormal];
      self.isFavorited = NO;
   }
}

- (IBAction)done:(id)sender {
   //Note that for 'Save' button tag = 0, for 'Delete' button tag = 1
   [self.delegate reviewControllerDidFinishWithDeletion:[(UIView *)sender tag] andFavorite:self.isFavorited];
}


@end