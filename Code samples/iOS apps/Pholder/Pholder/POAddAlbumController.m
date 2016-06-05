//
//  POAddAlbumController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/18/14.
//
//

#import "POAddAlbumController.h"
#import "POLibraryRootController.h"
#import "POLibraryFullscreenController.h"

@interface POAddAlbumController ()

@property (nonatomic) NSArray *albumNames;
@property (nonatomic) NSMutableDictionary *startingMemberships;
@property (nonatomic) NSMutableDictionary *currentMemberships;

@end

@implementation POAddAlbumController

- (id)initWithAlbumNames:(NSArray *)names andMemberships:(NSArray *)memberships {
   if (self = [super init]) {
      _allowsDeletion = YES;
      _albumNames = names;
      _startingMemberships = [[NSMutableDictionary alloc] init];
      
      for (NSString *name in names) {
         BOOL isMember = [memberships containsObject:name];
         [self.startingMemberships setObject:[NSNumber numberWithBool:isMember] forKey:name];
      }
      
      _currentMemberships = [NSMutableDictionary dictionaryWithDictionary:self.startingMemberships];
   }
   return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
   self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(exitWithCancel)];
   self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                          target:self
                                                                                          action:@selector(exitWithSave)];
   if (self.allowsDeletion) {
      self.navigationItem.title = @"Set pholders for photo:";
   } else {
      self.navigationItem.title = @"Add photo to pholders:";
   }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)exitWithCancel {
   [self.delegate controllerFinishedWithAdditions:@[] andDeletions:@[]];
}

- (void)exitWithSave {
   NSMutableArray *additions = [[NSMutableArray alloc] initWithCapacity:self.albumNames.count];
   NSMutableArray *deletions = [[NSMutableArray alloc] initWithCapacity:self.albumNames.count];
   
   for (NSString *name in self.albumNames) {
      BOOL starting = [self.startingMemberships[name] boolValue];
      BOOL current = [self.currentMemberships[name] boolValue];
      
      if (starting == YES && current == NO) {
         [deletions addObject:name];
      } else if (starting == NO && current == YES) {
         [additions addObject:name];
      }
   }
   
   [self.delegate controllerFinishedWithAdditions:additions andDeletions:deletions];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return self.albumNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"albumAddCell"];
   if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"albumAddCell"];
   }
   
   NSString *name = self.albumNames[indexPath.item];
   cell.textLabel.text = name;
   
   if ([self.startingMemberships[name] boolValue] == YES && self.allowsDeletion == NO) {
      cell.textLabel.textColor = [UIColor lightGrayColor];
      cell.tintColor = [UIColor lightGrayColor];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.userInteractionEnabled = NO;
   } else {
      cell.textLabel.textColor = [UIColor blackColor];
      cell.tintColor = nil; // hopefully this un-sets the tint, if necessary?
      cell.selectionStyle = UITableViewCellSelectionStyleGray;
      cell.userInteractionEnabled = YES;
   }
   
   if ([self.currentMemberships[name] boolValue] == YES) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
   } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
   }

   return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   NSString *name = self.albumNames[indexPath.item];
   BOOL wasMember = [self.currentMemberships[name] boolValue];
   self.currentMemberships[name] = [NSNumber numberWithBool:!wasMember];

   UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
   if (wasMember) {
      cell.accessoryType = UITableViewCellAccessoryNone;
   } else {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
   }

   [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end