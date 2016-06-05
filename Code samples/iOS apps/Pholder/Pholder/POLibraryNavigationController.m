//
//  POLibraryNavigationController.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/7/14.
//
//

#import "POLibraryNavigationController.h"

@interface POLibraryNavigationController ()

@end

@implementation POLibraryNavigationController

- (BOOL)shouldAutorotate {
   return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
   if (self.supportsLandscape) {
      return UIInterfaceOrientationMaskAllButUpsideDown;
   } else {
      return UIInterfaceOrientationMaskPortrait;
   }
}

- (void)viewDidLoad {
   [super viewDidLoad];
   self.supportsLandscape = NO;
   
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
