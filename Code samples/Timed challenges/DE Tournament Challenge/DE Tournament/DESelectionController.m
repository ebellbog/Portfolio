#import "DESelectionController.h"

@implementation DESelectionController

@synthesize delegate = _delegate;
@synthesize aButton, bButton, aLabel, bLabel, aName, bName;

- (id)initWithTeamA:(NSString *)teamA andTeamB:(NSString *)teamB
{
    self = [super init];
    if (self) {
        self.aName = teamA;
        self.bName = teamB;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *imageA = [[self.delegate teamLogos] valueForKey:self.aName];
    UIImage *imageB = [[self.delegate teamLogos] valueForKey:self.bName];
    
    if (!imageA) [self.delegate reloadImageWithName:self.aName];
    if (!imageB) [self.delegate reloadImageWithName:self.bName];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshButtons:) name:@"LoadedLogoForScopely" object:nil];
    
    [self.aButton setImage:imageA forState:UIControlStateNormal];
    [self.bButton setImage:imageB forState:UIControlStateNormal];
    
    self.aLabel.text = self.aName;
    self.bLabel.text = self.bName;
}

- (void)refreshButtons:(NSNotification *)notification {
    NSString *name = [notification.userInfo valueForKey:@"name"];
    
    if ([name isEqualToString:self.aName]) {
        UIImage *image = [[self.delegate teamLogos] valueForKey:self.aName];
        [self.aButton setImage:image forState:UIControlStateNormal];
        
    } else if ([name isEqualToString:self.bName]) {
        UIImage *image = [[self.delegate teamLogos] valueForKey:self.bName];
        [self.bButton setImage:image forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.aButton = nil;
    self.bButton = nil;
    self.aLabel = nil;
    self.bLabel = nil;
    self.aName = nil;
    self.bName = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)selectWinner:(UIView *)sender {
    [self.delegate selectionControllerDidFinishWithWin:sender.tag];
}

@end
