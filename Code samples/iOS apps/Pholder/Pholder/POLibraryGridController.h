//
//  POLibraryCollectionController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/3/14.
//
//

#import <UIKit/UIKit.h>

@interface POLibraryGridController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic) int albumSize;
@property (nonatomic) NSString *albumName;
@property (atomic) NSMutableArray *fileNames;
@property (atomic) NSMutableDictionary *loadedPhotoData;
@property (atomic) NSMutableArray *loadedOldPhotoData;
@property (atomic) NSMutableArray *loadedOldEditableData;

@property (atomic) BOOL displaySavedPhotos;
@property (nonatomic) BOOL shouldScrollToTop;

- (id)initWithAlbumName:(NSString *)albumName albumData:(NSArray *)albumData andSize:(int)size;

@end
