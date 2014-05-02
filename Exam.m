//
//  Exam.m
//  OcularCellscope
//
//  Created by Chris Echanique on 4/26/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import "Exam.h"
#import "EyeImage.h"


@implementation Exam

@dynamic date;
@dynamic firstName;
@dynamic lastName;
@dynamic notes;
@dynamic patientID;
@dynamic patientName;
@dynamic eyeImages;

- (void)addEyeImagesObject:(EyeImage *)image {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.eyeImages];
    [tempSet addObject:image];
    self.eyeImages = tempSet;
}

@end
