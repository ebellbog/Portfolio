#import <Foundation/Foundation.h>
#import "math.h"

@interface DETree : NSObject {
    NSMutableArray *winners;
    NSMutableArray *losers;
    NSMutableArray *victors;
    
    int latestTier[2];
    int currentMatch;
    BOOL currentlyInWinners;
}

@property (nonatomic, retain) NSMutableArray *winners;
@property (nonatomic, retain) NSMutableArray *losers;
@property (nonatomic, retain) NSMutableArray *victors;
@property (nonatomic, readonly) int currentMatch;
@property (nonatomic, readonly) int currentTier;
@property (nonatomic, readonly) BOOL currentlyInWinners;

//Takes in array of team names; class will accomodate any number of teams that is a power of 2
- (id)initWithTeams: (NSArray *)teams;


/*Updates both brackets to reflect a win for the first (asWin: YES) or second (asWin: NO) competitor
 Note that:
    Tier 0 contains leaves, last tier contains winner
    Matchs and tiers start with index 0
    asWin to a win for the upper competitor
*/
- (void)settleMatch:(int)match forTier:(int)tier inWinnersBracket:(BOOL)inWinners asWin:(BOOL)win;


//Calls settleMatch: on arguments stored in member variables
-(void)settleCurrentMatchAsWin:(BOOL)win;

//Pits winner's bracket against loser's
-(void)settleFinalMatchAsWin:(BOOL)win;

//Returns YES if another match was available, NO if tournament is over
- (BOOL)getNextMatch;

//Returns tagID for view corresponding to first competitor in match
- (int)getIndexForMatch:(int)match forTier:(int)tier inWinnersBracket:(BOOL)inWinners;

//Checks whether all contestants in a given tier have been determined
- (BOOL)readyToPlayTier:(int)tier inWinnersBracket:(BOOL)inWinners;

//Returns the winner if the tournament is over, otherwise returns nil
- (NSString *)isFinished;


@end
