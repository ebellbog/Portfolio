//
//  PODataManager.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/5/14.
//
//

/* This class is essentially a library. It has no data members.
 Handles all reading and writing within our internal file system for the app.
 */

#import <Foundation/Foundation.h>
#import "POAssetsLibrary.h"

#import "POPhotoData.h"

extern NSString * const POCachingNotification;
extern NSString * const MAIN_DATA;
extern NSString * const THUMBS_DATA;

@interface PODataManager : NSObject

+ (NSArray *)getListOfPholders;
+ (NSArray *)getListOfFilesInPholder:(NSString *)pholderName;
+ (NSArray *)getRecursiveListOfPhotos;

+ (void)addPhotoWithFileName:(NSString *)fileName toPholder:(NSString *)pholderName;
+ (void)addPhotoWithAsset:(ALAsset *)asset toPholders:(NSArray *)pholderNames;

+ (void)cachePhoto:(POPhotoData *)photoData withFileName:(NSString *)fileName;
+ (POPhotoData *)retrieveCachedPhotoWithFileName:(NSString *)fileName;
+ (POPhotoData *)retrieveCachedThumbnailWithFileName:(NSString *)fileName;
+ (POPhotoData *)retrieveNewestPhotoInPholder:(NSString *)pholderName;

+ (void)removeCachedPhotoWithFileName:(NSString *)fileName fromPholder:(NSString *)pholderName;
+ (void)removeCachedPhotoFromAllPholders:(NSString *)fileName;
+ (void)deleteDataForCachedPhoto:(NSString *)fileName;
//+ (void)deleteAllCachedPhotos;

+ (NSDictionary *)getCountsOfCachedFilesPerPholder;
+ (void)deleteUnusedPholders;

+ (NSArray*)getPholdersContainingFileName:(NSString *)fileName;
+ (NSArray *)getPholdersFromAsset:(ALAsset *)asset;

+ (BOOL)getFavoriteStatusFromFileName:(NSString *)fileName;
+ (BOOL)getFavoriteStatusFromAsset:(ALAsset *)asset;

+ (POPhotoData *)photoDataFromAsset:(ALAsset *)asset;

@end