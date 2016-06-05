//
//  NSString+SafeURL.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/2/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (SafeURL)

- (NSString *)safe;
- (NSString *)unsafe;

@end
