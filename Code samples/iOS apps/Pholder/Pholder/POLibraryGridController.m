//
//  POLibraryCollectionController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/3/14.
//
//


#import "PODataManager.h"
#import "POPhotoData.h"

#import "POLibraryNavigationController.h"

#import "POLibraryGridController.h"
#import "POLibraryGridCell.h"

#import "POReusableHeaderViewWithTitle.h"

#import "POLibraryFullscreenController.h"
#import "POCommonMethods.h"

#import "POAssetsLibrary.h"

@interface POLibraryGridController ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UILabel *noPhotosLabel;

@property (nonatomic) UICollectionViewFlowLayout *gridLayout;

@property (nonatomic) BOOL justLoaded;

@property (nonatomic) NSArray *albumData;
@property (nonatomic) POAssetsLibrary *library;

@property (atomic) NSMutableDictionary *favoritesCache;

@end


@implementation POLibraryGridController


- (NSUInteger)supportedInterfaceOrientations
{
   return UIInterfaceOrientationMaskPortrait;
}

- (id)initWithAlbumName:(NSString *)albumName albumData:(NSArray *)albumData andSize:(int)size
{
    self = [super init];
    if (self) {
       _albumName = albumName;
       _albumSize = size;
       _albumData = albumData;
       _fileNames = nil;
       
       _loadedPhotoData = [[NSMutableDictionary alloc] init];
       _loadedOldPhotoData = [[NSMutableArray alloc] init];
       _loadedOldEditableData = [[NSMutableArray alloc] init];
       
       _favoritesCache = [[NSMutableDictionary alloc] init];

       _library = [[POAssetsLibrary alloc] init];
       _justLoaded = YES;
       _displaySavedPhotos = YES; //this property is pretty much deprecated by this point
       _shouldScrollToTop = NO;
       
       _gridLayout = [[UICollectionViewFlowLayout alloc] init];
       self.gridLayout.sectionInset = UIEdgeInsetsMake(0, 0, 20, 0);
       
       self.navigationItem.title = [NSString stringWithFormat:@"\"%@\"", self.albumName];
       
       [self loadCachedPhotos];
       if (self.albumData.count > 0) [self loadSavedPhotos];
    }
    return self;
}


- (void)viewDidLoad
{
   [super viewDidLoad];
   
   if (self.albumSize == 0 && (self.displaySavedPhotos == NO || self.albumData.count == 0)) {
      self.noPhotosLabel.hidden = NO;
   } else {
      self.noPhotosLabel.hidden = YES;
   }
   
   [self.collectionView registerClass:[POLibraryGridCell class] forCellWithReuseIdentifier:@"PhotoCell"];
   [self.collectionView registerClass:[POReusableHeaderViewWithTitle class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"titledHeader"];
   
   self.collectionView.backgroundColor = [UIColor whiteColor];
   self.collectionView.alwaysBounceVertical = YES;

   float cellSize = ([UIScreen mainScreen].bounds.size.width/4)-1.5;
   self.gridLayout.itemSize = CGSizeMake(cellSize, cellSize);
   self.gridLayout.minimumInteritemSpacing = 0.0;
   self.gridLayout.minimumLineSpacing = 2.0;
   self.gridLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
   
   self.collectionView.collectionViewLayout = self.gridLayout;
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAllCached) name:POCachingNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
   [(POLibraryNavigationController *)self.navigationController setSupportsLandscape:NO];
   //In theory, should force this view into portrait mode;
   //see: http://stackoverflow.com/questions/12630359/ios-6-how-do-i-restrict-some-views-to-portrait-and-allow-others-to-rotate
   
   if (self.justLoaded == NO) {
      if (self.albumSize == 0 && (self.displaySavedPhotos == NO || self.albumData.count == 0)) {
         self.noPhotosLabel.hidden = NO;
      } else {
         self.noPhotosLabel.hidden = YES;
      }
      
      [self refreshFavoritesCache];
      [self.collectionView reloadData]; //Useful for updating favorite badges after returning from fullscreen view
   }
   
   [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
   if (self.justLoaded == YES) {
      self.justLoaded = NO;
   }
   else if (self.albumSize + self.albumData.count == 0) {
      [self.navigationController popViewControllerAnimated:YES];
   }
   
   if (self.shouldScrollToTop) {
      [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
      self.shouldScrollToTop = NO;
   }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // TODO: unload loadedData?
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self name:POCachingNotification object:nil];
   
   self.fileNames = nil;
   self.loadedPhotoData = nil;
   self.loadedOldPhotoData = nil;
   self.loadedOldEditableData = nil;
   self.library = nil;
   self.gridLayout = nil;
}


#pragma mark - Data handling methods

- (void)refreshFavoritesCache {
   int sectionIndex = 0;
   BOOL isFavorite;
   
   if (self.fileNames.count > 0) {
      for (int i = 0; i < self.fileNames.count; i++) {
         isFavorite = [PODataManager getFavoriteStatusFromFileName:self.fileNames[i]];
         [self.favoritesCache setObject:[NSNumber numberWithBool:isFavorite] forKey:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
      }
      sectionIndex++;
   }
   if (self.loadedOldEditableData.count > 0) {
      for (int i = 0; i < self.loadedOldEditableData.count; i++) {
         isFavorite = [PODataManager getFavoriteStatusFromAsset:self.loadedOldEditableData[i]];
         [self.favoritesCache setObject:[NSNumber numberWithBool:isFavorite] forKey:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
      }
      sectionIndex++;
   }
   if (self.loadedOldPhotoData.count > 0) {
      for (int i = 0; i < self.loadedOldPhotoData.count; i++) {
         isFavorite = [PODataManager getFavoriteStatusFromAsset:self.loadedOldPhotoData[i]];
         [self.favoritesCache setObject:[NSNumber numberWithBool:isFavorite] forKey:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
      }
   }
   
   NSLog(@"Finished refreshing Favorites cache");
}


- (void)loadCachedPhotos {
   NSLog(@"Refreshing collection view...");
   self.fileNames = [NSMutableArray arrayWithArray:[PODataManager getListOfFilesInPholder:self.albumName.safe]];
   NSLog(@"File names: %@", self.fileNames);
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      for (NSString *fileName in self.fileNames) {
         if (self.loadedPhotoData[fileName] == nil) {
            self.loadedPhotoData[fileName] = [PODataManager retrieveCachedPhotoWithFileName:fileName];
            dispatch_sync(dispatch_get_main_queue(), ^{
               [self.collectionView reloadData];
            });
         }
      }
      [self refreshFavoritesCache];
      dispatch_sync(dispatch_get_main_queue(), ^{
         [self.collectionView reloadData];
      });
   });
   
}


- (void)loadSavedPhotos {
   [self.loadedOldPhotoData removeAllObjects];
   for (NSURL *savedPhotoURL in self.albumData) {
      [self.library assetForURL:savedPhotoURL resultBlock:^(ALAsset *asset) {
         if (asset) {
            if (asset.isEditable) {
               [self.loadedOldEditableData addObject:asset];
            } else {
               [self.loadedOldPhotoData addObject:asset];
            }
            
            if (self.loadedOldPhotoData.count + self.loadedOldEditableData.count == self.albumData.count) { // i.e. we're finished loading
               self.displaySavedPhotos = YES;
               self.noPhotosLabel.hidden = YES;
               
               [self refreshFavoritesCache];
               
               [self.collectionView reloadData];
               NSLog(@"Finished loading saved photos from album data");
            }
         }
      } failureBlock:^(NSError *error) {
         NSLog(@"Unable to load saved photo: %@", [error description]);
      }];
   }
}

- (void)reloadAllCached {
   [self loadCachedPhotos];
   [self refreshFavoritesCache];
}



#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   SectionType currentType = [self typeForSectionAtIndex:indexPath.section];

   POLibraryFullscreenController *fullScreenController = [[POLibraryFullscreenController alloc] initWithType:currentType
                                                                                                 atIndexPath:indexPath];
   fullScreenController.parentController = self;
   
   [self.navigationController pushViewController:fullScreenController animated:YES];
}


#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
   NSMutableArray *itemCounts = [[NSMutableArray alloc] initWithCapacity:3];
   if (self.albumSize > 0) [itemCounts addObject:[NSNumber numberWithLong:self.loadedPhotoData.allKeys.count]];
   if (self.loadedOldEditableData.count > 0) [itemCounts addObject:[NSNumber numberWithLong:self.loadedOldEditableData.count]];
   if (self.loadedOldPhotoData.count > 0) [itemCounts addObject:[NSNumber numberWithLong:self.loadedOldPhotoData.count]];
   
   NSNumber *items = [itemCounts objectAtIndex:section];
   if (items) {
      return [items integerValue];
   }
   else return 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
   if (self.displaySavedPhotos == YES) {
      return (self.albumSize > 0)+(self.loadedOldPhotoData.count > 0)+(self.loadedOldEditableData.count > 0);
   }
   else return (self.albumSize > 0);
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {   
   POLibraryGridCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
   
   SectionType currentType = [self typeForSectionAtIndex:indexPath.section];
   
   if (currentType == kSectionNew) {
      NSArray *sortedKeys = [[self.loadedPhotoData allKeys] sortedArrayUsingSelector:@selector(compare:)];
      POPhotoData *photoData = self.loadedPhotoData[sortedKeys[indexPath.row]];
      cell.imageView.image = photoData.photo;
      
   } else if (currentType == kSectionEditable) {
      ALAsset *asset = [self.loadedOldEditableData objectAtIndex:[indexPath item]];
      cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
      
   } else if (currentType == kSectionOld) {
      ALAsset *asset = [self.loadedOldPhotoData objectAtIndex:[indexPath item]];
      cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
   }
   
   NSNumber *isFavorite = [self.favoritesCache objectForKey:indexPath];
   if (isFavorite) {
      cell.isFavorite = isFavorite.boolValue;
   } else {
      cell.isFavorite = NO;
   }

   return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
   return CGSizeMake(orientationIndependentScreenBounds().size.width, 35);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
   
   POReusableHeaderViewWithTitle *headerView = nil;
   
   if(kind == UICollectionElementKindSectionHeader) {
      headerView= [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"titledHeader" forIndexPath:indexPath];
   
      SectionType currentType = [self typeForSectionAtIndex:indexPath.section];
      
      if (currentType == kSectionNew) {
         [headerView setTitle:[NSString stringWithFormat:@"New photos (%i):", self.albumSize]];
      } else if (currentType == kSectionEditable) {
         [headerView setTitle:[NSString stringWithFormat:@"Photos saved by Pholder (%lu):", self.loadedOldEditableData.count]];
      } else if (currentType == kSectionOld) {
         [headerView setTitle:[NSString stringWithFormat:@"Photos not managed by Pholder (%lu):", self.loadedOldPhotoData.count]];
      }
      
      headerView.type = currentType;
   }

   return headerView;
}

#pragma mark - Helper methods

- (SectionType)typeForSectionAtIndex:(long)index {
   NSMutableArray *sectionKeys = [[NSMutableArray alloc] initWithCapacity:3];
   if (self.albumSize > 0) [sectionKeys addObject:@"NewPhotos"];
   if (self.loadedOldEditableData.count > 0) [sectionKeys addObject:@"EditablePhotos"];
   if (self.loadedOldPhotoData.count > 0) [sectionKeys addObject:@"OldPhotos"];
   
   SectionType returnType;
   NSString *sectionKey = [sectionKeys objectAtIndex:index];
   
   if ([sectionKey isEqualToString:@"NewPhotos"]) {
      returnType = kSectionNew;
      
   } else if ([sectionKey isEqualToString:@"EditablePhotos"]) {
      returnType = kSectionEditable;
      
   } else if ([sectionKey isEqualToString:@"OldPhotos"]) {
      returnType = kSectionOld;
   }

   return returnType;
}

@end
