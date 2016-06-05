//
//  POFocusingReticle.h
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/25/14.
//
//

#import <UIKit/UIKit.h>

@interface POFocusingReticle : UIView

@property (nonatomic) float startSize;
@property (nonatomic) float endSize;
@property (nonatomic) float lifeSpan;

- (id)initWithCenter:(CGPoint)center andSize:(float)size;
- (void)startAnimation;

@end
