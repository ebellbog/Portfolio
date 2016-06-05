//
//  POImagePickerController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/16/14.
//
//

#import "PODataManager.h"
#import "POImagePickerController.h"
#import "POLibraryNavigationController.h"
#import "POLibraryRootController.h"
#import "POMainViewController.h"
#import "POAppDelegate.h"
#import "POCommonMethods.h"
#import "POAssetsLibrary.h"

#define kMENUCELLHEIGHT 30.0f
#define kDefaultAlbum @"DefaultAlbumNameString"
#define kSelectAlbum @"SelectAlbumNameString"

// Pholder names that require special handling
#define BLACK_LIST @[MAIN_DATA, THUMBS_DATA, @"Camera Roll", @"My Photo Stream", @"Pholder Favorites", @"Favorites"]


@interface POImagePickerController ()

@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL isSwitchingModes;

@property (nonatomic) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIImageView *bottomBar;
@property (nonatomic, weak) IBOutlet UIButton *shutterButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet UIButton *flipCameraButton;
@property (nonatomic, weak) IBOutlet UIButton *albumButton;
@property (nonatomic, weak) IBOutlet UILabel *videoTimerLabel;
@property (nonatomic, weak) IBOutlet UILabel *videoRecordingLight;

@property (nonatomic, weak) NSTimer *videoTimer;
@property (nonatomic) float timeCount;

@property (nonatomic) IBOutlet UIView *mediaTypeViewProgrammatic;
@property (nonatomic, weak) IBOutlet UILabel *videoLabel;
@property (nonatomic, weak) IBOutlet UILabel *photoLabel;

@property (nonatomic) IBOutlet UIView *settingsView;
@property (nonatomic, weak) IBOutlet UIButton *settingsButton;
@property (nonatomic, weak) IBOutlet UISwitch *exportSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *reviewSwitch;

@property (nonatomic) UIView *menuView;

@property (nonatomic) POLibraryNavigationController *libraryNavigator;

@property (nonatomic) UIPinchGestureRecognizer *zoomBlocker;

@end


@implementation POImagePickerController

- (id)init
{
   if (self = [super init]) {
      //TODO: Confirm, either here or in MainViewController, that hardware exists/is available
      
      self.modalPresentationStyle = UIModalPresentationCurrentContext;
      self.sourceType = UIImagePickerControllerSourceTypeCamera;
      self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.sourceType]; //enables video if it's an option
      self.videoQuality = UIImagePickerControllerQualityTypeHigh;
      self.showsCameraControls = NO;

      self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
      self.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
      _photoFlashModeRef = self.cameraFlashMode;
      _videoFlashModeRef = UIImagePickerControllerCameraFlashModeOff;
      _videoMode = NO;
      _isRecording = NO;
      _isSwitchingModes = NO;
      
      _isDisplayingSettings = NO;
      _menuView = nil;
      _currentReticle = nil;
      
      _currentAlbum = kDefaultAlbum;
      _albumNames = [[NSMutableSet alloc] init];
      _oldAlbumData = [[NSMutableDictionary alloc] init];
      _thumbnailForAlbum = [[NSMutableDictionary alloc] init];

      [[NSBundle mainBundle] loadNibNamed:@"Overlay" owner:self options:nil];
      self.overlayView.frame = self.view.frame;
      self.overlayView.backgroundColor = [UIColor clearColor];
      
      CGRect screen_bounds = [UIScreen mainScreen].bounds;
      int screen_height = MAX(screen_bounds.size.width, screen_bounds.size.height);

      self.mediaTypeViewProgrammatic.frame = CGRectMake(83, screen_height-89, 97, 22); //TODO: iPhone 6+ compatibility?
      self.mediaTypeViewProgrammatic.backgroundColor = [UIColor clearColor];
      [self.overlayView addSubview:self.mediaTypeViewProgrammatic];
      
      self.cameraOverlayView = self.overlayView;
      self.overlayView = nil;
      
      self.bottomBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
      self.videoTimerLabel.alpha = 0.0f;
      self.videoRecordingLight.alpha = 0.0f;

      _videoTimer = nil;
      
      _libraryNavigator = [[POLibraryNavigationController alloc] init];
      self.libraryNavigator.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      
      UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
      leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
      
      UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
      rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
      
      [self.view addGestureRecognizer:leftSwipeRecognizer];
      [self.view addGestureRecognizer:rightSwipeRecognizer];
      
      _zoomBlocker = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
      self.zoomBlocker.cancelsTouchesInView = YES;
    }
    return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];

   if (isWidescreen()) {
      self.cameraViewTransform = CGAffineTransformMakeTranslation(0, 40);
   }
   
   self.settingsView.frame = CGRectMake(0, self.view.frame.size.height-115, self.view.frame.size.width, 115);
   [self.view insertSubview:self.settingsView atIndex:0];
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAlbumData) name:@"ALAssetsGroupUpdate" object:nil];
   
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSString *currentAlbum = [defaults objectForKey:@"currentAlbum"];
   NSNumber *doReviewPhotos = [defaults objectForKey:@"doReviewPhotos"];
   NSNumber *doExport = [defaults objectForKey:@"doExport"];
   
   if (currentAlbum) {
      self.currentAlbum = currentAlbum;
      [self setAlbumNameWithFade:currentAlbum];
   }
   
   if (doReviewPhotos) {
      [(POMainViewController *)self.delegate setDoReviewPhotos:doReviewPhotos.boolValue];
      [self.reviewSwitch setOn:doReviewPhotos.boolValue animated:NO];
      NSLog(@"Restored doReview setting to: %@", doReviewPhotos);
   } else {
      [self.reviewSwitch setOn:YES animated:NO];
   }
   
   if (doExport) {
      [(POAppDelegate *)[[UIApplication sharedApplication] delegate] setDoExport:doExport.boolValue];
      [self.exportSwitch setOn:doExport.boolValue animated:NO];
      NSLog(@"Restored doExport setting to: %@", doExport);
   } else {
      [self.exportSwitch setOn:YES animated:NO];
   }
}


- (void)viewDidAppear:(BOOL)animated {
   [super viewDidAppear:animated];
   [[(POMainViewController *)self.delegate locationManager] startUpdatingLocation];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden {
   return YES;
}

- (void)dealloc {
   self.libraryNavigator = nil;
   self.videoTimer = nil;
   self.mediaTypeViewProgrammatic = nil;
   self.albumNames = nil;
   self.oldAlbumData = nil;
   self.thumbnailForAlbum = nil;
   
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Button actions


- (IBAction)captureMedia:(id)sender {
   
   if (self.currentReticle) {
      [self.currentReticle removeFromSuperview];
      self.currentReticle = nil;
   }

   
   if (self.videoMode == NO) {
      [self takePicture];
      [self pickerIsNowBusy:YES];

      //Simple shutter animation
      [UIView animateWithDuration:0.1
                       animations:^{
                          self.cameraOverlayView.backgroundColor = [UIColor blackColor];
                       }
                       completion:^(BOOL finished) {
                          [UIView animateWithDuration:0.1
                                           animations:^{ self.cameraOverlayView.backgroundColor = [UIColor clearColor]; }];
                       }];
   }
   
   else {
      if (self.isRecording == NO) {
         [self startRecording];
         self.isRecording = YES;
      }
      else {
         [self stopRecording];
         self.isRecording = NO;
      }
   }
}

- (void)startRecording {
   [self.shutterButton setImage:[UIImage imageNamed:@"Shutter_button(stop_video)"] forState:UIControlStateNormal];
   self.albumButton.enabled = NO;
   
   [UIView animateWithDuration:0.2 animations:^{
      self.albumButton.alpha = 0.0f;
      self.videoTimerLabel.alpha = 1.0f;
   }];
   
   [self startVideoCapture];
   [self startTimer];
   NSLog(@"Began capturing video...");
}

- (void)stopRecording {
   [self.shutterButton setImage:[UIImage imageNamed:@"Shutter_button(start_video)"] forState:UIControlStateNormal];
   self.albumButton.enabled = YES;
   
   [UIView animateWithDuration:0.2 animations:^{
      self.albumButton.alpha = 1.0f;
      self.videoTimerLabel.alpha = 0.0f;
   }];
   
   [self stopVideoCapture];
   [self stopTimer];
   NSLog(@"Ended video capture.");
}


- (IBAction)flipCamera:(id)sender {
   if (self.cameraDevice == UIImagePickerControllerCameraDeviceFront) {
      self.cameraDevice = UIImagePickerControllerCameraDeviceRear;

      if (self.photoFlashModeRef == UIImagePickerControllerCameraFlashModeAuto) {
         [self.flashButton setImage:[UIImage imageNamed:@"Flash_auto"] forState:UIControlStateNormal];
      }
      else if (self.photoFlashModeRef == UIImagePickerControllerCameraFlashModeOn) {
         [self.flashButton setImage:[UIImage imageNamed:@"Flash_on"] forState:UIControlStateNormal];
      }
      self.flashButton.enabled = YES;
      
      NSLog(@"Switched to rear camera.");
   }
   else {
      self.cameraDevice = UIImagePickerControllerCameraDeviceFront;
      [self.flashButton setImage:[UIImage imageNamed:@"Flash_off"] forState:UIControlStateNormal];
      self.flashButton.enabled = NO;
      NSLog(@"Switched to front camera.");
   }
   
   if (self.currentReticle) {
      [self.currentReticle removeFromSuperview];
      self.currentReticle = nil;
   }
}

- (IBAction)changeFlashMode:(id)sender {
   UIImagePickerControllerCameraFlashMode *flashMode;
   if (self.videoMode) {
      flashMode = &_videoFlashModeRef;
   } else {
      flashMode = &_photoFlashModeRef;
   }
   
   if (*flashMode == UIImagePickerControllerCameraFlashModeOn) {
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
      *flashMode = UIImagePickerControllerCameraFlashModeOff;
      NSLog(@"Set flash mode to off.");
   }
   else if (*flashMode == UIImagePickerControllerCameraFlashModeOff) {
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
      *flashMode = UIImagePickerControllerCameraFlashModeAuto;
      NSLog(@"Set flash mode to auto.");
   }
   else {
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
      *flashMode = UIImagePickerControllerCameraFlashModeOn;
      NSLog(@"Set flash mode to on.");
   }
   
   [self.flashButton setImage:[self imageForFlashMode:*flashMode] forState:UIControlStateNormal];
}

- (UIImage *)imageForFlashMode:(UIImagePickerControllerCameraFlashMode)flashMode {
   switch (flashMode) {
      case UIImagePickerControllerCameraFlashModeOff:
         return [UIImage imageNamed:@"Flash_off"];
      
      case UIImagePickerControllerCameraFlashModeAuto:
         return [UIImage imageNamed:@"Flash_auto"];
         
      case UIImagePickerControllerCameraFlashModeOn:
         return [UIImage imageNamed:@"Flash_on"];
         
      default:
         return nil;
   }
}

- (IBAction)toggleAlbumMenu {
   if (self.menuView) {
      [self hideMenu];
   } else {
      [self displayMenu];
   }
}

- (void)displayMenu {
   [self setAlbumNameWithFade:kSelectAlbum];
   
   UIView *popUp = [[UIView alloc] init];
   popUp.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
   
   float menuItems = self.albumNames.count+2; //extra space for "Default" and "Add new..." buttons
   
   float maxDisplayItems = 10+2*isWidescreen();

   float menuHeight;
   if (menuItems > maxDisplayItems) {
      menuHeight = (maxDisplayItems - 0.2) * kMENUCELLHEIGHT;  // truncate last row a little bit to indicate user should scroll
                                                               // (note: this will not clip any actual text)
   } else {
      menuHeight = menuItems * kMENUCELLHEIGHT;
   }
   
   popUp.frame = CGRectMake(0, 0, 202, menuHeight);
   popUp.layer.anchorPoint = CGPointMake(0.5, 0);
   popUp.layer.position = CGPointMake(160, 39); //move up one to "swallow" masked top border
   popUp.layer.borderColor = [UIColor colorWithWhite:.7 alpha:0.7].CGColor;
   popUp.layer.borderWidth = 1.0;
   
   // mask for hiding top border
   UIView* mask = [[UIView alloc] initWithFrame:CGRectMake(0, 1.0, popUp.frame.size.width, popUp.frame.size.height-1.0)];
   mask.backgroundColor = [UIColor blackColor];
   popUp.layer.mask = mask.layer;
   
   popUp.transform = CGAffineTransformMakeScale(1.0, 0.0);
   
   UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, popUp.bounds.size.width, popUp.bounds.size.height)
                                                         style:UITableViewStylePlain];
   tableView.backgroundColor = [UIColor clearColor];
   tableView.delegate = self;
   tableView.dataSource = self;
   tableView.tag = 111;
   
   //Necessary for compatibility with iOS 8
   if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
      [tableView setSeparatorInset:UIEdgeInsetsZero];
   };
   if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
      [tableView setLayoutMargins:UIEdgeInsetsZero];
   };
   
   [popUp addSubview:tableView];
   self.menuView = popUp;
   
   [self.view addSubview:popUp];
   [UIView animateWithDuration:0.1
                         delay:0
                       options:UIViewAnimationOptionCurveEaseOut
                    animations:^ {
                       self.menuView.transform = CGAffineTransformIdentity;
                    }completion:^(BOOL finished) {
                       [(UITableView *)[self.menuView viewWithTag:111] flashScrollIndicators];
                    }
    ];
   
}

- (void)hideMenu {
   if (!self.menuView) {
      NSLog(@"Error: called collapseMenu when menu was not displaying");
      return;
   }
   
   NSString *newAlbumName;
   if (self.currentAlbum.length > 0) {
      newAlbumName = self.currentAlbum;
   } else {
      newAlbumName = kDefaultAlbum;
   }
   [self setAlbumNameWithFade:newAlbumName];
   
   [UIView animateWithDuration:0.1
                         delay:0
                       options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                    animations:^ {
                       [self.menuView setTransform:CGAffineTransformMakeScale(1.0, 0.01)];
                    }completion:^(BOOL finished) {
                       [self.menuView removeFromSuperview];
                       self.menuView = nil;
                    }];

}


- (IBAction)toggleSettings:(id)sender {
   if (self.isSwitchingModes) return;
   if (self.menuView) [self hideMenu];

   if (self.isDisplayingSettings == NO) {
      [self displaySettings];
      self.isDisplayingSettings = YES;
   } else {
      [self hideSettings];
      if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
         [[(UIGestureRecognizer *)sender view] removeFromSuperview];
      }
      self.isDisplayingSettings = NO;
   }
   
   if (self.currentReticle) {
      [self.currentReticle removeFromSuperview];
      self.currentReticle = nil;
   }
}

- (void)displaySettings {
   UIView *screenShield = [[UIView alloc] init];
   screenShield.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-115);
   screenShield.backgroundColor = [UIColor clearColor];
   
   UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSettings:)];
   [screenShield addGestureRecognizer:tapRecognizer];
   
   [self.view addSubview:screenShield];
   
   [UIView beginAnimations:@"displaySettings" context:nil];
   [UIView setAnimationDuration:0.3];
   
   UIView *cameraView = self.view.subviews[1];
   cameraView.frame = CGRectMake(0, -115, self.view.frame.size.width, self.view.frame.size.height);
   self.cameraOverlayView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
   self.shutterButton.enabled = NO;
   
   [self.settingsButton setImage:[UIImage imageNamed:@"Settings_icon(highlighted)"] forState:UIControlStateNormal];
   self.settingsButton.transform = CGAffineTransformMakeRotation(M_PI/2);
   
   [UIView commitAnimations];

}

- (void)hideSettings {
   [UIView beginAnimations:@"hideSettings" context:nil];
   [UIView setAnimationDuration:0.3];
   
   UIView *cameraView = self.view.subviews[1];
   cameraView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
   self.cameraOverlayView.backgroundColor = [UIColor clearColor];
   self.shutterButton.enabled = YES;
   
   [self.settingsButton setImage:[UIImage imageNamed:@"Settings_icon"] forState:UIControlStateNormal];
   self.settingsButton.transform = CGAffineTransformMakeRotation(0);
   
   [UIView commitAnimations];
   
   [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeDoReviewSetting:(UISwitch *)settingSwitch {
   [(POMainViewController *)self.delegate setDoReviewPhotos:settingSwitch.isOn];
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setObject:[NSNumber numberWithBool:settingSwitch.isOn] forKey:@"doReviewPhotos"];
}

- (IBAction)changeExportSettings:(UISwitch *)settingSwitch {
   [(POAppDelegate *)[[UIApplication sharedApplication] delegate] setDoExport:settingSwitch.isOn];
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setObject:[NSNumber numberWithBool:settingSwitch.isOn] forKey:@"doExport"];
}

- (IBAction)displayPhotoLibrary:(id)sender {
   POLibraryRootController *libraryController = [[POLibraryRootController alloc] init];
   
   libraryController.modalPresentationCapturesStatusBarAppearance = YES;
   libraryController.delegate = self;
   
   self.libraryNavigator.viewControllers = @[libraryController];
   
   [self presentViewController:self.libraryNavigator animated:YES completion:nil];
}


#pragma mark - POLibraryRootController delegate methods

- (void)libraryDidFinish {
   [UIView beginAnimations:@"hide_status_bar" context:nil];
   [UIView setAnimationDuration:0.2];
   [[UIApplication sharedApplication] setStatusBarHidden:YES];
   [UIView commitAnimations];
   
   [self.libraryNavigator dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - POPhotoReviewController delegate method(s)

- (void)presentReviewController:(POPhotoReviewController *)reviewController {
   [self presentViewController:reviewController animated:YES completion:nil];
}


- (void)reviewControllerDidFinishWithDeletion:(BOOL)doDelete andFavorite:(BOOL)favorite {
   [self dismissViewControllerAnimated:YES completion:nil];
   
   POMainViewController *mainController = (POMainViewController *)self.delegate;
   
   if (doDelete) {
      [mainController deleteLastPhoto];
      return;
   }
   if (favorite) {
      [mainController favoriteLastPhoto];
   }
   
   [mainController cacheReviewedPhotoInBackground];
}


#pragma mark - Handle taps

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
   if (self.isDisplayingSettings) return;
   if (self.isSwitchingModes) return;
   if (touches.count != 1) return;
   
   if (self.menuView) {
      [self hideMenu];
      //return; <-- the problem with returning is that, right now, the camera still refocuses
   }
   
   if (self.currentReticle) {
      [self.currentReticle removeFromSuperview]; //Remove any pre-existing reticle
   }
   
   UITouch *aTouch = [touches anyObject];
   CGPoint touchPoint = [aTouch locationInView:self.view];
   
   //For widescreen phones in photo mode, only add reticle in actual area of camera preview
   if (isWidescreen() == YES && self.videoMode == NO) {
      NSLog(@"Checking point x:%f, y:%f", touchPoint.x, touchPoint.y);
      if (touchPoint.y < 40 || touchPoint.y > self.bottomBar.frame.origin.y) return;
   }
   
   POFocusingReticle *reticle = [[POFocusingReticle alloc] initWithCenter:touchPoint andSize:150];
   reticle.endSize = 80;
   reticle.lifeSpan = 1.5;
   
   self.currentReticle = reticle;
   
   [self.cameraOverlayView insertSubview:reticle atIndex:0];
   [reticle startAnimation];
   
//   if (self.videoMode) {
//      self.mediaTypeView.frame = CGRectApplyAffineTransform(self.mediaTypeInitialFrame, CGAffineTransformMakeTranslation(45, 0));
//   }
}




#pragma mark - Handle swipes

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)swipeRecognizer {
   NSLog(@"Handling swipe");
   
   if (self.isSwitchingModes) return;
   
   if (self.currentReticle) {
      [self.currentReticle removeFromSuperview];
      self.currentReticle = nil;
   }
   
   if (self.menuView) {
      [self hideMenu];
   }
   
   if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
      if (self.videoMode == NO) {
         [self performSelector:@selector(enterVideoMode) withObject:self afterDelay:0.2];
      }
   } else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
      if (self.videoMode == YES) {
         [self performSelector:@selector(enterPhotoMode) withObject:self afterDelay:0.2];
      }
   } else {
      NSLog(@"Ambiguous swipe...");
   }
}

- (void)handlePinchFrom:(UIPinchGestureRecognizer *)pinchRecognizer {
   NSLog(@"Blocked zoom gesture.");
}

- (void)enterVideoMode {
   NSLog(@"Switching into video mode...");
   self.isSwitchingModes = YES;
   float transitionDuration = 0.25;
   
   //Slide labels to the side
   [UIView animateWithDuration:transitionDuration animations:^{
      self.mediaTypeViewProgrammatic.frame = CGRectApplyAffineTransform(self.mediaTypeViewProgrammatic.frame, CGAffineTransformMakeTranslation(58, 0));
   }];
   
   //Replace icon for shutter button
   [UIView transitionWithView:self.shutterButton duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      [self.shutterButton setImage:[UIImage imageNamed:@"Shutter_button(start_video)"] forState:UIControlStateNormal];
   } completion:^(BOOL finished) {
      
      //Note: This is where I am handling all changes that need to happen after the [transitionDuration] transition
      //      They could be handled in any of these blocks, but I'm grouping them here
      [self.cameraOverlayView addGestureRecognizer:self.zoomBlocker];
      self.isSwitchingModes = NO;
   }];
   
   //Replace icon for flash mode (if necessary)
   if (self.photoFlashModeRef != self.videoFlashModeRef) {
      [UIView transitionWithView:self.flashButton duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
         [self.flashButton setImage:[self imageForFlashMode:self.videoFlashModeRef] forState:UIControlStateNormal];
      } completion:^(BOOL finished) {}];
   }
   
   //Highlight the selected label
   [UIView transitionWithView:self.videoLabel duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.videoLabel.textColor = [UIColor colorWithRed:0.99 green:0.81 blue:0.14 alpha:1.0];
   } completion:^(BOOL finished) {}];
   
   //Un-highlight the starting label
   [UIView transitionWithView:self.photoLabel duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.photoLabel.textColor = [UIColor whiteColor];
   } completion:^(BOOL finished) {}];
   
   //Actually switch our UIImagePickerController over to the new media type
   self.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
   
   //In case view was shifted for widescreen device, re-center for video recording
   [UIView animateWithDuration:0.5
                         delay:transitionDuration
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{self.cameraViewTransform = CGAffineTransformIdentity;}
                    completion:^(BOOL finished) {}];
   
   //Without delaying this setter, the flash will not activate reliably
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      self.cameraFlashMode = self.videoFlashModeRef;
   });
   
   self.videoMode = YES;

}

- (void)enterPhotoMode {
   NSLog(@"Switching into photo mode...");
   self.isSwitchingModes = YES;
   float transitionDuration = 0.25;
   
   //Slide labels to the side
   [UIView animateWithDuration:transitionDuration animations:^{
      self.mediaTypeViewProgrammatic.frame = CGRectApplyAffineTransform(self.mediaTypeViewProgrammatic.frame, CGAffineTransformMakeTranslation(-58, 0));
   }];

   //Replace icon for shutter button
   [UIView transitionWithView:self.shutterButton duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      [self.shutterButton setImage:[UIImage imageNamed:@"Shutter_button"] forState:UIControlStateNormal];
   } completion:^(BOOL finished) {
      
      //Note: This is where I am handling all changes that need to happen after the 0.5 transition
      //      They could be handled in any of these blocks, but I'm grouping them here
      [self.cameraOverlayView removeGestureRecognizer:self.zoomBlocker];
      self.isSwitchingModes = NO;
      self.cameraFlashMode = self.photoFlashModeRef;
   }];
   
   //Replace icon for flash mode (if necessary)
   if (self.photoFlashModeRef != self.videoFlashModeRef) {
      [UIView transitionWithView:self.flashButton duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
         [self.flashButton setImage:[self imageForFlashMode:self.photoFlashModeRef] forState:UIControlStateNormal];
      } completion:^(BOOL finished) {}];
   }
   
   //Un-highlight the starting label
   [UIView transitionWithView:self.videoLabel duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.videoLabel.textColor = [UIColor whiteColor];
   } completion:^(BOOL finished) {}];

   //Highlight the selected label
   [UIView transitionWithView:self.photoLabel duration:transitionDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
      self.photoLabel.textColor = [UIColor colorWithRed:0.99 green:0.81 blue:0.14 alpha:1.0];
   } completion:^(BOOL finished) {}];
   
   //Actually switch our UIImagePickerController over to the new media type
   self.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
   
   //If using widescreen device, shift view in photo mode to accommodate screen dimensions
   if (isWidescreen()) {
      [UIView animateWithDuration:0.5
                            delay:transitionDuration
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{self.cameraViewTransform = CGAffineTransformMakeTranslation(0, 40);}
                       completion:^(BOOL finished) {}];
   }
   
   self.videoMode = NO;
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return self.albumNames.count + 2; // two extra cells: "Default" and "Add new..."
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   //By Emil's request, include Camera Roll in list in alphabetical order
   NSArray *unsortedAlbums = [[self.albumNames allObjects] arrayByAddingObject:@"Camera Roll"];
   NSArray *sortedAlbums = [unsortedAlbums sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
   
   UIColor *highlightedColor = [UIColor colorWithRed:1.0 green:0.9 blue:0.6 alpha:1.0];
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"albumCell"];
   if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"albumCell"];
      
      UILabel *cellSelectedIcon = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 10, kMENUCELLHEIGHT)];
      cellSelectedIcon.text = @"•";
      cellSelectedIcon.textColor = highlightedColor;
      cellSelectedIcon.tag = 111;
      
      [cell.contentView addSubview:cellSelectedIcon];
   }
   
   cell.backgroundColor = [UIColor clearColor];
   cell.textLabel.textColor = [UIColor whiteColor];
   cell.textLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:15];
   cell.accessoryType = UITableViewCellAccessoryNone;
   
   UILabel *cellSelectedIcon = (UILabel *)[cell viewWithTag:111];
   cellSelectedIcon.hidden = YES;
   
   //Necessary for iOS 8 compatibility
   if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
      [cell setSeparatorInset:UIEdgeInsetsZero];
   }
   if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
      [cell setLayoutMargins:UIEdgeInsetsZero];
   }
   
   if (indexPath.row == 0) {
      cell.textLabel.text = @"Add new";
      cell.textLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   }
   
   else {
      cell.textLabel.text = sortedAlbums[indexPath.row-1];//[NSString stringWithFormat:@"• %@",sortedAlbums[indexPath.row]];
      
      // Highlight the pholder currently selected
      if ([cell.textLabel.text isEqualToString:self.currentAlbum] ||
          ([cell.textLabel.text isEqualToString:@"Camera Roll"] && [self.currentAlbum isEqualToString:kDefaultAlbum])) {
         cell.textLabel.textColor = highlightedColor;
         cellSelectedIcon.hidden = NO;
      }
   }
   
   return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   return kMENUCELLHEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   if (indexPath.row == 0) { //selected "Add new..."
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Pholder" message:@"Enter a name for your new pholder:" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: @"Cancel", nil];
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert textFieldAtIndex:0].delegate = self;
      [alert show];
   }
   else {
      self.currentAlbum = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
      if ([self.currentAlbum isEqualToString:@"Camera Roll"]) self.currentAlbum = kDefaultAlbum;
   }

   [self hideMenu];
}


#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
   
   NSString *enteredText = [[alertView textFieldAtIndex:0] text];

   if (buttonIndex == 0 && enteredText.length > 0 && ![BLACK_LIST containsObject:enteredText]) {
      //TODO: consider displaying warning message when name from black list is entered
      
      self.currentAlbum = enteredText;
      [self.albumNames addObject:self.currentAlbum];
      [self setAlbumNameWithFade: self.currentAlbum];

   } else NSLog(@"Canceled.");
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
   NSCharacterSet *unsafeCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/"]; //add characters here as needed
   NSRange detectionRange = [string rangeOfCharacterFromSet:unsafeCharacters];
   return (detectionRange.location == NSNotFound);
}

#pragma mark - Timer methods

- (void)startTimer {
   self.videoTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateTimeLabel) userInfo:nil repeats:YES];
   self.timeCount = 0.0;
}

- (void)stopTimer {
   [self.videoTimer invalidate];
   self.videoTimer = nil;
   [self.videoTimerLabel setText:@"00:00:00"];
   self.videoRecordingLight.alpha = 0.0f;
}

- (void)updateTimeLabel {
   //Flash light twice per second
   if ((int)self.timeCount == self.timeCount) {
      self.videoRecordingLight.alpha = 1.0f;
   } else {
      self.videoRecordingLight.alpha = 0.0f;
   }
   
   self.timeCount += 0.5;
   [self.videoTimerLabel setText:[NSString stringWithFormat:@"00:%02i:%02i",(int)(self.timeCount)/60,(int)(self.timeCount)%60]];
}


#pragma mark - Helper methods

- (void)reloadAlbumData {
   [self.oldAlbumData removeAllObjects];
   [self.thumbnailForAlbum removeAllObjects];
   [self.albumNames removeAllObjects];
   
   //It is possible that there are cached albums which we want in our list and which do not exist anywhere else, thus...
   NSArray *cachedPholders = [PODataManager getListOfPholders];
   for (NSString *pholder in cachedPholders) {
      if ([BLACK_LIST containsObject:pholder] == NO) { //i.e. this pholder does not require special handling
         [self.albumNames addObject:pholder.unsafe];
      }
   }
   NSLog(@"Finished loading cached album data");
   
   //Asynchronously retrieve information about previously exported albums
   __block POAssetsLibrary *library = [[POAssetsLibrary alloc] init];
   [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
      
      if (group) {
         NSMutableArray *urlsForAlbum = [[NSMutableArray alloc] init];
         NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
         
         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
         [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            if (alAsset) {

               // Save thumbnail for top image in album
               if (self.thumbnailForAlbum[albumName] == nil) {
                  self.thumbnailForAlbum[albumName] = (__bridge id)(alAsset.thumbnail);
               }
               
               ALAssetRepresentation *representation = [alAsset defaultRepresentation];
               [urlsForAlbum addObject:representation.url];
               representation = nil;
               
            } else {
               [self.oldAlbumData setObject:urlsForAlbum forKey:albumName];
            }
         }];
      } else {
         library = nil;
         NSLog(@"Finished loading saved album data");
         
         // Add old album data to album names set
         for (NSString *name in self.oldAlbumData.allKeys) {
            if ([BLACK_LIST containsObject:name] == NO) { //i.e. this pholder does not require special handling
               [self.albumNames addObject:name.unsafe];
            }
         }
         
         // Reset current album if no longer in album list
         if (self.currentAlbum.length > 0 && [self.albumNames containsObject:self.currentAlbum] == NO) {
            NSLog(@"Resetting current album after deletion of %@", self.currentAlbum);
            self.currentAlbum = kDefaultAlbum;
            [self setAlbumNameWithFade:kDefaultAlbum];
         }
      }
   } failureBlock: ^(NSError *error) {
      NSLog(@"No groups: %@",error);
   }];
}


- (void)setAlbumNameWithFade: (NSString *)text {
   CATransition *animation = [CATransition animation];
   animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
   animation.type = kCATransitionFade;
   animation.duration = 0.1;
   [self.albumButton.titleLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
   
   
   NSString *newTitle;
   if ([text isEqualToString:kDefaultAlbum]) {
      newTitle = @"Pholder: Camera Roll";
   }
   
   else if ([text isEqualToString:kSelectAlbum]) {
      newTitle = @"Select pholder for next photo: ";
   }
   
   else {
      
      int maxLength = 20;
      if (text.length > maxLength) {
         newTitle = [NSString stringWithFormat:@"Pholder: \"%@...\"",[text substringToIndex:maxLength-3]];
      }
      else {
         newTitle = [NSString stringWithFormat:@"Pholder: \"%@\"", text];
      }
   }
   
   [self.albumButton setTitle:newTitle forState:UIControlStateNormal];
}

- (void)pickerIsNowBusy:(BOOL)busy {
   if (busy) {
      self.shutterButton.enabled = NO;
   } else {
      self.shutterButton.enabled = YES;
   }
}


@end
