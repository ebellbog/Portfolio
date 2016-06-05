//
//  POCommonMethods.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/4/14.
//
//

#import "POCommonMethods.h"

//Necessary for compatibility with iOS 8
CGRect orientationIndependentScreenBounds() {
   CGRect screenBounds = [UIScreen mainScreen].bounds;
   return CGRectMake(0, 0, MIN(screenBounds.size.width, screenBounds.size.height),
                     MAX(screenBounds.size.width, screenBounds.size.height));
}

//Note: iPhone 6 & iPhone 5 both have a 16:9 aspect ratio; iPhone 4 (and earlier) is 3:2
BOOL isWidescreen() {
   CGRect screenBounds = orientationIndependentScreenBounds();
   CGSize screenSize = screenBounds.size;
   float aspectRatio = screenSize.height/screenSize.width;
   
   BOOL isWidescreen = (aspectRatio > 1.5);
   //NSLog(@"This device is in the %@ family.", isWidescreen ? @"iPhone 6/iPhone 5" : @"iPhone 4");
   return isWidescreen;
}

NSString* makeTimedFileName() {
   //Alternately, this tends to work well enough: [[NSUUID UUID] UUIDString]]
   
   double timestamp = [[NSDate date] timeIntervalSince1970];
   int usefulTime = (int)((timestamp/1000000-(int)(timestamp/1000000))*10000000);
   
   NSString *fileName = [NSString stringWithFormat:@"%07d", usefulTime];
   return fileName;
}
