//
//  NSString+SafeURL.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/2/14.
//
//

#import "NSString+SafeURL.h"

@implementation NSString (SafeURL)

- (NSString *)safe {
   NSString *safeString;
   if (self.length > 0) {
      safeString = [self stringByReplacingOccurrencesOfString:@" " withString:@"_"];
   } else {
      safeString = @"Default";
   }
   return safeString;
}

- (NSString *)unsafe {
   return [self stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

@end
