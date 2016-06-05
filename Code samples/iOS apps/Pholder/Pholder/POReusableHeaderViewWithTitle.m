//
//  POReusableHeaderViewWithTitle.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/7/14.
//
//

#import "POReusableHeaderViewWithTitle.h"


@interface POReusableHeaderViewWithTitle()
@property (nonatomic) UILabel *titleView;
@end

@implementation POReusableHeaderViewWithTitle

- (id)initWithFrame:(CGRect)frame {
   if (self = [super initWithFrame:frame]) {
      self.backgroundColor = [UIColor whiteColor];
      self.clipsToBounds = NO;
      
      _titleView = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, frame.size.width, frame.size.height)];
      self.titleView.textColor = [UIColor blackColor];
      self.titleView.font = [UIFont systemFontOfSize:12];
      [self addSubview:self.titleView];

      UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
      button.frame = CGRectMake(frame.size.width-23, (frame.size.height-16)/2, 16, 16);
      button.clipsToBounds = NO;
      [button addTarget:self action:@selector(displayInfo) forControlEvents:UIControlEventTouchUpInside];
      
      [self addSubview:button];

   }
   return self;
}

- (void)layoutSubviews {
   //self.titleView.frame = self.frame;
   [super layoutSubviews];
}

- (void)setTitle:(NSString *)title {
   self.titleView.text = title;
}


- (void)displayInfo {
   NSString *title;
   NSString *message;
   
   if (self.type == kSectionNew) {
      title = @"Help: New Photos";
      message = @"These photos have not yet been exported to your Photos library. You can delete them, favorite or un-favorite them, and add or remove them from custom albums. When you transfer them to your computer, you can use the Pholder Assistant application to sort them automatically.";
      
   } else if (self.type == kSectionEditable) {
      title = @"Help: Saved by Pholder";
      message = @"These photos have already been exported to your Photos library, but you can still add them to new albums or favorite them. When you transfer them to your computer, you can use the Pholder Assistant application to sort them automatically.";
      
   } else if (self.type == kSectionOld) {
      title = @"Help: Unmanaged Photos";
      message = @"You cannot delete or modify these photos in any way, because you created them outside of Pholder. The Pholder Assistant application will not sort them, even if they are in custom albums. To manage these photos with Pholder, tap a photo, then tap \"Import into Pholder library.\" It will show up under \"New photos.\"";

   }
   
   
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
   [alert show];
}

@end
