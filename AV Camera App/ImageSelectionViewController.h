//
//  ImageSelectionViewController.h
//  OcularCellscope
//
//  Created by Chris Echanique on 2/19/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageSelectionViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UISlider *slider;

- (IBAction)didMoveSlider:(id)sender;

@end