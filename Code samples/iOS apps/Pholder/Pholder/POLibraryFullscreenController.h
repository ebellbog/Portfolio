//
//  POLibraryFullscreenControllerViewController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/10/14.
//
//

#import "POLibraryGridController.h"
#import "POCommonMethods.h"
#import "POAddAlbumController.h"

@interface POLibraryFullscreenController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate, POAddAlbumControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) POLibraryGridController *parentController;

- (id)initWithType:(SectionType)type atIndexPath:(NSIndexPath *)indexPath;

@end