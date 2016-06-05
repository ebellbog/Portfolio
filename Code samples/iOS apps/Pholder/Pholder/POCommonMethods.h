//
//  POCommonMethods2.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/4/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
   kSectionNew,
   kSectionEditable,
   kSectionOld
} SectionType;

CGRect orientationIndependentScreenBounds();
BOOL isWidescreen();
NSString *makeTimedFileName();