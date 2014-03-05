//
//  PatientsTableViewController.h
//  AV Camera App
//
//  Created by NAYA LOUMOU on 12/1/13.
//  Copyright (c) 2013 NAYA LOUMOU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Exam.h"
#import "EyeImage.h"


@interface PatientsTableViewController : UITableViewController

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Exam* currentExam;

@property (nonatomic, strong) NSMutableArray *patientsArray;

@end
