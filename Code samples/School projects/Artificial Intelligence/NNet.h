#import <Foundation/Foundation.h>
#import "NNode.h"

@interface NNet : NSObject {
    NSMutableArray *layers;
    float lrate;
}

- (id)initWithLayers:(int *)l;

- (void)loadData:(float *)newData;
- (void)loadDataFromNSArray:(NSArray *)newData;

- (void)feedForward;
- (float)backPropFrom:(float *)y;

- (float)actFunc:(float)g;
- (float)actDeriv:(float)g;
- (float)calibrateInput:(float)d;
- (void)setRate:(float)r;
- (void)resetNet;

- (int)greatestOutput;

@end
