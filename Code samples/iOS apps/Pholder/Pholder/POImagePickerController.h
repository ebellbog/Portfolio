//
//  POImagePickerController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/16/14.
//
//

#import <UIKit/UIKit.h>
#import "POPhotoReviewController.h"
#import "POScrollController.h"
#import "POLibraryRootController.h"
#import "POFocusingReticle.h"

@interface POImagePickerController : UIImagePickerController <POPhotoReviewControllerDelegate, UITableViewDelegate, UITableViewDataSource, POPhotoReviewControllerDelegate, UIAlertViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate, POLibraryRootControllerDelegate, UIGestureRecognizerDelegate>

//necessary to maintain our own flash state due to iOS 7 bug
@property (nonatomic) UIImagePickerControllerCameraFlashMode photoFlashModeRef;
@property (nonatomic) UIImagePickerControllerCameraFlashMode videoFlashModeRef;

@property (nonatomic) BOOL isDisplayingSettings;
@property (nonatomic) BOOL videoMode;

@property (nonatomic) NSString *currentAlbum;
@property (atomic) NSMutableSet *albumNames;
@property (atomic) NSMutableDictionary *oldAlbumData;
@property (atomic) NSMutableDictionary *thumbnailForAlbum;

@property (nonatomic) POFocusingReticle *currentReticle;

- (void)pickerIsNowBusy:(BOOL)busy;
- (void)presentReviewController:(POPhotoReviewController *)reviewController;
- (void)reloadAlbumData;

- (void)libraryDidFinish;

- (void)setAlbumNameWithFade: (NSString *)text;

@end
