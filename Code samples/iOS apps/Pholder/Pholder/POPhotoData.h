//
//  POPhotoData.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/19/14.
//
//

#import <Foundation/Foundation.h>
#import "NSString+SafeURL.h"

@interface POPhotoData : NSObject <NSCoding>

@property (nonatomic) UIImage *photo;
@property (nonatomic) NSMutableDictionary *metadata;
@property (nonatomic) NSString *album; //For now, indicates primary (first) album; may become deprecated
@property (nonatomic) BOOL isFavorite;
@property (nonatomic, readonly) POPhotoData *thumbnail;

- (id)initWithPhoto:(UIImage *)photo andMetadata:(NSMutableDictionary *)metadata;
- (void)addToAlbum:(NSString *)albumName;
- (void)removeFromAlbum:(NSString *)albumName;

@end