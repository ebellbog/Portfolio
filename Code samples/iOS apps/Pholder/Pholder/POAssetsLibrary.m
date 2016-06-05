//
//  POAssetsLibrary.m
//  PhotoOrganize
//
//  Adapted by Elana Bogdan on 12/15/14.
//  (original credit to Marin Todorov, 10/26/11)
//

#import "POAssetsLibrary.h"

typedef void(^AddAssetsGroupBlock)(ALAssetsGroup *);
typedef void(^EnumerateBlock)(ALAssetsGroup *group, BOOL *stop);

@interface POAssetsLibrary()
@property (atomic) __block NSMutableArray *remainingAlbums;
@property (atomic) BOOL readyToProceed;
@end


@implementation POAssetsLibrary

- (id)init {
   if (self = [super init]) {
      _remainingAlbums = [[NSMutableArray alloc] init];
      _readyToProceed = NO;
   }
   return self;
}

- (void)dealloc {
   self.remainingAlbums = nil;
}


- (void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
   //write the image data to the assets library (camera roll)
   [self writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
      
      //error handling
      if (error!=nil || albumName.length == 0) { //If no album name (i.e. saved only to camera roll), do not continue
         completionBlock(error);
         return;
      }
      
      //add the asset to the custom photo album
      
      [self addAssetURL: assetURL
                toAlbum:albumName
    withCompletionBlock:completionBlock];
      
   }];
}


//deprecated method
- (void)saveImage:(UIImage *)image
     withMetadata:(NSDictionary *)metadata
      andFavorite:(BOOL)isFavorite
          toAlbum:(NSString *)albumName
withCompletionBlock:(SaveImageCompletion)completionBlock {
   
   //write the image data to the assets library (camera roll)
   [self writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
      
      //error handling
      if (error!=nil) {
         completionBlock(error);
         return;
      }
      
      //add asset to Favorites album when needed; this does not duplicate file data
      if (isFavorite) {
         if (albumName.length > 0) {
            __weak POAssetsLibrary *weakSelf = self;
            [self addAssetURL: assetURL
                      toAlbum: @"Pholder Favorites"
          withCompletionBlock:^void(NSError *error){ //Completion block to save to pholder
             [weakSelf addAssetURL:assetURL
                           toAlbum:albumName
               withCompletionBlock:completionBlock];
          }];
         } else {
            [self addAssetURL: assetURL
                      toAlbum: @"Pholder Favorites"
          withCompletionBlock:completionBlock]; //No completion block if no pholder specified
         }
      }
      
      else if (albumName.length > 0) {
         [self addAssetURL:assetURL
                   toAlbum:albumName
       withCompletionBlock:completionBlock];
      }
      
      else { //unless no album name (i.e. saved only to camera roll)
         completionBlock(nil);
      }
      
   }];
}

- (void)saveImage:(UIImage *)image
     withMetadata:(NSDictionary *)metadata
         toAlbums:(NSArray *)albumNames
withCompletionBlock:(SaveImageCompletion)completionBlock {
   
   //write the image data to the assets library (camera roll)
   [self writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
      
      //error handling
      if (error!=nil || albumNames.count == 0) { //If no album name (i.e. saved only to camera roll), do not continue
         completionBlock(error);
         return;
      }
      
      //add the asset to the custom photo album
      [self addAssetURL: assetURL
               toAlbums:albumNames
    withCompletionBlock:completionBlock];
   }];
}


-(void)saveVideo:(NSURL *)videoUrl toAlbum:(NSString*)albumName withCompletionBlock:  (SaveImageCompletion)completionBlock
{
   //write the video data to the assets library (camera roll)
   //TODO: add metadata???
   [self writeVideoAtPathToSavedPhotosAlbum:videoUrl completionBlock:^(NSURL* assetURL, NSError* error) {
      
      //error handling
      if (error!=nil) {
         completionBlock(error);
         return;
      }
      
      //add the asset to the custom album
      [self addAssetURL: assetURL
                toAlbum:albumName
    withCompletionBlock:completionBlock];
      
   }];
}


// note: this method will present some issues for iOS 8; do not use it
-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock
{
   NSLog(@"Adding asset for album named: %@", albumName);
   __block BOOL albumWasFound = NO;
   
   //search all photo albums in the library
   [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                       usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                          
                          //compare the names of the albums
                          if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                             
                             //target album is found
                             albumWasFound = YES;
                             
                             //get a hold of the photo's asset instance
                             [self assetForURL: assetURL
                                   resultBlock:^(ALAsset *asset) {
                                      
                                      //add photo to the target album
                                      [group addAsset: asset];
                                      
                                      //run the completion block
                                      completionBlock(nil);
                                      
                                   } failureBlock: completionBlock];
                             
                             //album was found, bail out of the method
                             return;
                          }
                          
                          if (group==nil && albumWasFound==NO) {
                             //photo albums are over, target album does not exist, thus create it
                             __weak POAssetsLibrary *weakSelf = self;
                             
                             //create new assets album
                             [self addAssetsGroupAlbumWithName:albumName
                                                   resultBlock:^(ALAssetsGroup *group) {
                                                      NSLog(@"Group: %@", group);
                                                      
                                                      //get the photo's instance
                                                      [weakSelf assetForURL: assetURL
                                                                resultBlock:^(ALAsset *asset) {
                                                                   
                                                                   //add photo to the newly created album
                                                                   [group addAsset: asset];
                                                                   
                                                                   //call the completion block
                                                                   completionBlock(nil);
                                                                   
                                                                } failureBlock: completionBlock];
                                                      
                                                   } failureBlock: completionBlock];
                             
                             //should be the last iteration anyway, but just in case
                             return;
                          }
                          
                       } failureBlock: completionBlock];
   
}


-(void)addAssetURL:(NSURL*)assetURL toAlbums:(NSArray *)albumNames withCompletionBlock:(SaveImageCompletion)completionBlock {
   self.readyToProceed = YES;
   
   [self.remainingAlbums removeAllObjects];
   [self.remainingAlbums addObjectsFromArray:albumNames];
   
   NSInteger favoriteIndex = [self.remainingAlbums indexOfObject:@"Favorites"];
   if (favoriteIndex != NSNotFound) {
      [self.remainingAlbums removeObjectAtIndex:favoriteIndex]; // iOS 8 has its own Favorites album; this avoids confusion
      [self.remainingAlbums addObject:@"Pholder Favorites"];
   }
   
   //search all photo albums in the library
   [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                       usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                          
                          //determine whether this group is in our list
                          NSInteger index = [self.remainingAlbums indexOfObject:[group valueForProperty:ALAssetsGroupPropertyName]];
                          if (index != NSNotFound) { //if so...
                             NSLog(@"Found external album: %@", self.remainingAlbums[index]);
                             
                             //remove album from our to-do list
                             [self.remainingAlbums removeObjectAtIndex:index];
                             
                             //get a hold of the photo's asset instance
                             [self assetForURL: assetURL
                                   resultBlock:^(ALAsset *asset) {
                                      
                                      //add photo to the target album
                                      [group addAsset: asset];
                                      NSLog(@"Added photo to group");
                                      
                                      
                                      //run completion block if finished
                                      if (self.remainingAlbums.count == 0 && self.readyToProceed) {
                                         NSLog(@"Running completion block from top half");
                                         completionBlock(nil); //nil = no error
                                      }
                                      
                                   } failureBlock: completionBlock];
                             
                             //if completely done, bail out of the method
                             if (self.remainingAlbums.count == 0) return;
                          }
                          
                          if (group==nil && self.remainingAlbums.count > 0) {
                             self.readyToProceed = NO;
                             
                             //we've finished checking existing albums, we couldn't find everything we needed, so we'll create some new ones
                             
                             NSLog(@"Could not find the following external albums: %@", self.remainingAlbums);
                             
                             
                             Class PHPhotoLibrary_class = NSClassFromString(@"PHPhotoLibrary");
                             
                             if (PHPhotoLibrary_class) {
                                
                                // -------------------------------- <MESSY iOS 8 STUFF> --------------------------------
                                // (many credits to Adam Freeman's help at http://stackoverflow.com/questions/26003211/assetslibrary-framework-broken-on-ios-8 )
                                
                                NSLog(@"Proceeding using Photos framework in iOS 8...");
                                
                                /**
                                 *
                                 iOS 8..x. . code that has to be called dynamically at runtime and will not link on iOS 7.x.x ...
                                 
                                 [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                 [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
                                 } completionHandler:^(BOOL success, NSError *error) {
                                 if (!success) {
                                 NSLog(@"Error creating album: %@", error);
                                 }
                                 }];
                                 */
                                
                                // dynamic runtime code for code chunk listed above
                                id sharedPhotoLibrary = [PHPhotoLibrary_class performSelector:NSSelectorFromString(@"sharedPhotoLibrary")];
                                
                                SEL performChanges = NSSelectorFromString(@"performChanges:completionHandler:");
                                
                                NSMethodSignature *methodSig = [sharedPhotoLibrary methodSignatureForSelector:performChanges];
                                
                                __block NSInvocation* inv = [NSInvocation invocationWithMethodSignature:methodSig];
                                [inv setTarget:sharedPhotoLibrary];
                                [inv setSelector:performChanges];
                                
                                __weak __block void (^weakBlock)();
                                __weak POAssetsLibrary* weakSelf = self;
                                
                                void (^mainBlock)() = ^void() {
                                   NSLog(@"In main block");
                                   
                                   __block NSString *albumName = [self.remainingAlbums firstObject];
                                   [self.remainingAlbums removeObjectAtIndex:0];
                                   
                                   void (^strongBlock)() = weakBlock;
                                   
                                   void(^firstBlock)() = ^void() { //i.e. the performChanges block
                                      NSLog(@"In first block");
                                      Class PHAssetCollectionChangeRequest_class = NSClassFromString(@"PHAssetCollectionChangeRequest");
                                      SEL creationRequestForAssetCollectionWithTitle = NSSelectorFromString(@"creationRequestForAssetCollectionWithTitle:");
                                      [PHAssetCollectionChangeRequest_class performSelector:creationRequestForAssetCollectionWithTitle withObject:albumName];
                                      
                                   };
                                   
                                   void (^secondBlock)(BOOL success, NSError *error) = ^void(BOOL success, NSError *error) { //i.e. the completionHandler block
                                      NSLog(@"In second block");
                                      if (success) {
                                         //get a reference to the newly created asset group
                                         [weakSelf enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *newGroup, BOOL *stop) {
                                            NSLog(@"Enumerating...");
                                            if (newGroup) {
                                               NSString *name = [newGroup valueForProperty:ALAssetsGroupPropertyName];
                                               if ([albumName isEqualToString:name]) {

                                                  NSLog(@"Used photos framework to create external album: %@", albumName);
                                                  
                                                  [weakSelf assetForURL: assetURL
                                                            resultBlock:^(ALAsset *asset) {
                                                               
                                                               //add photo to the newly created album
                                                               [newGroup addAsset: asset];
                                                               NSLog(@"Added photo to %@", albumName);
                                                               
                                                               if (weakSelf.remainingAlbums.count == 0) {
                                                                  NSLog(@"Finished adding photo to albums");
                                                                  NSLog(@"Running completion block from lower half");
                                                                  completionBlock(nil); // i.e. no error
                                                               }
                                                               else {
                                                                  strongBlock(); //recurse!
                                                               }
                                                            } failureBlock:completionBlock]; //failure to obtain asset for URL
                                                  *stop = YES; //found our group; no need to continue enumerating
                                               }
                                            } else if (*stop == NO){
                                               NSLog(@"Reached end of groups and could not find album"); //This would be a very bizarre error to encounter...
                                            }
                                         } failureBlock:^(NSError *error) { //failure to enumerate
                                            completionBlock(error);
                                         }];
                                      }
                                      
                                      if (error) {
                                         NSLog(@"Error creating album: %@", error); //failure to create asset group
                                         completionBlock(error);
                                      }
                                   };
                                   
                                   // Set the success and failure blocks.
                                   [inv setArgument:&firstBlock atIndex:2];
                                   [inv setArgument:&secondBlock atIndex:3];
                                   
                                   [inv invoke];
                                };
                                
                                weakBlock = mainBlock;

                                mainBlock();
                              
                                // -------------------------------- </MESSY iOS 8 STUFF> --------------------------------
                             }
                             else {   
                                // code that always creates an album on iOS 7.x.x but fails
                                // in certain situations such as if album has been deleted
                                // previously on iOS 8...x.
                                
                                __weak POAssetsLibrary* weakSelf = self;
                                __weak __block AddAssetsGroupBlock weakAdd;
                                
                                AddAssetsGroupBlock mainAdd = ^void(ALAssetsGroup *newGroup) {
                                   __block NSString *albumName = [newGroup valueForProperty:ALAssetsGroupPropertyName];
                                   
                                   NSLog(@"Created external album: %@", newGroup);
                                   
                                   AddAssetsGroupBlock strongAdd = weakAdd;
                                   
                                   //get the photo's instance
                                   [weakSelf assetForURL: assetURL
                                             resultBlock:^(ALAsset *asset) {
                                                
                                                //add photo to the newly created album
                                                [newGroup addAsset: asset];
                                                NSLog(@"Added photo to %@", albumName);
                                                
                                                if (weakSelf.remainingAlbums.count == 0) {
                                                   NSLog(@"Finished adding photo to albums");
                                                   NSLog(@"Running completion block from lower half");
                                                   completionBlock(nil); // i.e. no error
                                                }
                                                else {
                                                   NSString *nextAlbumName = [self.remainingAlbums firstObject];
                                                   [self.remainingAlbums removeObjectAtIndex:0];
                                                   
                                                   [weakSelf addAssetsGroupAlbumWithName:nextAlbumName
                                                                             resultBlock:strongAdd
                                                                            failureBlock:completionBlock];
                                                }
                                             }failureBlock:completionBlock];
                                };
                                
                                weakAdd = mainAdd;
                                
                                NSString *albumName = [self.remainingAlbums firstObject];
                                [self.remainingAlbums removeObjectAtIndex:0];
                                
                                [self addAssetsGroupAlbumWithName:albumName
                                                      resultBlock:mainAdd
                                                     failureBlock:completionBlock];
                             }
                             return;
                          }
                       } failureBlock:completionBlock];
}

@end
