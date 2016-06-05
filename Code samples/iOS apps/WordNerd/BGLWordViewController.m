//
//  BGLWordViewController.m
//  WordNerd
//
//  Created by Elana Bogdan on 12/5/11.
//

#import "BGLWordViewController.h"
#import "BGLMainViewController.h"
#import "BGLAppDelegate.h"


@implementation BGLWordViewController

@synthesize foundList, displayList;
@synthesize wordTable, sBar;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil andList:(NSArray *)list withPBC:(NSMutableArray *)PBCList
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nil]) {
        self.title = @"Detected words";
        for (int i = 0; i < 12; i++) {
            sections[i][0] = 0;
            sections[i][1] = 0;
        }
        
        int counter = 0, length = 0, running = 0;
        NSString *word;
        
        for (word in list) {
            if (word.length != length) {
                length = word.length;
                sections[counter][0] = length;
                counter++;
            }
            sections[counter-1][1] += 1;
            running ++;
        }
        sections[11][0] = counter;
        sections[11][1] = running;
        
        if (!PBCList) self.foundList = list;
        else self.foundList = PBCList;
        self.displayList = [NSMutableArray arrayWithArray:foundList];        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.sBar.text = @"";
    self.wordTable.tableHeaderView = self.sBar;

    UILongPressGestureRecognizer *longRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
    [self.wordTable addGestureRecognizer:longRecognizer];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self.delegate action:@selector(controllerFinishedWithoutWord)];
    [self.navigationItem setLeftBarButtonItem:buttonItem];
    [buttonItem release];
    
    buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"Detected" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:buttonItem];
    [buttonItem release];
    
    versionBOOL = ([(BGLAppDelegate *)[[UIApplication sharedApplication] delegate] versionNumber] < 500);
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

- (void)dealloc {
    self.wordTable = nil;
    self.displayList = nil;
    self.sBar = nil;
    [super dealloc];
}

#pragma mark - Actions


#pragma mark - UITableViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (versionBOOL) {
        if ([self.sBar.text isEqualToString:@""]) [self.sBar resignFirstResponder];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self numberOfSectionsInTableView:tableView] > 1) [(BGLMainViewController *)self.delegate setWordIndex:indexPath];

    [self.delegate controllerFinishedWithWord:[[[tableView cellForRowAtIndexPath:indexPath] textLabel] text]];
}


- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:self.wordTable];
        NSIndexPath *indexPath = [self.wordTable indexPathForRowAtPoint:p];
        if (indexPath) {
            UITableViewCell *cell = [self.wordTable cellForRowAtIndexPath:indexPath];

            /*NSError *error;
            NSURL *wordURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://en.wiktionary.org/wiki/%@",cell.textLabel.text]];
            NSString *wordHTML = [NSString stringWithContentsOfURL:wordURL encoding:NSASCIIStringEncoding error:&error];
            NSArray *tokens = [[[wordHTML componentsSeparatedByString:@"<h2>"] objectAtIndex:2] componentsSeparatedByString:@"<ol>"];
            NSString *token;
            NSRange endToken;
            
            endToken = [wordHTML rangeOfString:@"</head>"];
            
            NSMutableString *pageCode;
            pageCode = [NSMutableString stringWithString:[wordHTML substringToIndex:(endToken.location+endToken.length)]];
            
            [pageCode appendString:@"<body>"];
            
            for (int i = 1; i < tokens.count; i++) {
                token = [tokens objectAtIndex:i];
                endToken = [token rangeOfString:@"</ol>"];
                [pageCode appendString:[token substringToIndex:endToken.location]];
            }
            
            [pageCode appendString:@"</body></html>"];
            NSLog(@"%@",pageCode);*/
            
            [self.delegate loadDefinitionView:cell.textLabel.text];
        }
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.displayList.count == self.foundList.count ? sections[section][1] : self.displayList.count);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.displayList.count == self.foundList.count ? sections[11][0] : 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *returnString;
    
    if (self.displayList.count == self.foundList.count) {
        int length = sections[section][0], score;
        int scores[5] = {1,1,2,3,5};
        score = (length >= 8 ? 11 : scores[length-3]);
        returnString = [NSString stringWithFormat:@"%i-Letter words (%i point%@",length,score,((score > 1) ? @"s)" : @")")];
    }
    else returnString = @"";
    return returnString;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    cell = [tv dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        
    }
    
    if (self.displayList.count == self.foundList.count) {
        int section = 0, total = 0;
        while (section < indexPath.section) {
            total += sections[section][1];
            section++;
        }
        cell.textLabel.text = [foundList objectAtIndex:total+indexPath.row];
    } else cell.textLabel.text = [displayList objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.wordTable.contentOffset = CGPointMake(0, 0);
    [self.displayList removeAllObjects];
    if (searchText.length > 0) {
        NSString *word;
        NSRange range;
        for (word in self.foundList) {
            range = [word rangeOfString:searchText];
            if (range.location == 0 || (range.location == 1 && [word characterAtIndex:0] == '*')) [self.displayList addObject:word];
        }
    } else [self.displayList addObjectsFromArray:self.foundList];
    [self.wordTable reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    self.displayList = [NSMutableArray arrayWithArray:self.foundList];
    [self.wordTable reloadData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end
