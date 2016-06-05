#import <Foundation/Foundation.h>
#import <stdlib.h>
#import "NNet.h"

@interface NNode : NSObject {
    int nID;
    float weights [20];
    float act, propErr;
}

@property (nonatomic) float propErr;
@property (nonatomic) float act;

- (id)initWithID:(int)n;

- (void)updateWeight:(float)w forNode:(int)n;
- (void)manWeights:(float *)w; //For debugging; allows manual input of weight values
- (void)refreshWeights;

- (float)feedTo:(int)n;
- (float)weightTo:(int)n;

@end
