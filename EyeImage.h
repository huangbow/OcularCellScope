//
//  EyeImage.h
//  OcularCellscope
//
//  Created by PJ Loury on 6/19/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Exam;

@interface EyeImage : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * drName;
@property (nonatomic, retain) NSString * eye;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSNumber * fixationLight;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * uploaded;
@property (nonatomic, retain) Exam *exam;

@end
