//
//  POLibraryViewController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/29/14.
//
//

#import "PODataManager.h"
#import "POImagePickerController.h"
#import "POMainViewController.h"
#import "POLibraryRootController.h"
#import "POLibraryGridController.h"
#import "POLibraryNavigationController.h"
#import "NSString+SafeURL.h"

@interface POLibraryRootController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL justLoaded;
@property (atomic) NSMutableDictionary *recentThumbnails;

@end

@implementation POLibraryRootController

- (NSUInteger)supportedInterfaceOrientations
{
   return UIInterfaceOrientationMaskPortrait;
}


- (void)viewDidLoad
{
   [super viewDidLoad];
   self.navigationItem.title = @"Pholders";
   
   UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self.delegate
                                                                               action:@selector(libraryDidFinish)];
   self.navigationItem.leftBarButtonItem = doneButton;
   [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeLibrary) name:UIApplicationDidEnterBackgroundNotification object:nil];
   
   _recentThumbnails = [[NSMutableDictionary alloc] init];
   
   [self refreshRootView];

   self.justLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated {
   
   [(POLibraryNavigationController *)self.navigationController setSupportsLandscape:NO];
   
   if (self.justLoaded == NO) {
      [self refreshRootView];
   } else {
      self.justLoaded = NO;
   }
   
   [super viewWillAppear:animated];
}

- (void)closeLibrary {
   [self.delegate libraryDidFinish];
}

- (void)refreshRootView {
   NSLog(@"Refreshing root view...");
   
   POImagePickerController *imagePicker = (POImagePickerController *)self.delegate;
   POMainViewController *mainController = (POMainViewController *)imagePicker.delegate;
   
   NSSet *albumNames = [(POImagePickerController *)self.delegate albumNames];
   self.pholderNames = [[albumNames allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
   self.photoCounts = [mainController getCountsOfAllPhotosByPholder];
   
   [self refreshThumbnails];
   
   [self.tableView reloadData];
}

- (void)refreshThumbnails {
   [self.recentThumbnails removeAllObjects];
   
   NSMutableArray *allNames = [NSMutableArray arrayWithArray:self.pholderNames];
   [allNames addObject:MAIN_DATA];
   [allNames addObject:@"Favorites"];
   
   for (NSString *pholderName in allNames) {
      POPhotoData *newestPhoto = [PODataManager retrieveNewestPhotoInPholder:pholderName.safe];
      if (newestPhoto) {
         self.recentThumbnails[pholderName] = newestPhoto.photo;
      }
   }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
   self.photoCounts = nil;
   [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   POLibraryGridController *libraryCollection;
   NSDictionary *oldAlbumData = [(POImagePickerController *)self.delegate oldAlbumData];
   
   if (indexPath.section == 0) {
      if (indexPath.row == 0) {
         int albumSize = [self.photoCounts[MAIN_DATA] intValue];
         libraryCollection = [[POLibraryGridController alloc] initWithAlbumName:MAIN_DATA
                                                                      albumData:oldAlbumData[@"Camera Roll"]
                                                                        andSize:albumSize];
         libraryCollection.navigationItem.title = @"Camera Roll";
      } else {
         int albumSize = [self.photoCounts[@"Favorites"] intValue];
         libraryCollection = [[POLibraryGridController alloc] initWithAlbumName:@"Favorites"
                                                                      albumData:oldAlbumData[@"Pholder Favorites"]
                                                                        andSize:albumSize];
         libraryCollection.navigationItem.title = @"Favorites";
      }
   }
   else {
      NSString *albumName = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
      int albumSize = [self.photoCounts[albumName.safe] intValue];
      libraryCollection = [[POLibraryGridController alloc] initWithAlbumName:albumName
                                                                   albumData:oldAlbumData[albumName]
                                                                     andSize:albumSize];
   }

   libraryCollection.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                         style:UIBarButtonItemStylePlain target:nil action:nil];
   
   //Delay allows time for photos to begin loading after POLibraryGridController is init'd
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [self.navigationController pushViewController:libraryCollection animated:YES];
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
   });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   return 65;
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
   return  2;
};


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   if (section == 0) return 2;
   else return self.pholderNames.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
   if (section == 0) return nil;
   else return @"Custom pholders";
};


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"libraryCell"];
   if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"libraryCell"];
      cell.detailTextLabel.textColor = [UIColor darkGrayColor];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.indentationLevel = 1;
      cell.indentationWidth = 55;
      
      UIImageView *thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 55, 55)];
      thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
      thumbnailView.clipsToBounds = YES;
      thumbnailView.tag = 1234;
      
      [cell.contentView addSubview:thumbnailView];
   }
   
   NSNumber *photosInPholder = nil;
   
   
   // Set primary text on cell
   NSString *pholderName;
   if (indexPath.section == 0) {
      if (indexPath.row == 0) {
         pholderName = MAIN_DATA;
         cell.textLabel.text = @"Camera Roll";
      } else {
         pholderName = @"Favorites";
         cell.textLabel.text = @"Favorites";
      }
   }
   
   else {
      pholderName = self.pholderNames[indexPath.row];
      cell.textLabel.text = pholderName;
   }
   
   NSString *fixedPholderName = pholderName;
   if ([pholderName isEqualToString:@"Favorites"]) fixedPholderName = @"Pholder Favorites";
   if ([pholderName isEqualToString:MAIN_DATA]) fixedPholderName = @"Camera Roll";
   
   
   // Set thumbnail
   UIImageView *thumbnailView = (UIImageView *)[cell viewWithTag:1234];
   
   UIImage *thumbnailImage = self.recentThumbnails[pholderName];
   if (thumbnailImage) {
      [thumbnailView setImage:thumbnailImage];
   } else {
      CGImageRef ref = (__bridge CGImageRef)([[(POImagePickerController *)self.delegate thumbnailForAlbum]
                                              objectForKey:fixedPholderName]);
      if (ref) {
         [thumbnailView setImage:[UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationUp]];
      } else {
         [thumbnailView setImage:[UIImage imageNamed:@"DefaultThumbnail"]];
      }
   }
   
   // Set subtitle text on cell
   photosInPholder = self.photoCounts[pholderName.safe];
   
   NSString *detailText;
   if (photosInPholder == nil || [photosInPholder isEqualToNumber:@0]) {
      detailText = @"No new / ";
   }
   else {
      detailText = [NSString stringWithFormat:@"%@ new / ", photosInPholder];
   }
   

   NSDictionary *oldAlbumData = [(POImagePickerController *)self.delegate oldAlbumData];
   NSArray *oldContents = oldAlbumData[fixedPholderName];
   if (oldContents == nil || oldContents.count == 0) {
      detailText = [detailText stringByAppendingString:@"no saved"];
   } else {
      detailText = [detailText stringByAppendingString:[NSString stringWithFormat:@"%i saved", (int)oldContents.count]];
   }
   cell.detailTextLabel.text = detailText;
   
   return cell;
}




@end
