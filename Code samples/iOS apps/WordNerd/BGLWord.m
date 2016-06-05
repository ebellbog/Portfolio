//
//  BGLWord.m
//  WordNerd
//
//  Created by Elana Bogdan on 12/1/11.
//

#import "BGLWord.h"
#import "BGLAppDelegate.h"

@implementation BGLWord

@synthesize endPoint;
@synthesize usedBlocks;
@synthesize workingString;
@synthesize delegate;

- (char *)gameBoard {
    return gameBoard;
}

- (void)setGameBoard: (char *)board {
    gameBoard = board;
}

- (BGLWord *)initWithBoard:(char *)board atPoint:(NSUInteger)point {
    if (self = [super init]) {
        textChecker = [[UITextChecker alloc] init];
        delegate = (BGLAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.gameBoard = board;
        self.endPoint = point;
        char c = *(gameBoard+point);
        if (c == '?') self.workingString = @"qq";
        else if (c == 'q') self.workingString = @"qu";
        else self.workingString = [NSString stringWithFormat:@"%c",c];
        self.usedBlocks = [NSMutableArray arrayWithCapacity:25];
        
        for (int i = 0; i < 25; i++) {
            [self.usedBlocks addObject:[NSNumber numberWithInt:((i == point) ? 1 : 0)]];
        }
    }
    return self;
}

- (BGLWord *)initFromPrevious:(BGLWord *)previousWord withString:(NSString *)passedWorking andEnd:(NSUInteger)passedPoint {
    if (self = [super init]) {
        textChecker = [[UITextChecker alloc] init];
        delegate = (BGLAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.endPoint = passedPoint;
        self.workingString = passedWorking;

        self.gameBoard = previousWord.gameBoard;
        self.usedBlocks = [NSMutableArray arrayWithArray:previousWord.usedBlocks];
        [self.usedBlocks replaceObjectAtIndex:self.endPoint withObject:[NSNumber numberWithInt:[[workingString stringByReplacingOccurrencesOfString:@"q" withString:@""] length]]];
    }
    return self;
}

- (NSArray *)proliferate {
    int r, c, d;
    c = (self.endPoint)%5;
    r = (self.endPoint/5);
    
    NSMutableArray *newWords = [[NSMutableArray alloc] init];
    [newWords autorelease];
    
    NSString *newWorking;
    if (!delegate.setPBC) {
        for (int i = -1; i < 2; i++) {
            if (c+i < 5 && c+i > -1) {
                for (int j = -1; j < 2; j++) {
                    if (r+j < 5 && r+j > -1) {
                        d = j*5+i;
                        if ([[self.usedBlocks objectAtIndex:self.endPoint+d] intValue] == 0) {
                            newWorking = [self appendLetterToString:*(gameBoard+self.endPoint+d)];
                            if ([self canWord:newWorking]) [newWords addObject:[[[BGLWord alloc] initFromPrevious:self withString:newWorking andEnd:self.endPoint+d] autorelease]];
                        }
                    }
                }
            }
        }
    } else {
        int size = 4+delegate.boardSize, newIndex;
        for (int i = -1; i < 2; i++) {
            for (int j = -1; j < 2; j++) {
                newIndex = 5*((r+j+size)%size)+(c+i+size)%size;
                if ([[self.usedBlocks objectAtIndex:newIndex] intValue] == 0) {
                    newWorking = [self appendLetterToString:*(gameBoard+newIndex)];
                    if ([self canWord:newWorking]) {
                        [newWords addObject:[[[BGLWord alloc] initFromPrevious:self withString:newWorking andEnd:newIndex] autorelease]];
                    }
                }
            }
        }
    }
    return newWords;
}

- (BOOL)isWord {
    int boardSize = delegate.boardSize;
    BOOL twoTry = NO;
    if (self.workingString.length > 2 + boardSize) {
        /*NSRange spellRange = [textChecker rangeOfMisspelledWordInString:self.workingString range:NSMakeRange(0, self.workingString.length) startingAt:0 wrap:NO language:[[NSLocale preferredLanguages] objectAtIndex:0]];
        twoTry = (spellRange.location == NSNotFound);*/
        NSArray *wordCompletions = (NSMutableArray *)[textChecker completionsForPartialWordRange:NSMakeRange(0, self.workingString.length) inString:self.workingString language:[[NSLocale preferredLanguages] objectAtIndex:0]];
        twoTry = [(NSString *)[wordCompletions objectAtIndex:0] isEqualToString:self.workingString];
        if (!twoTry && wordCompletions.count > 1) twoTry = [(NSString *)[wordCompletions objectAtIndex:1] isEqualToString:self.workingString];
    }
    return (twoTry);
}

- (BOOL)canWord:(NSString *)testString {
    NSMutableArray *wordCompletions = (NSMutableArray *)[textChecker completionsForPartialWordRange:NSMakeRange(0, testString.length) inString:testString language:[[NSLocale preferredLanguages] objectAtIndex:0]];
    
    NSString *temp;
    for (int i = 0; i < wordCompletions.count; i++) {
        temp = [wordCompletions objectAtIndex:i];
        if ([temp compare:[temp lowercaseString]] != NSOrderedSame) [wordCompletions removeObjectAtIndex:i];
    }
    //NSLog(@"For word %@, there are %i possible completions.",testString,wordCompletions.count);
    return (wordCompletions.count > 0);
}

- (NSString *)appendLetterToString:(char)letter {
    NSString *returnString;
    
    if (letter == '?') returnString = @"qq";
    else if (letter == 'q') returnString = [self.workingString stringByAppendingString:@"qu"];
    else returnString = [NSString stringWithFormat:@"%@%c",self.workingString, letter];
    
    return returnString;
}

- (void)printUsedArray {
    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
            printf("%i ",[[usedBlocks objectAtIndex:5*i+j] intValue]);
        }
        printf("\n");
    }
    printf("\n");
}

- (void)dealloc {
    [textChecker release];
    [workingString release];
    [usedBlocks release];
    [super dealloc];
}

@end
