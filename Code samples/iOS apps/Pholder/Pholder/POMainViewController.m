//
//  POMainViewController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/11/14.
//
//

#import "UIImage+Resize.h"
#import "NSMutableDictionary+ImageMetadata.h"

#import "POMainViewController.h"
#import "POPhotoData.h"

#import "PODataManager.h"
#import "POAssetsLibrary.h"

#import "POCommonMethods.h"

#import <MobileCoreServices/MobileCoreServices.h>


@implementation POMainViewController

- (void)viewDidLoad
{
   _isCachingPhotos = NO;
   
   _imagePicker = [[POImagePickerController alloc] init];
   self.imagePicker.delegate = self;
   
   _unsavedPhotos = [[NSMutableArray alloc] init];
   
   //Note that the location manager will start and stop updates in accordance with when the ImagePickerController is visible
   _locationManager = [[CLLocationManager alloc] init];
   self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
   self.locationManager.delegate = self;
   
   // New request process required for iOS 8 compatibility
   if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
      NSLog(@"Requesting location authorization in iOS 8...");
      [self.locationManager requestWhenInUseAuthorization];
   }
   
   [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
   [self.locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated {
   if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
   {
      //some sort of alert to user that they do not appear to have a camera, and thus that we question
      //the question of them trying to use our camera app...
   }
   else {
      [self presentViewController:self.imagePicker animated:NO completion:nil];
   }
   [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
   NSLog(@"Received memory warning");
   // Consider disabling shutter button temporarily
   
   [super didReceiveMemoryWarning];
}



- (void)dealloc {
   self.imagePicker = nil;
   self.unsavedPhotos = nil;
   self.locationManager = nil;
}

- (BOOL)prefersStatusBarHidden {
   return YES;
}


#pragma mark - Data handling methods

- (void)cacheReviewedPhotoInBackground {
   [self.unsavedPhotos addObject:self.reviewedPhoto];
   self.reviewedPhoto = nil;

   if (self.isCachingPhotos == NO) {
      [self cacheUnsavedPhotosInBackground];
   } else {
      NSLog(@"Added reviewed photo to ongoing caching process");
   }
}

- (void)cacheUnsavedPhotos {
   [self cacheHelperAtCount:0];
}

- (void)cacheHelperAtCount:(int)count {
   if (self.unsavedPhotos.count > 0 && self.shouldStopCaching == NO) {
      NSLog(@"Unsaved photos remaining: %i", (int)self.unsavedPhotos.count);
      [PODataManager cachePhoto:self.unsavedPhotos[0] withFileName:makeTimedFileName()];
      [self.unsavedPhotos removeObjectAtIndex:0];
      [self cacheHelperAtCount:count+1];
   } else {
      NSLog(@"Cached %i photo(s)", count);
   }
}

- (void)cacheUnsavedPhotosInBackground {
   NSLog(@"Starting new cache batch...");
   self.isCachingPhotos = YES;
   
   //This block allows the caching process to continue running in the background
   __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"CacheFromRAM" expirationHandler:^{
      
      NSLog(@"Failed to cache %i photos in RAM", (int)self.unsavedPhotos.count);
      
      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
      bgTask = UIBackgroundTaskInvalid;
   }];
   
   //Start process running on background thread
   dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [self cacheUnsavedPhotos];
      self.isCachingPhotos = NO; //Apparently this is safe, because atomic? Must happen here, not on main queue.
      dispatch_async( dispatch_get_main_queue(), ^{
         [[UIApplication sharedApplication] endBackgroundTask:bgTask];
         bgTask = UIBackgroundTaskInvalid;
      });
   });
}

//This function aggregates counts for cached photos with counts currently in RAM
- (NSDictionary *)getCountsOfAllPhotosByPholder {
   NSMutableDictionary *totalCounts = [NSMutableDictionary dictionaryWithDictionary:
                                       [PODataManager getCountsOfCachedFilesPerPholder]];
   
   int newFavorites = 0, newTotal = 0;
   
   for (POPhotoData *photo in self.unsavedPhotos) {
      NSNumber *count = totalCounts[photo.album.safe];
      if (count) {
         totalCounts[photo.album.safe] = [NSNumber numberWithInt:[count intValue]+1];
      } else {
         totalCounts[photo.album.safe] = @1;
      }
      
      if (photo.isFavorite) newFavorites++;
      newTotal++;
   }
   
   
   if (newTotal > 0) {
      if (totalCounts[MAIN_DATA] != nil) {
         newTotal += [totalCounts[MAIN_DATA] intValue];
      }
      totalCounts[MAIN_DATA] = [NSNumber numberWithInt:newTotal];
   }
   
   if (newFavorites > 0) {
      if (totalCounts[@"Favorites"] != nil) {
         newFavorites += [totalCounts[@"Favorites"] intValue];
      }
      totalCounts[@"Favorites"] = [NSNumber numberWithInt:newFavorites];
   }

   return totalCounts;
}


#pragma mark - CLLocationManager delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
   // We only really need one update per photo, so stop updating after initial location data arrives
   NSLog(@"Location updated");
   [self.locationManager stopUpdatingLocation];
}

#pragma mark - ImagePicker delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
   
   // If the captured media is a video...
   // (currently, we save the video immediately, rather than caching it and waiting for app to exit)
   if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie]) {
         
         NSURL *videoURL = info[UIImagePickerControllerMediaURL];
         NSString *pathToVideo = [videoURL path];
         BOOL okToSaveVideo = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToVideo);
         
         if (okToSaveVideo) {
            NSLog(@"Saving video...");
            POAssetsLibrary *library = [[POAssetsLibrary alloc] init];
            [library saveVideo:videoURL toAlbum:self.imagePicker.currentAlbum withCompletionBlock:^(NSError *error) {
               if (error) {
                  NSLog(@"Error adding video to pholder: %@", [error description]);
               } else {
                  NSLog(@"Successfully added video to \"%@\"", self.imagePicker.currentAlbum);
               }
            }];
         } else {
            NSLog(@"Video cannot be saved to Camera Roll");
         }
         
         return;
   }
   
   // If the captured media is a photo...
   NSLog(@"Successfully captured photo");
   
   UIImage *photo = info[UIImagePickerControllerOriginalImage];
   NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:[info objectForKey:UIImagePickerControllerMediaMetadata]];
   
   //[metadata setKeywords:@[self.imagePicker.currentAlbum]]; --> this now happens in app delegate, at export time
   [metadata setLocation:self.locationManager.location];
   NSLog(@"Location: %@", self.locationManager.location);
   
   POPhotoData *newPhoto = [[POPhotoData alloc] initWithPhoto:photo
                                                  andMetadata:metadata];
   
   newPhoto.album = self.imagePicker.currentAlbum; // Photo may end up in more albums, but this will be the first place it gets added

   if (self.doReviewPhotos == NO) {
      [self.unsavedPhotos addObject:newPhoto];
      if (self.isCachingPhotos == NO) {           // Only spawn one working thread for this;
         [self cacheUnsavedPhotosInBackground];   // photos wait in (array) queue until thread is ready for them
      } else {
         NSLog(@"Added photo to ongoing batch process");
      }
      [(POImagePickerController *)picker pickerIsNowBusy:NO];
   }
   
   else {
      //We don't want photo to "get eaten up" by an ongoing caching process, so we do not store it in unsavedPhotos
      self.reviewedPhoto = newPhoto;
      
      //Providing the full resolution image is faster... TODO: determine whether this ever causes app to crash; right now it's passing all its stress tests
      [(POImagePickerController *)picker pickerIsNowBusy:NO];
      [self displayPhotoReviewControllerWithPhoto:newPhoto.photo];
      
      //Here is the lower memory alternative:
/*      dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         
         //Scale image down to avoid memory pressure
         CGSize doubleSize = CGSizeApplyAffineTransform(self.view.bounds.size, CGAffineTransformMakeScale(2, 2));
         UIImage *reducedImage = [newPhoto.photo resizedImageToFitInSize:doubleSize scaleIfSmaller:YES];
         
         //Optionally, compress the image as well
//         NSData *jpegData = UIImageJPEGRepresentation(photo, 0.6);
//         UIImage *reducedImage = [UIImage imageWithData:jpegData];
         
         dispatch_async( dispatch_get_main_queue(), ^{
            [(POImagePickerController *)picker pickerIsNowBusy:NO];
            [self displayPhotoReviewControllerWithPhoto:newPhoto.photo];
         });
      });*/
      
   }
}


- (void)displayPhotoReviewControllerWithPhoto:(UIImage *)reducedPhoto {
   POPhotoReviewController *reviewController = [[POPhotoReviewController alloc] initWithPhoto:reducedPhoto];
   
   reviewController.delegate = self.imagePicker;
   reviewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
   
   [self.imagePicker presentReviewController:reviewController];
   //[self.imagePicker performSelector:@selector(presentReviewController:) withObject:reviewController afterDelay:0.2]; //allows camera shutter sound (and any animations) time to finish
}

- (void)deleteLastPhoto {
   self.reviewedPhoto = nil;
}

- (void)favoriteLastPhoto {
   self.reviewedPhoto.isFavorite = YES;
}


@end
