//
//  BGLWordViewController.h
//  WordNerd
//
//  Created by Elana Bogdan on 12/5/11.
//

#import <UIKit/UIKit.h>

@class BGLMainViewController;

@protocol BGLWordViewControllerDelegate
- (void)controllerFinishedWithoutWord;
- (void)controllerFinishedWithWord:(NSString *)word;
- (void)loadDefinitionView:(NSString *)word;
@end

@interface BGLWordViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    NSMutableArray *displayList;
    NSArray *foundList;
    int sections[12][2];
    IBOutlet UITableView *wordTable;
    IBOutlet UISearchBar *sBar;
    
    BGLMainViewController *parentView;
    BOOL versionBOOL;
}

@property (assign, nonatomic) NSArray *foundList;
@property (retain, nonatomic) NSMutableArray *displayList;
@property (retain, nonatomic) IBOutlet UITableView *wordTable;
@property (retain, nonatomic) IBOutlet UISearchBar *sBar;
@property (retain, nonatomic) id <BGLWordViewControllerDelegate> delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil andList:(NSArray *)list withPBC:(NSMutableArray *)PBCList;

@end