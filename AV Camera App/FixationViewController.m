//
//  FixationViewController.m
//  OcularCellscope
//
//  Created by PJ Loury on 2/27/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import "FixationViewController.h"
#import "CaptureViewController.h"
#import "ImageSelectionViewController.h"
#import "CoreDataController.h"
#import "CameraAppDelegate.h"
#import "Constants.h"


@interface FixationViewController ()

@end

@implementation FixationViewController


@synthesize selectedEye, selectedLight, oldSegmentedIndex, actualSegmentedIndex;

//This is an EyeImage
@synthesize leftEyeImage;

//These are Buttons
@synthesize centerFixationButton, topFixationButton,
bottomFixationButton, leftFixationButton, rightFixationButton, noFixationButton;

//This is an array of buttons
@synthesize fixationButtons;

@synthesize eyeImages;

@synthesize managedObjectContext= _managedObjectContext;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CameraAppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    _managedObjectContext = [appDelegate managedObjectContext];

    fixationButtons = [NSMutableArray arrayWithObjects: centerFixationButton, topFixationButton,
                                       bottomFixationButton, leftFixationButton, rightFixationButton, noFixationButton, nil];

    //[self loadImages: self.segmentedControl.selectedSegmentIndex];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:(BOOL) animated];
    
    //ONLY RELOAD IF ITS CHANGED
    [self loadImages: self.segmentedControl.selectedSegmentIndex];
    
}

-(void)loadImages:(NSInteger)segmentedIndex{
    
    if(self.segmentedControl.selectedSegmentIndex == 0){
        selectedEye = LEFT_EYE;
    }
    else{
        selectedEye = RIGHT_EYE;
    }
        //load the images
        for (int i = 1; i <= 6; i++)
        {
            //Attempt 3
             self.eyeImages = [CoreDataController getObjectsForEntity:@"EyeImage" withSortKey:@"date" andSortAscending:YES andContext:self.managedObjectContext];
            
            //Atempt 2
            /*
            NSPredicate *p = [NSPredicate predicateWithFormat: @"eye == %@ AND fixationLight == %d", selectedEye, i];
            
            NSMutableArray *nsmar = [CoreDataController searchObjectsForEntity:@"EyeImage" withPredicate: p
                                                                    andSortKey: @"date" andSortAscending: YES
                                      andContext: _managedObjectContext];
            */
            
            
            //Attempt 1
            /*
            
            //NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"EyeImage"];
            
            //request.entity = [NSEntityDescription entityForName:@"EyeImage" inManagedObjectContext: _managedObjectContext];
            request.predicate = [NSPredicate predicateWithFormat: @"eye == %@ AND fixationLight == %d", selectedEye, i];
            request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
            request.fetchLimit = 1;
            NSError *error;
            
            NSArray *array = [_managedObjectContext executeFetchRequest:request error:&error];
            
            */
            
            
            if([eyeImages count] != 0){
                leftEyeImage = eyeImages[0];
                UIImage* thumbImage = [UIImage imageWithData: leftEyeImage.thumbnail];
                [fixationButtons[i-1] setImage: thumbImage forState:UIControlStateNormal];
                [fixationButtons[i-1] setSelected: YES];
            }
            else{
                UIImage* thumbImage = [UIImage imageNamed: @"Icon.png"];
                [fixationButtons[i-1] setImage: thumbImage forState: UIControlStateNormal];
                [fixationButtons[i-1] setSelected: NO];
                
            }
        }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressFixation:(id)sender {
    
    
    self.selectedLight = [sender tag];
    
    
    if( [sender isSelected] == NO){
    //there are pictures!
        [self performSegueWithIdentifier:@"captureViewSegue" sender:(id)sender];
    }
    
    else if([sender isSelected] == YES ){
        [self performSegueWithIdentifier:@"imageSelectionSegue" sender:(id)sender];
        
    }
    
}


- (IBAction)didSegmentedValueChanged:(id)sender {
    //self.oldSegmentedIndex = self.actualSegmentedIndex;
    //self.actualSegmentedIndex = self.segmentedControl.selectedSegmentIndex;
    
    //[self loadImages: self.segmentedControl.selectedSegmentIndex];
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"captureViewSegue"])
    {
        CaptureViewController* cvc = (CaptureViewController*)[segue destinationViewController];
       cvc.whichEye = self.selectedEye;
       cvc.whichLight = self.selectedLight;
    }
    
    else if ([[segue identifier] isEqualToString:@"imageSelectionSegue"])
    {
        ImageSelectionViewController * isvc = (ImageSelectionViewController*)[segue destinationViewController];
       isvc.whichEye = self.selectedEye;
       isvc.whichLight = self.selectedLight;
    }

}


@end
