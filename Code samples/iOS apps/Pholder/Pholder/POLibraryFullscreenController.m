//
//  POLibraryFullscreenControllerViewController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/10/14.
//
//

#import "POLibraryFullscreenController.h"
#import "POLibraryFullscreenCell.h"
#import "POLibraryNavigationController.h"
#import "POLibraryRootController.h"

#import "PODataManager.h"
#import "POPhotoData.h"

@interface POLibraryFullscreenController ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic) UICollectionViewFlowLayout *fullscreenLayout;

@property (nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@property (nonatomic, weak) IBOutlet UIButton *trashButton;
@property (nonatomic, weak) IBOutlet UIButton *manageButton;


@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) SectionType collectionType;
@property (nonatomic) BOOL didPerformInitialScroll;

@property (nonatomic, weak) IBOutlet UIView *bottomBar;

@end


@implementation POLibraryFullscreenController

- (id)initWithType:(SectionType)type atIndexPath:(NSIndexPath *)indexPath {
   self = [super init];
   if (self) {
      _fullscreenLayout = [[UICollectionViewFlowLayout alloc] init];
      
      self.currentIndex = indexPath.item;
      self.collectionType = type;
      
      _didPerformInitialScroll = NO;
   }
   return self;
}

- (void)viewDidLoad {
   [super viewDidLoad];
   [(POLibraryNavigationController *)self.navigationController setSupportsLandscape:YES];
   
   [self updateTitleWithIndex:self.currentIndex+1];
   [self updateFavoriteIcon];
   
   self.bottomBar.backgroundColor = [UIColor colorWithWhite:.5 alpha:0.5];
   
   [self.collectionView registerClass:[POLibraryFullscreenCell class] forCellWithReuseIdentifier:@"PhotoCell"];
   self.collectionView.backgroundColor = [UIColor whiteColor];
   self.collectionView.pagingEnabled = YES;
   self.collectionView.delegate = self;
   self.collectionView.dataSource = self;
   
   self.fullscreenLayout.minimumInteritemSpacing = 0.0;
   self.fullscreenLayout.minimumLineSpacing = 0.0; //TODO: increase to ~15 to match spacing in Photos app
    
   self.fullscreenLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
   self.fullscreenLayout.sectionInset = UIEdgeInsetsZero;
   
   [self.collectionView setCollectionViewLayout:self.fullscreenLayout animated:NO];
   
   self.trashButton.tag = 1;
   
   if (self.collectionType == kSectionEditable) {
      [self.plusButton setImage:[UIImage imageNamed:@"Plus_button"] forState:UIControlStateNormal];
      [self.trashButton setImage:[UIImage imageNamed:@"Trash_button(disabled)"] forState:UIControlStateNormal];
      self.trashButton.tag = 0;
   }
   
   else if (self.collectionType == kSectionOld) {
      self.plusButton.hidden = YES;
      self.favoriteButton.hidden = YES;
      self.trashButton.hidden = YES;
      
      self.manageButton.hidden = NO;
   }
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFavoriteIcon) name:@"MetadataUpdate" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.collectionView reloadData];
}

- (void)viewDidLayoutSubviews {
   if (self.didPerformInitialScroll == NO) {
      [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                  atScrollPosition:UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally
                                          animated:NO];
      self.didPerformInitialScroll = YES;
   }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
   NSDictionary *infoDict = @{@"orientation" : [NSNumber numberWithInt:toInterfaceOrientation],
                              @"duration" : [NSNumber numberWithFloat:duration]};
   
   [[NSNotificationCenter defaultCenter] postNotificationName:@"rotateScrollView" object:nil userInfo:infoDict];
   NSLog(@"Posted rotation notification");
   
   [self updateCurrentIndex];
   [self.collectionView setAlpha:0.0f];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

   [self.collectionView.collectionViewLayout invalidateLayout];
//   [[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]] setNeedsDisplay];
   
   CGSize currentSize = self.collectionView.bounds.size;
   float offset = self.currentIndex * currentSize.width;
   [self.collectionView setContentOffset:CGPointMake(offset, 0)];
   
   [UIView animateWithDuration:0.125f animations:^{
      [self.collectionView setAlpha:1.0f];
   }];
}


- (void)dealloc {
   self.fullscreenLayout = nil;
   
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Button actions

- (IBAction)deletePhoto:(id)sender {
   if ([(UIView *)sender tag] == 0) {
      NSLog(@"Display alert");
      return;
   }

   NSString *title, *destructiveButtonTitle;
   if ([self.parentController.albumName isEqualToString:MAIN_DATA]) {
      destructiveButtonTitle = @"Delete";
      if ([self photoDataForIndex:self.currentIndex].album.length > 0) {
         title = @"This photo will also be deleted from a pholder.";
      } else {
         title = nil;
      }
   } else {
      destructiveButtonTitle = @"Remove from Pholder";
      title = @"This photo will be removed from this pholder, but will remain in the Camera Roll";
   }
   
   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:destructiveButtonTitle
                                                   otherButtonTitles: nil];
   
   [actionSheet showInView:self.view];
   
 }

- (IBAction)toggleFavorite:(id)sender {
   if ([(UIView *)sender tag] == 0) {
      NSLog(@"Display alert");
      return;
   }

   if (self.collectionType == kSectionNew) {
      NSString *currentFileName = [self fileNameForIndex:self.currentIndex];
      BOOL isFavorite = [PODataManager getFavoriteStatusFromFileName:currentFileName];

      if (isFavorite) {
         [PODataManager removeCachedPhotoWithFileName:currentFileName fromPholder:@"Favorites"];
      } else {
         [PODataManager addPhotoWithFileName:currentFileName toPholder:@"Favorites"];
      }
      
      [self updateFavoriteIcon];
   } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Just a moment"
                                                      message:@"Once you favorite this photo, you will not be able to un-favorite it. Proceed anyway?"
                                                     delegate:self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
      alert.tag = 2222;
      [alert show];
   }
}

- (IBAction)addToAlbums:(id)sender {

   POLibraryRootController *rootController = (POLibraryRootController *)self.navigationController.viewControllers[0];
   NSArray *albumNames = rootController.pholderNames;
   NSArray *albumMemberships;
   
   if (self.collectionType == kSectionNew) {
      albumMemberships = [PODataManager getPholdersContainingFileName:[self fileNameForIndex:self.currentIndex]];
   }
   else if (self.collectionType == kSectionEditable) {
      ALAsset *asset = [self.parentController.loadedOldEditableData objectAtIndex:self.currentIndex];
      albumMemberships = [PODataManager getPholdersFromAsset:asset];
   }
   
   POAddAlbumController *addController = [[POAddAlbumController alloc] initWithAlbumNames:albumNames andMemberships:albumMemberships];
   addController.allowsDeletion = (self.collectionType == kSectionNew);
   addController.delegate = self;
   
   UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addController];
   navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
   
   [self presentViewController:navController animated:YES completion:nil];
}

- (void)controllerFinishedWithAdditions:(NSArray *)additions andDeletions:(NSArray *)deletions {
   NSLog(@"Returned with additions:\n%@\nand deletions:\n%@", additions, deletions);
   [self dismissViewControllerAnimated:YES completion:nil];
   
   if (self.collectionType == kSectionNew) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
         NSString *currentFileName = [self fileNameForIndex:self.currentIndex];
         
         for (NSString *deletion in deletions) {
            if ([deletion isEqual:self.parentController.albumName]) {
               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Just a moment"
                                                               message:@"Are you sure you want to remove this photo from the current pholder?"
                                                              delegate:self
                                                     cancelButtonTitle:@"No"
                                                     otherButtonTitles:@"Yes", nil];
               alert.tag = 1111;
               dispatch_sync(dispatch_get_main_queue(), ^{
                  [alert show];
               });
               
            } else {
               [PODataManager removeCachedPhotoWithFileName:currentFileName fromPholder:deletion];
            }
         }
         
         for (NSString *addition in additions) {
            [PODataManager addPhotoWithFileName:currentFileName toPholder:addition.safe];
         }
      });
   } else {
      ALAsset *asset = [self.parentController.loadedOldEditableData objectAtIndex:self.currentIndex];
      [PODataManager addPhotoWithAsset:asset toPholders:additions];
   }
}


- (IBAction)importPhoto:(id)sender {
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Importing..."
                                                   message:@"Pholder will make a copy of this photo and add it to the \"New photos\" section of your Pholder library. You will then be able to manage it alongside your other Pholder photos."
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"Import photo", nil]; //@"Import album", nil];
   alert.tag = 3333;
   [alert show];
}


#pragma mark - UIAlertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
   if (alertView.tag == 1111) {
      if (buttonIndex == 1) {
         [self actionSheet:nil clickedButtonAtIndex:0]; // which is to say: this is the same as confirming we want to delete
      }
   }
   else if (alertView.tag == 2222) {
      if (buttonIndex == 1) {
         ALAsset *asset = [self.parentController.loadedOldEditableData objectAtIndex:self.currentIndex];
         [PODataManager addPhotoWithAsset:asset toPholders:[NSArray arrayWithObject:@"Pholder Favorites"]];
         [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite_button(filled+disabled)"] forState:UIControlStateNormal];
         self.favoriteButton.tag = 0;
      }
   } else if (alertView.tag == 3333) {
      if (buttonIndex == 1) { // i.e. we want to import the current photo
         [self importCurrentAsset];
      } else if (buttonIndex == 2) { // i.e. we want to import all photos in the current album
         [self importAllAssets];
      }
   }
}

- (void)importCurrentAsset {
   ALAsset *asset = [self.parentController.loadedOldPhotoData objectAtIndex:self.currentIndex];
   POPhotoData *newData = [PODataManager photoDataFromAsset:asset];
   newData.album = self.parentController.albumName;
   
   if ([newData.album isEqualToString:MAIN_DATA]) {
      newData.album = @"";
   }
   
   NSString *fileName = makeTimedFileName();
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      [PODataManager cachePhoto:newData withFileName:fileName];
   });
   
   [self.parentController.fileNames addObject:fileName];
   [self.parentController.loadedPhotoData setObject:newData forKey:fileName];
   self.parentController.albumSize += 1;
   self.parentController.shouldScrollToTop = YES;
   
   [self.navigationController popViewControllerAnimated:YES];

}

- (void)importAllAssets {
   NSLog(@"Importing all assets in pholder...");
   
   NSString *album = self.parentController.albumName;
   if ([album isEqualToString:MAIN_DATA]) {
      album = @"";
   }
   
   NSMutableDictionary *allNewData = [[NSMutableDictionary alloc] initWithCapacity:self.parentController.loadedOldPhotoData.count];
   
   //TODO: display busy indicator (if we use this method)
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      for (ALAsset *asset in self.parentController.loadedOldPhotoData) {
         
         POPhotoData *newData = [PODataManager photoDataFromAsset:asset];
         newData.album = album;
         
         NSString *fileName = makeTimedFileName();
         
         [self.parentController.fileNames addObject:fileName];
         [self.parentController.loadedPhotoData setObject:newData forKey:fileName];
         self.parentController.albumSize += 1;
         
         [allNewData setObject:newData forKey:fileName];
      }
      
      dispatch_sync(dispatch_get_main_queue(), ^{
         self.parentController.shouldScrollToTop = YES;
         [self.navigationController popViewControllerAnimated:YES];
      });
      
      for (NSString *fileName in allNewData.allKeys) {
         [PODataManager cachePhoto:allNewData[fileName] withFileName:fileName];
      }
   });
}


#pragma mark - UIActionSheetDelegate method

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
   if (buttonIndex == 1) return;
   
   NSString *currentFileName = [self fileNameForIndex:self.currentIndex];
   
   //Manage actual data
   if ([self.parentController.albumName isEqualToString:MAIN_DATA]) { // i.e. if deleting from Camera Roll
      [PODataManager deleteDataForCachedPhoto:currentFileName];
      [PODataManager removeCachedPhotoFromAllPholders:currentFileName];
   }
   else {
      [PODataManager removeCachedPhotoWithFileName:currentFileName fromPholder:self.parentController.albumName];
   }
   
   self.parentController.albumSize = self.parentController.albumSize - 1;
   
   //Manage loaded data for UICollectionView
   if (self.parentController.loadedPhotoData.count > 1) { //i.e. there are other photos to which we can scroll
      
      [UIView animateWithDuration:.3
                       animations:^{
                          [self.collectionView setAlpha:0.0f];
                       }
                       completion:^(BOOL finished) {
                          [self.parentController.loadedPhotoData removeObjectForKey:[self fileNameForIndex:self.currentIndex]];
                          [self.collectionView reloadData];
                          
                          // We scroll right (i.e. same index) unless we are already rightmost, in which case we need to decrement
                          if (self.currentIndex >= self.parentController.loadedPhotoData.count) {
                             self.currentIndex--;
                          }
                          
                          [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]
                                                      atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                              animated:NO];
                          
                          [self updateTitleWithIndex:self.currentIndex+1];
                          
                          [UIView animateWithDuration:0.5
                                           animations:^{
                                              [self.collectionView setAlpha:1.0];
                                           }];
                       }];
   }
   else {
      [self.parentController.loadedPhotoData removeObjectForKey:[self fileNameForIndex:self.currentIndex]];
      [self.navigationController popViewControllerAnimated:YES];
   }
}

#pragma mark - UICollectionViewDelegateFlowLayout methods

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
   return self.collectionView.frame.size;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
   [self updateCurrentIndex];
   
   [UIView beginAnimations:@"postScrollUpdates" context:nil];
   [UIView setAnimationDuration:0.5];
   [self updateTitleWithIndex:self.currentIndex+1];
   [self updateFavoriteIcon];
   [UIView commitAnimations];
}

- (void)updateFavoriteIcon {
   NSLog(@"Updating favorite icon...");
   
   BOOL isFavorite;
   self.favoriteButton.tag = 1;
   if (self.collectionType == kSectionNew) {
      NSString *currentFileName = [self fileNameForIndex:self.currentIndex];
      isFavorite = [PODataManager getFavoriteStatusFromFileName:currentFileName];
      if (isFavorite) {
         [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite_button(filled)"] forState:UIControlStateNormal];
      } else {
         [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite_button"] forState:UIControlStateNormal];
      }
   } else if (self.collectionType == kSectionEditable) {
      ALAsset *asset = [self.parentController.loadedOldEditableData objectAtIndex:self.currentIndex];
      isFavorite = [PODataManager getFavoriteStatusFromAsset:asset];
      if (isFavorite) {
         [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite_button(filled+disabled)"] forState:UIControlStateNormal];
         self.favoriteButton.tag = 0;
      } else {
         [self.favoriteButton setImage:[UIImage imageNamed:@"Favorite_button"] forState:UIControlStateNormal];
      }
   }

}

#pragma mark - UICollectionViewDataSource methods


- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
   NSInteger items;
   switch (self.collectionType) {
      case kSectionNew:
         items = self.parentController.loadedPhotoData.count;
         break;
      case kSectionEditable:
         items = self.parentController.loadedOldEditableData.count;
         break;
      case kSectionOld:
         items = self.parentController.loadedOldPhotoData.count;
         break;
         
      default:
         break;
   }
   return items;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
   return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
   POLibraryFullscreenCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
   
   if (self.collectionType == kSectionNew) {
      POPhotoData *photoData = [self photoDataForIndex:indexPath.row];
      [cell setPhoto:photoData.photo];
   }
   else if (self.collectionType == kSectionEditable) {
      ALAsset *asset = [self.parentController.loadedOldEditableData objectAtIndex:[indexPath item]];
      ALAssetRepresentation *rep = [asset defaultRepresentation];
      [cell setPhoto:[UIImage imageWithCGImage:rep.fullResolutionImage
                                         scale:1.0
                                   orientation:(UIImageOrientation)rep.orientation]];
      
   } else if (self.collectionType == kSectionOld) {
      ALAsset *asset = [self.parentController.loadedOldPhotoData objectAtIndex:[indexPath item]];
      ALAssetRepresentation *rep = [asset defaultRepresentation];
      [cell setPhoto:[UIImage imageWithCGImage:rep.fullResolutionImage
                                         scale:1.0
                                   orientation:(UIImageOrientation)rep.orientation]];
   }
   
   return cell;
}


#pragma mark - Helper methods

- (void)updateCurrentIndex {
   CGPoint currentOffset = [self.collectionView contentOffset];
   self.currentIndex = currentOffset.x / self.collectionView.frame.size.width;
}

- (void)updateTitleWithIndex:(NSInteger)index {
   NSInteger outOf = [self collectionView:nil numberOfItemsInSection:0]; // is it kosher to call this method? oh well
   self.navigationItem.title = [NSString stringWithFormat:@"%lu of %lu", index, outOf];
}


- (POPhotoData *)photoDataForIndex:(NSInteger)index {
   NSArray *sortedKeys = [[self.parentController.loadedPhotoData allKeys] sortedArrayUsingSelector:@selector(compare:)];
   return self.parentController.loadedPhotoData[sortedKeys[index]];
}
    
- (NSString *)fileNameForIndex:(NSInteger)index {
   NSArray *sortedKeys = [[self.parentController.loadedPhotoData allKeys] sortedArrayUsingSelector:@selector(compare:)];
   return sortedKeys[index];
}

@end
