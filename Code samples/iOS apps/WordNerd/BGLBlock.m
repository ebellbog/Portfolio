//
//  Block.m
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import "BGLBlock.h"

@implementation BGLBlock

- (BGLBlock *)initWithFaces:(char *)faceInputs {
    if (self = [super init]) {
        for (int i = 0; i < 6; i++) {
            faces[i] = faceInputs[i];
        }
    }
    return self;
}

- (char)roll {
    return faces[arc4random()%6];
}

- (void)dealloc {
    [super dealloc];
}

@end

