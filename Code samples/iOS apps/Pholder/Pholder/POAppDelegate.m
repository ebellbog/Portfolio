//
//  POAppDelegate.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/11/14.
//
//

#import "POAppDelegate.h"
#import "POMainViewController.h"
#import "PODataManager.h"
#import "POPhotoData.h"
#import "POAssetsLibrary.h"
#import "NSMutableDictionary+ImageMetadata.h"

typedef void(^SavePhotoBlock)(NSError *);

@implementation POAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   _isWritingData = NO;
   _shouldStopWritingData = NO;
   return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
   // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   
   POMainViewController *mainController = (POMainViewController *)self.window.rootViewController;
   POImagePickerController *imagePicker = mainController.imagePicker;
   
   
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   [defaults setObject:imagePicker.currentAlbum forKey:@"currentAlbum"];
   [defaults synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   if (self.doExport == NO) { //Any caching process will continue, but app will not write to camera roll
      [PODataManager deleteUnusedPholders];
      NSLog(@"Exiting without exporting");
      return;
   }
   
   if (self.isWritingData) {
      NSLog(@"Warning: app is already writing data in background process");
     
      self.shouldStopWritingData = NO;
      //This deals with a corner case, in which the app is opened and exited immediately (while background saving is in progress).
      //The issue was that saving would be stopped but not started again.
      
      return; //We do not want to launch this process multiple times concurrently!
   }
   
   self.isWritingData = YES;
   
   POMainViewController *mainController = (POMainViewController *)self.window.rootViewController;
   
   //We want to stop any ongoing caching, since it is faster just to send data directly from RAM to camera roll at this point -> cool idea, but it might also be safer to let the caching finish, since other apps can cause RAM to be lost
   if (mainController.isCachingPhotos) {
      mainController.shouldStopCaching = YES;
      NSLog(@"Waiting for caching process to tidy up...");
      
      while (mainController.isCachingPhotos) {}; //Spin while waiting for current cache to finish
      
      mainController.shouldStopCaching = NO;
      NSLog(@"Caching successfully terminated.");
   }
   
   NSMutableArray *unsavedPhotosInRAM = mainController.unsavedPhotos;
   //Note: contains actual POPhotoData objects
   
   NSMutableArray *unsavedPhotosInCache = [NSMutableArray arrayWithArray:[PODataManager getListOfFilesInPholder:MAIN_DATA]];
   //List of file names; no actual photo data
   
   NSLog(@"Unsaved photos in RAM = %i", (int)unsavedPhotosInRAM.count);
   NSLog(@"Unsaved photos in cache = %i", (int)unsavedPhotosInCache.count);
   
   if (unsavedPhotosInCache.count + unsavedPhotosInRAM.count == 0) {
      [PODataManager deleteUnusedPholders];
      self.isWritingData = NO;
      NSLog(@"Done.");
      return;
   }
   
   //Sort file names to ensure that photos get saved in the order they were taken
   [unsavedPhotosInCache sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
   
//   [unsavedPhotosInCache sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//      return [[(NSArray *)obj1 objectAtIndex:0] compare:[(NSArray *)obj2 objectAtIndex:0]];
//   }];
   
   __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithName:@"SaveFromCacheAndRAM" expirationHandler:^{
      NSLog(@"Failed to save %i photos in RAM", (int)unsavedPhotosInRAM.count);
      NSLog(@"Failed to save %i photos that were cached", (int)unsavedPhotosInCache.count);
      
      [application endBackgroundTask:bgTask];
      bgTask = UIBackgroundTaskInvalid;
      self.isWritingData = NO;
   }];
   
   
   // Start the long-running task and return immediately.
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      
      POAssetsLibrary *tmpLibrary = [[POAssetsLibrary alloc] init];
      
      __weak __block SavePhotoBlock weakSave;
      
      SavePhotoBlock mainSave = ^void(NSError *error) {
         if (error) {
            NSLog(@"Encountered error: %@", [error description]);
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
         }
         
         else {
            // Delete cached data here, after saving is complete, to be more robust in case of a crash
            // (note that, if the last photo saved was saved from RAM, this condition will not get
            // triggered, since the cache gets exhausted first)
            if (unsavedPhotosInCache.count > 0) {
               NSString *fileName = unsavedPhotosInCache[0];
               [PODataManager deleteDataForCachedPhoto:fileName];
               [unsavedPhotosInCache removeObjectAtIndex:0];
            }
            
            NSLog(@"Successfully saved photo!");
            NSLog(@"%i photo(s) remaining in RAM", (int)unsavedPhotosInRAM.count);
            NSLog(@"%i photo(s) remainining in cache", (int)unsavedPhotosInCache.count);
            
            
            if (self.shouldStopWritingData == YES) {
               NSLog(@"Background saves interrupted by app re-entering foreground");
               self.isWritingData = NO;
               self.shouldStopWritingData = NO;
               [application endBackgroundTask:bgTask];
               bgTask = UIBackgroundTaskInvalid;
            }
            
            else {
            
               POPhotoData *dataToSave = nil;
               NSMutableArray *albums = [[NSMutableArray alloc] init];
               
               if (unsavedPhotosInCache.count > 0) { //Save from cache first to ensure that oldest photos appear earliest
                  NSLog(@"Saving photo from cache...");
                  
                  NSString *fileName = unsavedPhotosInCache[0];
                  [albums addObjectsFromArray:[PODataManager getPholdersContainingFileName:fileName]];
                  
                  dataToSave = [PODataManager retrieveCachedPhotoWithFileName:fileName];
                  
                  // TODO: relocate to preserve data in cases of crash
//                  [PODataManager deleteDataForCachedPhoto:fileName];
//                  [unsavedPhotosInCache removeObjectAtIndex:0];
               }
               else if (unsavedPhotosInRAM.count > 0) {
                  NSLog(@"Saving photo from RAM...");
                  
                  dataToSave = unsavedPhotosInRAM[0];
                  
                  [albums addObject:dataToSave.album];
                  if (dataToSave.isFavorite) {
                     [albums addObject:@"Pholder Favorites"];
                  }
                  
                  [unsavedPhotosInRAM removeObjectAtIndex:0];
               }
               else {
                  NSLog(@"Finished saving.");
                  [PODataManager deleteUnusedPholders]; // Clean up empty pholders at this stage
                  [application endBackgroundTask:bgTask];
                  bgTask = UIBackgroundTaskInvalid;
                  self.isWritingData = NO;
               }
               
               [dataToSave.metadata setKeywords:albums]; // CRUCIAL STEP! This is what makes our desktop assistant work
               
               if (dataToSave) {
                  SavePhotoBlock strongSave = weakSave;
                  [tmpLibrary saveImage:dataToSave.photo
                           withMetadata:dataToSave.metadata
                               toAlbums:albums
                    withCompletionBlock:strongSave];
               }
            }
         }
      };
      
      weakSave = mainSave;
      
      POPhotoData *dataToSave;
      NSMutableArray *albums = [[NSMutableArray alloc] init];

      if (unsavedPhotosInCache.count > 0) {
         NSLog(@"Saving photo from cache...");
         
         NSString *fileName = unsavedPhotosInCache[0];
         [albums addObjectsFromArray:[PODataManager getPholdersContainingFileName:fileName]];
         
         dataToSave = [PODataManager retrieveCachedPhotoWithFileName:fileName];
         
         // TODO: relocate to preserve data in cases of crash
//         [PODataManager deleteDataForCachedPhoto:fileName];
//         [unsavedPhotosInCache removeObjectAtIndex:0];
      }
      else {
         NSLog(@"Saving photo from RAM...");
         
         dataToSave = unsavedPhotosInRAM[0];
         
         [albums addObject:dataToSave.album];
         if (dataToSave.isFavorite) {
            [albums addObject:@"Pholder Favorites"];
         }
         
         [unsavedPhotosInRAM removeObjectAtIndex:0];
      }
      
      [dataToSave.metadata setKeywords:albums]; // CRUCIAL STEP! This is what makes our desktop assistant work
      
      [tmpLibrary saveImage:dataToSave.photo
               withMetadata:dataToSave.metadata
                   toAlbums:albums
        withCompletionBlock:mainSave];
   });
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
   // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   if (self.isWritingData) {
      self.shouldStopWritingData = YES;
   }
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
   //In case any albums have been deleted while app was in background
   [[(POMainViewController *)self.window.rootViewController imagePicker] reloadAlbumData];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   NSLog(@"Well shoot... Goodbye, World!");
}

@end
