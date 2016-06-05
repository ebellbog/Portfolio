//
//  POAssetsLibrary.h
//  PhotoOrganize
//
//  Adapted by Elana Bogdan on 12/15/14.
//  (original credit to Marin Todorov, 10/26/11)
//

#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^SaveImageCompletion)(NSError* error);

@interface POAssetsLibrary : ALAssetsLibrary

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

-(void)saveImage:(UIImage *)image
    withMetadata:(NSDictionary *)metadata
     andFavorite:(BOOL)isFavorite
         toAlbum:(NSString *)albumName
withCompletionBlock:(SaveImageCompletion)completionBlock;

-(void)saveImage:(UIImage *)image
    withMetadata:(NSDictionary *)metadata
        toAlbums:(NSArray *)albumNames
withCompletionBlock:(SaveImageCompletion)completionBlock;

-(void)saveVideo:(NSURL *)videoUrl toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

// has some iOS 8 bugs
-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

// compatible with iOS 8; efficient for adding to multiple albums
-(void)addAssetURL:(NSURL*)assetURL toAlbums:(NSArray *)albumNames withCompletionBlock:(SaveImageCompletion)completionBlock;


@end
