#import "DETree.h"

@implementation DETree

@synthesize winners, losers, victors;
@synthesize currentMatch, currentlyInWinners;

- (id)initWithTeams: (NSArray *)teams {
    if (self = [super init]) {
        latestTier[0] = -1;
        latestTier[1] = 0;
        currentMatch = -1;
        currentlyInWinners = YES;
        
        int bracketSize = teams.count;
        
        if (log2(bracketSize) != floor(log2(bracketSize))) { //Check that number of teams is a power of 2
            NSLog(@"Invalid number of teams provided for tournament.");
            return self;
        }
        
        int winCapacity = log2(bracketSize)+1;
        int loseCapacity = winCapacity*2-3;
        
        self.winners = [NSMutableArray arrayWithCapacity:winCapacity];
        self.losers = [NSMutableArray arrayWithCapacity:winCapacity*2-3];
        self.victors = [NSMutableArray arrayWithObjects:@"", @"", @"", nil];
        
        NSMutableArray *temp;
        NSMutableArray *teamPool = [NSMutableArray arrayWithArray:teams];

        while (bracketSize >= 1) {
            temp = [NSMutableArray arrayWithCapacity:bracketSize];
            
            for (int i = 0; i < bracketSize; i++) {
                if (bracketSize == teams.count) { //Initialize leaves with random seeding of teams
                    int index = arc4random()%teamPool.count;
                    [temp addObject:[teamPool objectAtIndex:index]];
                    [teamPool removeObjectAtIndex:index];
                    
                }
                else [temp addObject:@""]; //Initialize rest of tree
            }
            
            [self.winners addObject:temp];
            bracketSize /= 2;
        }
        
        for (int i = 0; i < loseCapacity; i++) {
            int capacity = floor([(NSArray *)[self.winners objectAtIndex:floor(i/2)] count]/2);
            temp = [NSMutableArray arrayWithCapacity:capacity];
            for (int j = 0; j < capacity; j++) {
                [temp addObject:@""];
            }
            [self.losers addObject:temp];
        }

    }
    return self;
}

- (void)settleMatch:(int)match forTier:(int)tier inWinnersBracket:(BOOL)inWinners asWin:(BOOL)win {
    NSMutableArray *workingBracket = (inWinners ? self.winners : self.losers);
    NSMutableArray *workingTier = [workingBracket objectAtIndex:tier];
    NSString *winner = [workingTier objectAtIndex:(win ? 2*match : 2*match+1)];
    NSString *loser = [workingTier objectAtIndex:(win ? 2*match+1 : 2*match)];
    
    if ([winner isEqualToString:@""] || [loser isEqualToString:@""]) {
        NSLog(@"Match %i in tier %i of the %@ bracket depends on earlier matches; please resolve in order.\n",
              match, tier, (inWinners? @"winner's" : @"losers"));
        return;
    }
    
    //Promote winner
    if (inWinners || tier%2 == 1) {
        [[workingBracket objectAtIndex:tier+1] setObject:winner atIndex:match]; //From tier size n to tier size n/2
    }
    else [[workingBracket objectAtIndex:tier+1] setObject:winner atIndex:2*match+1]; //From tier size n to tier size n
    
    //Drop loser to lower bracket
    if (inWinners) {
        if (tier == 0) [[self.losers objectAtIndex:tier] setObject:loser atIndex:match];
        else {
            int lTier = 2*tier-1; //Maps tier in winner's bracket to corresponding tier loser will enter in loser's bracket
            int count = [[self.losers objectAtIndex:lTier] count];
            [[self.losers objectAtIndex:lTier] setObject:loser atIndex:count-2*(match+1)]; //Inverts match ordering, as shown in tournament background image
        }
    }
}

- (void)settleCurrentMatchAsWin:(BOOL)win {
    [self settleMatch:currentMatch forTier:latestTier[currentlyInWinners] inWinnersBracket:currentlyInWinners asWin:win];
}

- (void)settleFinalMatchAsWin:(BOOL)win {
    NSString *bestWinner = [[self.winners objectAtIndex:self.winners.count-1] objectAtIndex:0];
    NSString *bestLoser = [[self.losers objectAtIndex:self.losers.count-1] objectAtIndex:0];
    
    if ([[self.victors objectAtIndex:0] isEqualToString:@""]) { //First round of final
        [self.victors replaceObjectAtIndex:0 withObject:(win ? bestWinner : bestLoser)];
        if (!win) [self.victors replaceObjectAtIndex:1 withObject:bestWinner];
    }
    else [self.victors replaceObjectAtIndex:2 withObject:(win ? bestLoser : bestWinner)]; //Second round of final
}

- (BOOL)readyToPlayTier:(int)tier inWinnersBracket:(BOOL)inWinners {
    NSMutableArray *workingBracket = (inWinners ? self.winners : self.losers);
    int count = 0;
    for (NSString *string in [workingBracket objectAtIndex:tier]) {
        if ([string isEqualToString:@""]) {
            NSLog(@"Tier %i in %@ bracket is incomplete.", tier, (inWinners ? @"winner's" : @"loser's"));
            return NO;
        }
        count++;
    }
    return (count > 1); //Ensures that tier has at least two contestants
}

- (NSString *)isFinished {
    NSString *rString = nil;
    if (![[self.victors objectAtIndex:0] isEqualToString:@""] && [[self.victors objectAtIndex:1] isEqualToString:@""]) rString = [self.victors objectAtIndex:0];
    else if (![[self.victors objectAtIndex:2] isEqualToString:@""]) rString = [self.victors objectAtIndex:2];
    return rString;
}

- (BOOL)getNextMatch {
    NSMutableArray *workingBracket = (currentlyInWinners ? self.winners : self.losers);
    int tCheck = latestTier[0];
    int cCheck = self.losers.count-1;

    //Continue within bracket if more matches
    if ([[workingBracket objectAtIndex:latestTier[currentlyInWinners]] count] > (currentMatch+1)*2) currentMatch++;
    
    //Otherwise consider switching into a new losing bracket...
    else if (tCheck < cCheck && [self readyToPlayTier:latestTier[0]+1 inWinnersBracket:NO]) {
        currentlyInWinners = NO;
        currentMatch = 0;
        latestTier[0]++;
    }
    
    //...or a winning bracket, if the losing bracket wasn't ready.
    else if (latestTier[1] < self.winners.count-1 && [self readyToPlayTier:latestTier[1]+1 inWinnersBracket:YES]) {
        currentlyInWinners = YES;
        currentMatch = 0;
        latestTier[1]++;
    }
    
    //If no success, tournament must be finished.
    else {
        return NO;
    }
    return YES;
}

- (int)getIndexForMatch:(int)match forTier:(int)tier inWinnersBracket:(BOOL)inWinners {
    int index = 0;
    
    if (!inWinners) {
        for (NSArray *tier in self.winners) index += tier.count;
    }
    
    NSMutableArray *workingBracket = (inWinners ? self.winners : self.losers);
    while (tier > 0) {
        tier--;
        index += [[workingBracket objectAtIndex:tier] count];
    }
    
    index += 2*match;
    return index;
}

- (int)currentTier {
    return latestTier[currentlyInWinners];
}

- (void)dealloc {
    self.winners = nil;
    self.losers = nil;
    self.victors = nil;
    [super dealloc];
}


@end
