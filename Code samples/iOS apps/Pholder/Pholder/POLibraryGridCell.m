//
//  POLibraryCollectionCell.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 10/5/14.
//
//

#import "POLibraryGridCell.h"

@interface POLibraryGridCell ()

@property (nonatomic) UIImageView *favoriteIcon;

@end


@implementation POLibraryGridCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
       _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
       self.imageView.contentMode = UIViewContentModeScaleAspectFill;
       self.imageView.clipsToBounds = YES;

       [self.contentView addSubview:self.imageView];
       
       _favoriteIcon = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width/2, frame.size.height/2, frame.size.width/2, frame.size.height/2)];
       self.favoriteIcon.contentMode = UIViewContentModeScaleAspectFill;
       self.favoriteIcon.clipsToBounds = YES;
       self.favoriteIcon.image = [UIImage imageNamed:@"Favorite_icon"];
       //self.favoriteIcon.alpha = 0.7;
       
       [self.contentView addSubview:self.favoriteIcon];
       self.favoriteIcon.hidden = YES;
       
       self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib
{
   [super awakeFromNib];
   
   self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
   self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)setIsFavorite:(BOOL)isFavorite {
   if (isFavorite) {
      self.favoriteIcon.hidden = NO;
   } else {
      self.favoriteIcon.hidden = YES;
   }
}

//- (void)layoutSubviews {
//   float width = self.frame.size.width;
//   float height = self.frame.size.height;
//   
//   self.imageView.frame = CGRectMake(0, 0, width, height);
//   self.favoriteIcon.frame = CGRectMake(width/2, height/2, width/2, height/2);
//}


@end
