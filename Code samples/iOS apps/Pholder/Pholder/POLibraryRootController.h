//
//  POLibraryViewController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/29/14.
//
//

#import <UIKit/UIKit.h>

@protocol POLibraryRootControllerDelegate
-(void)libraryDidFinish;
@end


@interface POLibraryRootController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id <POLibraryRootControllerDelegate> delegate;
@property (nonatomic) NSDictionary *photoCounts;
@property (nonatomic) NSArray *pholderNames;

@end
