//
//  Block.h
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import <Foundation/Foundation.h>

@interface BGLBlock : NSObject {
    char faces[6];
}

- (BGLBlock *)initWithFaces:(char *)faceInput;
- (char)roll;

@end
