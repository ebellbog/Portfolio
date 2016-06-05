//
//  POReusableHeaderViewWithTitle.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 12/7/14.
//
//

#import <UIKit/UIKit.h>
#import "POCommonMethods.h"


@interface POReusableHeaderViewWithTitle : UICollectionReusableView

- (void)setTitle:(NSString *)title;

@property (nonatomic) SectionType type;

@end
