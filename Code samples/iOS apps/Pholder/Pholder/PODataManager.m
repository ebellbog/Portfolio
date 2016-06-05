//
//  PODataManager.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/5/14.
//
//

#define BASE_PATH [self applicationDocumentsDirectory]

#import "PODataManager.h"
#import "NSMutableDictionary+ImageMetadata.h"

#define kDefaultAlbum @"DefaultAlbumNameString"

NSString * const POCachingNotification = @"POCachingNotification";
NSString * const MAIN_DATA = @"AllPhotoData";
NSString * const THUMBS_DATA = @"ThumbnailData";

@implementation PODataManager

+ (NSString *)applicationDocumentsDirectory {
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   return [paths firstObject];
}

//Returns all pholders, including "Camera Roll" (i.e. MAIN_DATA) and "Favorites"
+ (NSArray *)getListOfPholders {
   NSError *error = nil;
   NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:BASE_PATH error:&error];
   
   if (error) {
      NSLog(@"Error retrieving pholder names: %@", [error description]);
   }
   
   return contents;
}

+ (NSArray *)getListOfFilesInPholder:(NSString *)pholderName {
   NSString *path = [BASE_PATH stringByAppendingPathComponent:pholderName];

   BOOL exists, isDirectory;
   exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
   if (exists == NO || isDirectory == NO)   {
      NSLog(@"Pholder \"%@\" does not exist.", pholderName);
      return @[];
   }
   
   NSError *error = nil;
   NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
   if (error) {
      NSLog(@"Error retrieving files in pholder: %@", [error description]);
      return @[];
   }
   
   return fileNames;
}


//deprecated function!
+ (NSArray *) getRecursiveListOfPhotos {
   
   NSMutableArray *filePaths = [[NSMutableArray alloc] init];
   
   // Enumerators are recursive
   NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:BASE_PATH];
   
   NSString *filePath;
   for (filePath in enumerator) {
      NSArray *pathElements = [filePath pathComponents];
      if (pathElements.count > 1) { //Which is to say: if we've got a file, not a higher-level directory
         NSString *name = pathElements[1];
         NSString *pholder = pathElements[0];
         [filePaths addObject:@[name, pholder]];
      }
   }
   return filePaths;
}


+ (void)addPhotoWithFileName:(NSString *)fileName toPholder:(NSString *)pholderName {
   BOOL exists, isDirectory;
   NSString *aliasMainPath = [BASE_PATH stringByAppendingPathComponent:pholderName];
   
   exists = [[NSFileManager defaultManager] fileExistsAtPath:aliasMainPath isDirectory:&isDirectory];
   if (exists == NO || isDirectory == NO)
   {
      NSError *error;
      [[NSFileManager defaultManager] createDirectoryAtPath:aliasMainPath withIntermediateDirectories:NO attributes:nil error:&error];
      if (error) {
         NSLog(@"Encountered problem creating directory at path: %@", aliasMainPath);
         NSLog(@"Error: %@", [error description]);
         return;
      }
      NSLog(@"Created new directory at %@", aliasMainPath);
   }
   
   NSString *aliasFilePath = [aliasMainPath stringByAppendingPathComponent:fileName];
   [[NSFileManager defaultManager] createFileAtPath:aliasFilePath contents:nil attributes:nil];
   
   NSLog(@"Saved reference for file \"%@\" to Pholder \"%@\"", fileName, pholderName);
}


// N.B.: This method is composed almost entirely of asynchronous calls; there should never be a need to call it asynchronously
+ (void)addPhotoWithAsset:(ALAsset *)asset toPholders:(NSArray *)pholderNames {
   POAssetsLibrary *library = [[POAssetsLibrary alloc] init];
   
   ALAssetRepresentation *rep = [asset defaultRepresentation];
   
   [library addAssetURL:rep.url toAlbums:pholderNames withCompletionBlock:^(NSError *error) {
      if (error) {
         NSLog(@"Error adding saved photos to new albums: %@", [error description]);
      } else {
         NSLog(@"Successfully added saved photo to the following albums: %@", pholderNames);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"ALAssetsGroupUpdate" object:nil];
      }
   }];
   
   
   // Janky way of getting raw image data
   // (see http://stackoverflow.com/questions/11520209/how-to-update-exif-of-alasset-without-changing-the-image)
   Byte *buffer = (Byte *)malloc(rep.size);
   NSUInteger k = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
   NSData *imageData = [NSData dataWithBytesNoCopy:buffer length:k freeWhenDone:YES];
   
   NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:rep.metadata];
   
   NSMutableArray *fixedPholderNames = [NSMutableArray arrayWithArray:pholderNames];
   NSInteger index = [fixedPholderNames indexOfObject:@"Pholder Favorites"];
   if (index != NSNotFound) {
      [fixedPholderNames replaceObjectAtIndex:index withObject:@"Favorites"];
   }
   [metadata addKeywords:fixedPholderNames];
   
   [asset setImageData:imageData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
      if (error) {
         NSLog(@"Error editing metadata for saved photo: %@", [error description]);
      } else {
         NSLog(@"Successfully overwrote metadata for saved photo"); //TODO: figure out how to overwrite the original data...
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"MetadataUpdate" object:nil];
      }
   }];
   
}



+ (void)cachePhoto:(POPhotoData *)photoData withFileName:(NSString *)fileName {
   /* This function has been rewritten to work with aliases. All original data stored together at top level. */
   BOOL isDirectory, exists;

   NSError *error;
   NSString *mainPath = [BASE_PATH stringByAppendingPathComponent:MAIN_DATA];
   NSString *thumbPath = [BASE_PATH stringByAppendingPathComponent:THUMBS_DATA];
   NSString *filePath = [mainPath stringByAppendingPathComponent:fileName];
   NSString *thumbFilePath = [thumbPath stringByAppendingPathComponent:fileName];
   
   
   for (NSString *path in @[mainPath, thumbPath]) {
      exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
      if (exists == NO || isDirectory == NO) //This should get triggered very infrequently, since every photo gets saved here
      {
         NSError *error;
         [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
         if (error) {
            NSLog(@"Encountered problem creating directory at path: %@", path);
            NSLog(@"Error: %@", [error description]);
            return;
         }
         NSLog(@"Created new directory at %@", path);
      }
   }
   
   
//   NSDate *methodStart = [NSDate date];
   
   POPhotoData *thumbnailData = photoData.thumbnail;
   
//   NSDate *methodFinish = [NSDate date];
//   NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
//   NSLog(@"executionTime = %f", executionTime);


   NSData *data = [NSKeyedArchiver archivedDataWithRootObject:photoData];
   [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
   if (error) {
      NSLog(@"Could not cache photo at path: %@\n%@", filePath, [error description]);
   } else {
      NSLog(@"Cached photo at path: %@", filePath);

      //If cached successfully, then cache thumbnail
      data = [NSKeyedArchiver archivedDataWithRootObject:thumbnailData];
      [data writeToFile:thumbFilePath options:NSDataWritingAtomic error:&error];
      if (error) {
         NSLog(@"Could not cache thumbnail at path: %@\n%@", thumbFilePath, [error description]);
      } else {
         NSLog(@"Cached thumbnail at path: %@", thumbFilePath);
         [[NSNotificationCenter defaultCenter] postNotificationName:POCachingNotification object:nil];
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:POCachingNotification object:nil];
   }
   
   //Now save reference to album(s):
   NSMutableArray *aliasLocations = [[NSMutableArray alloc] init];
   if (photoData.album.length > 0 && ![photoData.album isEqualToString:kDefaultAlbum]) { //TODO: add names of multiple albums in future versions?
      [aliasLocations addObject:photoData.album.safe];
   }
   if (photoData.isFavorite) {
      [aliasLocations addObject:@"Favorites"];
   }
   
   for (NSString *aliasLocation in aliasLocations) {
      [PODataManager addPhotoWithFileName:fileName toPholder:aliasLocation];
   }
};

+ (POPhotoData *)retrieveCachedPhotoWithFileName:(NSString *)fileName {
   NSURL *fileURL = [NSURL fileURLWithPath:[[BASE_PATH stringByAppendingPathComponent:MAIN_DATA] stringByAppendingPathComponent:fileName]];
   NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
   
   if (!fileData) {
      NSLog(@"Error: data does not exist for \"%@\"", fileName);
      return nil;
   }
   
   POPhotoData *cachedPhoto = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
   return cachedPhoto;
}

+ (POPhotoData *)retrieveCachedThumbnailWithFileName:(NSString *)fileName {
   NSURL *fileURL = [NSURL fileURLWithPath:[[BASE_PATH stringByAppendingPathComponent:THUMBS_DATA] stringByAppendingPathComponent:fileName]];
   NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
   
   if (!fileData) {
      NSLog(@"Error: thumbnail data does not exist for \"%@\"", fileName);
      return nil;
   }
   
   POPhotoData *cachedThumbnail = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
   return cachedThumbnail;
}


+ (POPhotoData *)retrieveNewestPhotoInPholder:(NSString *)pholderName {
   NSArray *files = [self getListOfFilesInPholder:pholderName];
   
   if (files.count > 0) {
      NSArray *sortedFiles = [files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
      return [self retrieveCachedPhotoWithFileName:[sortedFiles lastObject]];
   } else {
      return nil;
   }
}


+ (void)removeCachedPhotoWithFileName:(NSString *)fileName fromPholder:(NSString *)pholderName {
   NSURL *fileURL = [NSURL fileURLWithPath:
                     [[BASE_PATH stringByAppendingPathComponent:pholderName.safe]
                      stringByAppendingPathComponent:fileName]];
   
   NSError *error = nil;
   [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
   
   if (error) {
      NSLog(@"Error deleting file: %@", [error description]);
   } else {
      NSLog(@"Removed file %@ from pholder %@", fileName, pholderName);
   }
}


+ (void)removeCachedPhotoFromAllPholders:(NSString *)fileName {
   NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:BASE_PATH];
   
   NSString *filePath;
   for (filePath in enumerator) {
      NSArray *pathElements = [filePath pathComponents];
      if (pathElements.count > 1) { //Which is to say: if we've got a file, not a higher-level directory
         NSString *name = pathElements[1];
         NSString *pholder = pathElements[0];
         
         
         NSArray *essentialData = @[MAIN_DATA, THUMBS_DATA];
         if ([essentialData containsObject:pholder] == NO && [name isEqualToString:fileName]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[BASE_PATH stringByAppendingPathComponent:filePath] error:&error];
            if (error) {
               NSLog(@"Error deleting photo reference at path: %@", filePath);
            }
            else {
               NSLog(@"Removed reference to file \"%@\" from pholder \"%@\"", name, pholder);
            }
         }
         
      }
   }
   
}

+ (void)deleteDataForCachedPhoto:(NSString *)fileName {
   NSString *filePath = [[BASE_PATH stringByAppendingPathComponent:MAIN_DATA] stringByAppendingPathComponent:fileName];
   NSString *thumbPath = [[BASE_PATH stringByAppendingPathComponent:THUMBS_DATA] stringByAppendingPathComponent:fileName];

   NSError *error;
   [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
   
   if (error) {
      NSLog(@"Error deleting data for cached photo %@: %@", fileName, error);
   } else {
      NSLog(@"Deleted data for cached photo: %@", fileName);
      
      // If deletion was successful, delete thumbnail as well
      [[NSFileManager defaultManager] removeItemAtPath:thumbPath error:&error];
      
      if (error) {
         NSLog(@"Error deleting thumbnail data for cached photo %@: %@", fileName, error);
      } else {
         NSLog(@"Deleted thumbnail data for cached photo: %@", fileName);
      }
      
      //Then clean up all remaining traces
      [self removeCachedPhotoFromAllPholders:fileName];
   }
}

// deprecated function!
//+ (void)deleteAllCachedPhotos {
//   NSArray *allFileData = [PODataManager getListOfTempFiles];
//   
//   int count = 0;
//   for (NSArray *fileData in allFileData) {
//      [self deleteCachedPhotoInPholder:fileData[0] withFileName:fileData[1]];
//      NSLog(@"Deleted temp file \"%@\" in pholder \"%@\"", fileData[1], fileData[0]);
//      count++;
//   }
//   
//   NSLog(@"Deleted %i file(s) in total", count);
//}


+ (NSDictionary *)getCountsOfCachedFilesPerPholder {
   NSMutableDictionary *pholderCounts = [[NSMutableDictionary alloc] init];
   
   NSArray *pholderNames = [PODataManager getListOfPholders];
   NSString *pholder;
   for (pholder in pholderNames) {
      NSArray *photos = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[BASE_PATH stringByAppendingPathComponent:pholder] error:nil];
      pholderCounts[pholder] = [NSNumber numberWithInt:(int)photos.count];
   }
   
   return pholderCounts;
}


+ (void)deleteUnusedPholders {
   NSDictionary *pholderCounts = [PODataManager getCountsOfCachedFilesPerPholder];
   NSError *error = nil;
   NSString *pholderKey;
   
   for (pholderKey in pholderCounts.allKeys) {
      if ([(NSNumber *)pholderCounts[pholderKey] intValue] == 0) {
         [[NSFileManager defaultManager] removeItemAtPath:[BASE_PATH stringByAppendingPathComponent:pholderKey]
                                                    error:&error];
         if (error) {
            NSLog(@"Error deleting pholder: %@", [error description]);
         } else {
            NSLog(@"Deleted pholder: %@", pholderKey);
         }
      }
   }
   
   NSLog(@"Finished deleting pholders.");
}


// This function returns the names of all Pholders to which a given file belongs,
// formatted as required for exporting.
+ (NSArray*)getPholdersContainingFileName:(NSString *)fileName {
   NSMutableArray *pholdersToReturn = [[NSMutableArray alloc] init];
   
   NSMutableArray *allPholders = [NSMutableArray arrayWithArray:[self getListOfPholders]];
   
    //not relevant; all photos are here
   [allPholders removeObject:MAIN_DATA];
   [allPholders removeObject:THUMBS_DATA];

   for (NSString *pholder in allPholders) {
      NSArray *filesInPholder = [self getListOfFilesInPholder:pholder];
      if ([filesInPholder containsObject:fileName]) {
         [pholdersToReturn addObject:pholder.unsafe];
      }
   }
   
   NSLog(@"The following Pholders contain file %@:\n%@", fileName, pholdersToReturn);
   return pholdersToReturn;
}


+ (NSArray *)getPholdersFromAsset:(ALAsset *)asset {
   ALAssetRepresentation *rep = [asset defaultRepresentation];
   NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:rep.metadata];
   
   NSMutableArray *albums = [NSMutableArray arrayWithArray:[metadata getKeywords]];
   [albums removeObject:@"Favorites"];
   
   //TODO: if we add a generic "Created in Pholder" tag, that will need to get removed here, too
   
   return albums;
}



+ (BOOL)getFavoriteStatusFromFileName:(NSString *)fileName {
   NSArray *favoritePhotos = [self getListOfFilesInPholder:@"Favorites"];
   return [favoritePhotos containsObject:fileName];
}

+ (BOOL)getFavoriteStatusFromAsset:(ALAsset *)asset {
   ALAssetRepresentation *representation = [asset defaultRepresentation];
   NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:representation.metadata];
   
   NSArray *keywords = [metadata getKeywords];
   return [keywords containsObject:@"Favorites"];
}


+ (POPhotoData *)photoDataFromAsset:(ALAsset *)asset {
   ALAssetRepresentation *rep = [asset defaultRepresentation];
   UIImage *photo = [UIImage imageWithCGImage:rep.fullResolutionImage scale:1.0 orientation:(UIImageOrientation)rep.orientation];
   NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:rep.metadata];
   
   POPhotoData *newData = [[POPhotoData alloc] initWithPhoto:photo andMetadata:metadata];
   return newData;
}

@end
