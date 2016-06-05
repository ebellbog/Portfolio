//
//  POFocusingReticle.m
//  PhotoOrganize
//
//  Created by Elana Bogdan on 9/25/14.
//
//

#define FPS 60
#define scaleToFlashRatio 0.15

#import "POFocusingReticle.h"

@interface POFocusingReticle ()

@property (nonatomic) float timeRemaining;
@property (nonatomic) float reticleAlpha;

@end


@implementation POFocusingReticle

- (id)initWithCenter:(CGPoint)center andSize:(float)size {
   self = [super init];
   if (self) {
      _startSize = size;
      self.frame = CGRectMake(center.x-size/2, center.y-size/2, size, size);
      self.backgroundColor = [UIColor clearColor];
   }
   return self;
}

- (void)drawRect:(CGRect)rect
{
   float tickMarkLength = self.frame.size.width/9;
   float sideLength = self.frame.size.width*.9;
   
   UIBezierPath *aPath = [[UIBezierPath alloc] init];
   [aPath moveToPoint:CGPointMake(0, 0)];
   
   //Left side
   [aPath addLineToPoint:CGPointMake(0, sideLength/2)];
   [aPath addLineToPoint:CGPointMake(tickMarkLength, sideLength/2)];
   [aPath moveToPoint:CGPointMake(0, sideLength/2)];
   [aPath addLineToPoint:CGPointMake(0, sideLength)];
   
   //Bottom side
   [aPath addLineToPoint:CGPointMake(sideLength/2, sideLength)];
   [aPath addLineToPoint:CGPointMake(sideLength/2, sideLength-tickMarkLength)];
   [aPath moveToPoint:CGPointMake(sideLength/2, sideLength)];
   [aPath addLineToPoint:CGPointMake(sideLength, sideLength)];
   
   //Right side
   [aPath addLineToPoint:CGPointMake(sideLength, sideLength/2)];
   [aPath addLineToPoint:CGPointMake(sideLength-tickMarkLength, sideLength/2)];
   [aPath moveToPoint:CGPointMake(sideLength, sideLength/2)];
   [aPath addLineToPoint:CGPointMake(sideLength, 0)];
   
   //Top side
   [aPath addLineToPoint:CGPointMake(sideLength/2, 0)];
   [aPath addLineToPoint:CGPointMake(sideLength/2, tickMarkLength)];
   [aPath moveToPoint:CGPointMake(sideLength/2, 0)];
   [aPath addLineToPoint:CGPointMake(0, 0)];
   
   [[UIColor colorWithRed:1.0 green:0.82 blue:0 alpha:1.0] setStroke];
   
// CGContextSaveGState(aRef);
   CGContextRef contextRef = UIGraphicsGetCurrentContext();
   CGContextTranslateCTM(contextRef, 2, 2);
   
   aPath.lineWidth = 1;
   
   [aPath stroke];
// CGContextRestoreGState(aRef);
}



- (void)startAnimation {
   self.timeRemaining = self.lifeSpan*scaleToFlashRatio; //Shrink for first third of lifespan, then flash
   [NSTimer scheduledTimerWithTimeInterval:(1.0/FPS)
                                    target:self
                                  selector:@selector(updateSize:)
                                  userInfo:nil
                                   repeats:YES];
}

- (void)updateSize:(NSTimer *)timer {
   float percentRemaining = self.timeRemaining/(self.lifeSpan*scaleToFlashRatio);
   float currentSize = self.endSize+(self.startSize-self.endSize)*percentRemaining;
   
   self.frame = CGRectMake(self.center.x-currentSize/2, self.center.y-currentSize/2, currentSize, currentSize);
   
   [self setNeedsDisplay];
   
   self.timeRemaining -= 1.0/FPS;
   if (self.timeRemaining <= 0) {
      [timer invalidate];
      self.timeRemaining = self.lifeSpan*(1-scaleToFlashRatio);
      [NSTimer scheduledTimerWithTimeInterval:(1.0/FPS)
                                       target:self
                                     selector:@selector(flashReticle:)
                                     userInfo:nil
                                      repeats:YES];
   }
}

- (void)flashReticle:(NSTimer *)timer {
   float percentRemaining = self.timeRemaining/(self.lifeSpan*(1-scaleToFlashRatio));
   float frequency = 35.0;
   float amplitude = 0.4;
   self.alpha = 1.0-amplitude*sin((1.0-percentRemaining)*frequency); //starts alpha at 1 for smooth transition
   
   self.timeRemaining -= 1.0/FPS;
   if (self.timeRemaining <= 0) {
      [timer invalidate];
      [self performSelector:@selector(fadeOut) withObject:nil afterDelay:0.15];
   }
}

- (void)fadeOut {
   [UIView animateWithDuration:0.3
                    animations:^{
                       self.alpha = 0;
                    }
                    completion:^(BOOL finished) {
                       [self removeFromSuperview];
                    }];
}


@end
