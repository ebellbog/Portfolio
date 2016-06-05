//
//  POAppDelegate.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/11/14.
//
//

#import <UIKit/UIKit.h>

@interface POAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (atomic) BOOL isWritingData;
@property (atomic) BOOL shouldStopWritingData;
@property (nonatomic) BOOL doExport;

@end
