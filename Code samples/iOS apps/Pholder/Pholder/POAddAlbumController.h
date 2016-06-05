//
//  POAddAlbumController.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/18/14.
//
//

#import <UIKit/UIKit.h>

@protocol POAddAlbumControllerDelegate
- (void)controllerFinishedWithAdditions:(NSArray *)additions andDeletions:(NSArray *)deletions;
@end


@interface POAddAlbumController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL allowsDeletion;
@property (nonatomic, weak) id <POAddAlbumControllerDelegate> delegate;

- (id)initWithAlbumNames:(NSArray *)names andMemberships:(NSArray *)memberships;

@end
