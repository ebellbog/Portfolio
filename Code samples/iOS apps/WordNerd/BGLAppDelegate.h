//
//  BGLAppDelegate.h
//  WordNerd
//
//  Created by Elana Bogdan on 11/28/11.
//

#import <UIKit/UIKit.h>

@class BGLMainViewController;

@interface BGLAppDelegate : UIResponder <UIApplicationDelegate> {
    NSMutableArray *blocks;
    NSMutableArray *smallBlocks;
    char freqLetters[1000];
    char alphabet[26];
    BOOL doRotate, setPBC;
    NSInteger boardSize, letterDistribution, minWords, minPoints, minLength;
    NSInteger versionNumber;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BGLMainViewController *mainViewController;

@property (readonly, nonatomic) NSMutableArray *blocks;
@property (readonly, nonatomic) NSMutableArray *smallBlocks;

@property (nonatomic) BOOL doRotate;
@property (nonatomic) BOOL setPBC;
@property (nonatomic) NSInteger boardSize;
@property (nonatomic) NSInteger letterDistribution;
@property (nonatomic) NSInteger minWords;
@property (nonatomic) NSInteger minPoints;
@property (nonatomic) NSInteger minLength;
@property (nonatomic) NSInteger versionNumber;

- (char)freqLetter:(int)letterRequest;
- (char)alphaLetter:(int)letterRequest;


@end
