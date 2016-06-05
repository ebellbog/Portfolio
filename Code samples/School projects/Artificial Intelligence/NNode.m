#import "NNode.h"

@implementation NNode

@synthesize propErr, act;

-(id)initWithID:(int)n {
    if (self = [super init]) {
        nID = n;
        act = 1.0; //For bias nodes, this should never get changed
        [self refreshWeights];
    }
    return self;
}

-(void)updateWeight:(float)w forNode:(int)n {
    weights[n] = weights[n]+w*act;
}

- (float)feedTo:(int)n {
    
    return (act*weights[n]);
}

- (void)manWeights:(float *)w {
    for (int i = 0; i < 3; i++) {
        weights[i] = w[i];
    }
}

- (void)refreshWeights {
    for (int i = 0; i < 20; i++) {
        weights[i] = arc4random()%2-1.0;
    }
}

- (float)weightTo:(int)n {
    return weights[n];
}

@end
