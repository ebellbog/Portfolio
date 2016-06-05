//
//  BGLResultsViewController.m
//  WordNerd
//
//  Created by Elana Bogdan on 12/12/11.
//

#import "BGLResultsViewController.h"
#import "BGLMainViewController.h"

@implementation BGLResultsViewController

@synthesize delegate = _delegate;
@synthesize stats, statNames;

- (id)initWithNibName:(NSString *)nibNameOrNil andSender:(BGLMainViewController *)mainDel {

    self = [super initWithNibName:nibNameOrNil bundle:nil];

    if (self) {
        NSArray *foundList = mainDel.foundList;
        NSDictionary *foundDict = mainDel.foundDict;
        
        int shortestWord, commonWord, multipleWord = 0, variantWord = 0;
        float averageWord;
        
        if (foundList.count > 0) {
            shortestWord = [[foundList objectAtIndex:0] length];
            
            NSString *word;
            int mode[23] = {0};
            
            int count = 0;
            for (word in foundList) {
                count += word.length;
                mode[word.length-3]++;
            }
            averageWord = (float)count/(float)foundList.count;
            
            int max = 0;
            for (int i = 0; i < 23; i++) {
                if (mode[i] > max) {
                    commonWord = i+3;
                    max = mode[i];
                }
            }
            
            if (foundList.count > 1) {
                NSArray *blockSet;
                NSString *nextWord;
                for (blockSet in [foundDict allValues]) {
                    multipleWord += (blockSet.count > 25);
                }
                
                foundList = [foundList sortedArrayUsingSelector:@selector(compare:)];
                for (int i = 1; i < foundList.count; i++) {
                    word = [foundList objectAtIndex:i-1];
                    nextWord = [foundList objectAtIndex:i];
                    if (nextWord.length > word.length) {
                        if ([word isEqualToString:[nextWord substringToIndex:word.length]]) variantWord++;
                    }
                }
            }
        } else {
            shortestWord = 0;
            averageWord = 0;
            commonWord = 0;
        }
        
        self.stats = [NSArray arrayWithObjects:
                 [NSString stringWithFormat:@"%i", mainDel.wordCount],
                 [NSString stringWithFormat:@"%i", mainDel.pointCount],
                 [NSString stringWithFormat:@"%i", mainDel.maxWord],
                 [NSString stringWithFormat:@"%i", shortestWord],
                 [NSString stringWithFormat:@"%0.2f", averageWord],
                 [NSString stringWithFormat:@"%i", commonWord],
                 [NSString stringWithFormat:@"%i", multipleWord],
                 [NSString stringWithFormat:@"%i", variantWord],
                 nil];
        
        self.statNames = [NSArray arrayWithObjects:
                          @"Words:",
                          @"Points:",
                          @"Longest word:",
                          @"Shortest word:",
                          @"Average length:",
                          @"Most common length:",
                          @"Appear multiple times:",
                          @"Appear with extensions:",
                          nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)done {
    [self.delegate modalViewControllerDidFinish];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case 0:
            title = @"Total...";
            break;
        case 1:
            title = @"Letters in...";
            break;
        case 2:
            title = @"Words that...";
            break;
            
        default:
            title = @"";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"] autorelease];
    int indices[3] = {0,2,6};
    int overallIndex = indexPath.row+indices[indexPath.section];
    cell.textLabel.text = [self.statNames objectAtIndex:overallIndex];
    cell.detailTextLabel.text = [self.stats objectAtIndex:overallIndex];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rowCounts[3] = {2,4,2};
    return rowCounts[section];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc {

    self.stats = nil;
    self.statNames = nil;
    [super dealloc];
}

@end
