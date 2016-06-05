//
//  BGLWord.h
//  WordNerd
//
//  Created by Elana Bogdan on 12/1/11.
//

#import <Foundation/Foundation.h>

@class BGLAppDelegate;

@interface BGLWord : NSObject {
    NSString *workingString;
    NSUInteger endPoint;
    NSMutableArray *usedBlocks;
    char *gameBoard;
    UITextChecker *textChecker;
    BGLAppDelegate *delegate;
}

@property (copy, nonatomic) NSString *workingString;
@property (nonatomic) NSUInteger endPoint;
@property (retain, nonatomic) NSMutableArray *usedBlocks;
@property (assign, nonatomic) char *gameBoard;
@property (assign, nonatomic) BGLAppDelegate *delegate;

- (BGLWord *)initWithBoard:(char *)board atPoint:(NSUInteger)point;
- (BGLWord *)initFromPrevious:(BGLWord *)previousWord withString:(NSString *)passedWorking andEnd:(NSUInteger)passedPoint;
- (NSArray *)proliferate;
- (BOOL)isWord;
- (BOOL)canWord:(NSString *)testString;
- (NSString *)appendLetterToString:(char)letter;
- (void)printUsedArray;

@end
