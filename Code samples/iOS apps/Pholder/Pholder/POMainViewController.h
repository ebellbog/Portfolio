//
//  POMainViewController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/11/14.
//
//

#import <CoreLocation/CoreLocation.h>
#import "POPhotoReviewController.h"
#import "POImagePickerController.h"
#import "POPhotoData.h"

@interface POMainViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) POImagePickerController *imagePicker;

@property (nonatomic) BOOL doReviewPhotos;

@property (atomic) BOOL isCachingPhotos;
@property (atomic) BOOL shouldStopCaching;
@property (atomic) NSMutableArray *unsavedPhotos;
@property (atomic) POPhotoData *reviewedPhoto;

-(void)deleteLastPhoto;
-(void)favoriteLastPhoto;
-(void)cacheReviewedPhotoInBackground;

- (NSDictionary *)getCountsOfAllPhotosByPholder; //all = cached + still in RAM

@end
