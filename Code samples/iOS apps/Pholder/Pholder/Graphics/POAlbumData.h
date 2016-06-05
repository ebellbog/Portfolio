//
//  POAlbumData.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 11/1/14.
//
// This NSCoding-compliant class will facilitate membership in multiple albums by
// storing lists of file paths to member photos rather than actual photo data

#import <Foundation/Foundation.h>

@interface POAlbumData : NSObject <NSCoding>

@property (nonatomic) NSString *name;
@property (readonly) int size;

- (id)initWithAlbumName:(NSString *)name;

- (NSString *)getPhotoAtIndex:(int)index;
- (NSArray *)getAllPhotos;

- (void)removePhotoAtIndex:(int)index;
- (void)toggleFavoriteForPhotoAtIndex:(int)index;

- (void)addPhotoWithFilePath:(int)path;

@end
