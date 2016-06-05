//
//  POPhotoData.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/19/14.
//
//

#import "POPhotoData.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIImage+Resize.h"

@interface POPhotoData ()
@property (nonatomic) BOOL touched; //tracks whether data needs to be written back to memory
@end

@implementation POPhotoData

- (id)initWithPhoto:(UIImage *)photo andMetadata:(NSMutableDictionary *)metadata {
   if (self = [super init]) {
      _photo = photo;
      _metadata = metadata;
      _isFavorite = NO;
      
      _touched = NO;
   }
   return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
   _photo = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"photo"]];
   _metadata = [aDecoder decodeObjectForKey:@"metadata"];
   _album = [aDecoder decodeObjectForKey:@"album"];
   _isFavorite = [aDecoder decodeBoolForKey:@"favorite"];
   
   _touched = NO;
   
   return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
   [aCoder encodeObject:UIImageJPEGRepresentation(self.photo, 1.0) forKey:@"photo"];
   [aCoder encodeObject:_metadata forKey:@"metadata"];
   [aCoder encodeObject:_album forKey:@"album"];
   [aCoder encodeBool:_isFavorite forKey:@"favorite"];
}

- (void)setIsFavorite:(BOOL)isFavorite {
   _isFavorite = isFavorite;
   
   if (isFavorite == YES) {
      [self addToAlbum:@"Favorites"];
   } else {
      [self removeFromAlbum:@"Favorites"];
   }
}


- (void)addToAlbum:(NSString *)albumName {
   NSMutableArray *keywords = [NSMutableArray arrayWithArray:self.metadata.getKeywords];
   
   if ([keywords containsObject:albumName] == NO) {
      [keywords addObject:albumName];
      NSLog(@"Added \"%@\" to keywords.", albumName);
      
      [self.metadata setKeywords:keywords];
      self.touched = YES;
   }
}

- (void)removeFromAlbum:(NSString *)albumName {
   NSMutableArray *keywords = [NSMutableArray arrayWithArray:self.metadata.getKeywords];
   
   NSInteger index = [keywords indexOfObject:albumName];
   if (index != NSNotFound) {
      [keywords removeObjectAtIndex:index];
      NSLog(@"Removed \"%@\" from keywords.", albumName);
      
      [self.metadata setKeywords:keywords];
      self.touched = YES;
   }
}

- (POPhotoData *)thumbnail {
   CGSize thumbnailSize = CGSizeMake(200, 200);
   UIImage *reducedImage = [self.photo resizedImageToFitInSize:thumbnailSize scaleIfSmaller:YES];

   POPhotoData *thumbnail = [[POPhotoData alloc] initWithPhoto:reducedImage andMetadata:nil];
   return thumbnail;
}


- (void)dealloc {
   self.photo = nil;
   self.metadata = nil;
   self.album = nil;
}

@end
