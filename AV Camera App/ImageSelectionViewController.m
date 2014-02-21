//
//  ImageSelectionViewController.m
//  OcularCellscope
//
//  Created by Chris Echanique on 2/19/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import "ImageSelectionViewController.h"

@interface ImageSelectionViewController ()

@property(strong, nonatomic) NSMutableArray *images;
@property(assign, nonatomic) int currentImageIndex;

@end

@implementation ImageSelectionViewController

@synthesize imageView,slider, images, currentImageIndex;

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
    [imageView setImage:[UIImage imageNamed:@"im1.png"]];
    currentImageIndex = 0;
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    images = [[NSMutableArray alloc] init];
    UIImage *im1 = [UIImage imageNamed:@"im1.png"];
    UIImage *im2 = [UIImage imageNamed:@"im2.png"];
    UIImage *im3 = [UIImage imageNamed:@"im3.png"];
    UIImage *im4 = [UIImage imageNamed:@"im4.png"];
    
    [images addObject:im1];
    [images addObject:im2];
    [images addObject:im3];
    [images addObject:im4];
    
    NSLog(@"%@", images);
    
    [imageView setImage:im1];//[images objectAtIndex:currentImageIndex]];
    
    if([images count]<1)
        slider.hidden = YES;
    else{
        slider.minimumValue = 0;
        slider.maximumValue = [images count]-1;
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didMoveSlider:(id)sender{
    int newImageIndex = (int) (slider.value + .5);
    
    if(newImageIndex!=currentImageIndex){
        [imageView setImage:[images objectAtIndex:newImageIndex]];
        currentImageIndex = newImageIndex;
    }
    
}

-(IBAction)didTouchUpFromSlider:(id)sender{
    slider.value = currentImageIndex;
    
}


@end
