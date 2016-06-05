#import "NNet.h"

@implementation NNet

- (id)initWithLayers:(int *)l { //Note that l[0] will encode for the number of layers, while subsequent indices refer to nodes per layer
    if (self = [super init]) {
        layers = [[NSMutableArray alloc] initWithCapacity:l[0]];
        for (int i = 1; i <= l[0]; i++) {
            NSMutableArray *layer = [NSMutableArray arrayWithCapacity:l[i]];
            for (int j = 0; j < (i == l[0] ? l[i] : l[i]+1); j++) { //Macro for adding bias node to all non-output layers
                NNode *newNode = [[NNode alloc] initWithID:(100*i+j)];
                [layer addObject:newNode];
                [newNode release];
            }
            [layers addObject:layer];
            NSLog(@"Added layer %i to network with %i nodes.", i, layer.count);
        }
    }
    return self;
}

- (void)loadData:(float *)newData {
    NSArray *inputLayer = [layers objectAtIndex:0];
    float a;
    for (int i = 0; i < inputLayer.count-1; i++) { //Subtracting 1 to compensate for bias node
        a = [self calibrateInput:newData[i]];
        [(NNode *)[inputLayer objectAtIndex:i] setAct:a];
    }
}

- (void)loadDataFromNSArray:(NSArray *)newData {
    NSArray *inputLayer = [layers objectAtIndex:0];
    float a;
    for (int i = 0; i < inputLayer.count-1; i++) { //Subtracting 1 to compensate for bias node
        a = [self calibrateInput:[[newData objectAtIndex:0] floatValue]]/10.0;
        [(NNode *)[inputLayer objectAtIndex:i] setAct:a];
    }
}

- (void)feedForward {
    NSArray *layerI, *layerJ;
    NNode *node;
    float a;
    
    for (int l = 0; l < layers.count-1; l++) {
        layerI = [layers objectAtIndex:l];
        layerJ = [layers objectAtIndex:l+1];
        for (int j = 0; j < (l == layers.count-2 ? layerJ.count : layerJ.count-1); j++) { //Another macro to account for bias nodes at non-output layers
            a = 0;
            for (int i = 0; i < layerI.count; i++) { //Here we just let the bias node count as an input
                a += [[layerI objectAtIndex:i] feedTo:j];
            }
            
            node = [layerJ objectAtIndex:j];
            node.propErr = [self actDeriv:a]; //Temporary place to store g'(in), until needed for calculating deltas
            node.act = [self actFunc:a];
            
            //NSLog(@"Node %i in layer %i activated: %f",j,l+1,node.act);
        }
    }
}

- (float)backPropFrom:(float *)y {
    NSArray *layerI, *layerJ;
    NNode *node, *node2;
    float totalError = 0;
    
    for (int l = layers.count-1; l >= 0; l--) { //Iterate backwards through layers, starting with output
        layerI = [layers objectAtIndex:l];
        
        //Set delta j for output nodes
        if (l == layers.count-1) {
            for (int i = 0; i < layerI.count; i++) {
                node = [layerI objectAtIndex:i];
                node.propErr *= (y[i]-node.act); //propErr previously set to g'(in)
                totalError += fabs(y[i]-node.act);
                //NSLog(@"Correct answer: %.2f Predicted output: %.2f", y[i],node.act);
            }
        } 
        
        //Set delta i for hidden nodes
        else {
            layerJ = [layers objectAtIndex:l+1]; //Will initially refer to the output layer
            float p;
            for (int i = 0; i < layerI.count; i++) { //Here we let the bias node count, even though its delta will be irrelevant, so that we can update its weights
                p = 0;
                node = [layerI objectAtIndex:i];
                
                for (int j = 0; j < (l == layers.count-2 ? layerJ.count : layerJ.count-1); j++) { //Bias nodes not backpropped, removed from non-output ranges
                    node2 = [layerJ objectAtIndex:j];
                    if (l > 0) p += [node weightTo:j]*node2.propErr; //Unnecessary to determine delta if l is the input layer (or if bias node, but not worth checking)
                 
                    [node updateWeight:node2.propErr*lrate forNode:j]; //Update weights as we backprop (!-- after applying old weight to p --!)
                    //NSLog(@"Updated weight from node %i in layer %i to node %i", i, l, j);
                }
                
                if (l > 0) node.propErr *= p;
            }
        }
    }
    return totalError;
}

- (float)actFunc:(float)g {
    return (1/(1+exp(-g)));
}

- (float)actDeriv:(float)g {
    return ([self actFunc:g]*(1-[self actFunc:g]));
}

- (float)calibrateInput:(float)d {
    return d;
}

- (int)greatestOutput {
    float g, f = 0;
    int c = 0;
    
    NSArray *outputLayer = [layers lastObject];
    for (int i = 0; i < outputLayer.count; i++) {
        g = [(NNode *)[outputLayer objectAtIndex:i] act];
        //NSLog(@"Output node %i activated at %f",i,g);
        if (g > f) {
            f = g;
            c = i;
        }
    }
    return c;
}

- (void)resetNet {
    for (NSArray *layer in layers) {
        for (NNode *node in layer) {
            [node refreshWeights];
        }
    }
    NSLog(@"All weights randomized.");
}

- (void)setRate:(float)r {
    lrate = r;
}

@end
