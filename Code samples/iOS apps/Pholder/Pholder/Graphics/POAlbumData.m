//
//  POAlbumData.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 11/1/14.
//

#import "POAlbumData.h"

@interface POAlbumData ()

@property (nonatomic) NSMutableArray *photos;

@end


@implementation POAlbumData

- (id)init {
   self = [super init];
   if (self) {
      _photos = [[NSMutableArray alloc] init];
   }
   return self;
}

- (id)initWithAlbumName:(NSString *)name {
   self = [self init];
   if (self) {
      _name = name;
   }
   return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
   _name = [aDecoder decodeObjectForKey:@"name"];
   _photos = [aDecoder decodeObjectForKey:@"photos"];
   return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
   [aCoder encodeObject:_name forKey:@"name"];
   [aCoder encodeObject:_photos forKey:@"photos"];
}


- (int)getSize {
   return self.photos.count;
}


- (void)dealloc {
   self.photos = nil;
   self.name = nil;
}


@end
