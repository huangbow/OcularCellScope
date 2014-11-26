//
//  ParseUploadManager.m
//  Ocular Cellscope
//
//  Created by Frankie Myers on 11/24/14.
//  Copyright (c) 2014 UC Berkeley Fletcher Lab. All rights reserved.
//


#import "ParseUploadManager.h"


@implementation ParseUploadManager

int _totalNumberOfImagesToUpload = 0;
BOOL _queueIsProcessing = NO;

- (id) init
{
    self = [super init];
    if(self){
        self.imagesToUpload = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addExamToUploadQueue:(Exam*)exam
{

    if (exam.uploaded.intValue!=0) {
        //TODO: handle this exam differently (it's already been uploaded/partially uploaded)
        //load the parseExam from Parse
    }
    

    //this gets all the EyeImage objects for this exam from CD which have not been uploaded yet
    NSArray* eyeImagesToAdd = [CoreDataController getEyeImagesToUploadForExam:exam];
    
    if (eyeImagesToAdd.count>0)
        exam.uploaded = @1; //upload "pending"
    else
        exam.uploaded = @2; //nothing to upload (note: this won't update the exam info in Parse)
    
    NSLog(@"adding exam: %@ to upload queue with %d images",exam.patientIndex,eyeImagesToAdd.count);
    
    [self.imagesToUpload addObjectsFromArray:eyeImagesToAdd];
    
    _totalNumberOfImagesToUpload += eyeImagesToAdd.count;
    
    if (_queueIsProcessing==NO)
        [self processUploadQueue];

}

- (void) processUploadQueue
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
        _queueIsProcessing = YES;
        
        //process queue
        while (self.imagesToUpload.count>0) {
            EyeImage* nextImage = self.imagesToUpload[0];
            self.currentExam = nextImage.exam;
            NSLog(@"uploading image: %@",nextImage.uuid);
            
            //calculate progress and fire notification
            self.currentExamProgress = (float)[self.currentExam numberOfImagesUploaded]/(float)self.currentExam.eyeImages.count;
            self.overallProgress = 1 - ((float)self.imagesToUpload.count / (float)_totalNumberOfImagesToUpload); //calculate overall progress
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadProgressChangeNotification" object:nil];
            
            //upload "pending"
            nextImage.uploaded = @1;
            
            //trigger the upload. when it's done, it will set uploaded to 2 if success or 0 if fail
            [self uploadImage:nextImage];
            
            //wait for upload to complete
            while (nextImage.uploaded.intValue==1)
                [NSThread sleepForTimeInterval:0.1];
            
            //dequeue this image
            [self.imagesToUpload removeObject:nextImage];
            
            //check to see if parent exam should also be marked as uploaded
            if ([self.currentExam numberOfImagesUploaded]==self.currentExam.eyeImages.count) {
                //all images have been uploaded for this exam, so update the overall exam upload status
                self.currentExam.uploaded = @2;
                self.currentExam = nil;
                self.currentParseExam = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[CellScopeContext sharedContext] managedObjectContext] save:nil];
                });

            }

        }
        

        self.currentExam = nil;
        self.currentParseExam = nil;
        self.overallProgress = 1;
        self.currentExamProgress = 1;
        _totalNumberOfImagesToUpload = 0; //reset this
        _queueIsProcessing = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadProgressChangeNotification" object:nil];
        
    });
    
    
}

- (void)uploadImage:(EyeImage *)eyeImage
{
    NSURL *aURL = [NSURL URLWithString: eyeImage.filePath];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:aURL
             resultBlock:^(ALAsset *asset)
     {
         ALAssetRepresentation* rep = [asset defaultRepresentation];
         
         NSUInteger size = (NSUInteger)rep.size;
         NSMutableData *imageData = [NSMutableData dataWithLength:size];
         NSError *error;
         [rep getBytes:imageData.mutableBytes fromOffset:0 length:size error:&error];
         
         [self uploadImageDataToParse:imageData
                    completionHandler:^(BOOL success, NSError* err) {
                        NSLog(@"image upload complete");
                        if (success)
                            eyeImage.uploaded = @2; //mark as uploaded
                        else
                            eyeImage.uploaded = @0; //mark as not uploaded
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[[CellScopeContext sharedContext] managedObjectContext] save:nil];
                        });
                        
                        NSLog(@"%@",err.description); //print error
                    }];
         
         //completion block should check for error, if error, set upload to 0, else 2, and save CD
         
     }
            failureBlock:^(NSError *error)
     {
         NSLog(@"failure loading video/image from AssetLibrary");
     }
     ];
}


- (void)uploadImageDataToParse:(NSData *)imageData completionHandler:(void(^)(BOOL,NSError*))completionBlock//add completion block
{
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"Image-%d.jpg",arc4random()] data:imageData];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *eyeImage = [PFObject objectWithClassName:@"EyeImage"];
            [eyeImage setObject:imageFile forKey:@"Image"];
            eyeImage[@"Eye"] = @"OD";
            
            // Set the access control list to current user for security purposes
            //eyeImage.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            [eyeImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
             {
                 if (!error) {
                     //TODO: pull the parse patient from the exam of this eyeImage
                     if (self.currentParseExam==nil) { //create one (or...search Parse DB to see if this record exists already)
                         
                         /*
                         if(self.currentExam.uuid)
                         {
                             PFQuery *query = [PFQuery queryWithClassName:@"Patient"];
                             [query getObjectInBackgroundWithId:self.currentExam.uuid block:^(PFObject *patient, NSError *error) {
                                 
                                 //TODO: wait for this query to return and get the parse object
                             }];
                         }
                         else...
                        */
                         
                         //new parse exam
                         PFObject* parseExam = [PFObject objectWithClassName:@"Patient"];
                         
                         parseExam[@"firstName"] = self.currentExam.firstName;
                         parseExam[@"lastName"] = self.currentExam.lastName;
                         parseExam[@"patientID"] = self.currentExam.patientID;
                         parseExam[@"phoneNumber"] = self.currentExam.phoneNumber;
                         //...
                         
                         self.currentParseExam = parseExam;
                     }
                     PFRelation *relation = [self.currentParseExam relationForKey:@"EyeImages"];
                     [relation addObject: eyeImage];
                     

                     [self.currentParseExam saveInBackground]; //why is this not working w/ callback??
                     //need to get the UUID from this callback and save it to the eyeImage object, so that next time we generate this object we can refer to the correct one
                     //THEN call completionBlock
                     
                     completionBlock(succeeded,nil);
                     
                     /*
                      :^(BOOL succeeded, NSError *error)
                      {
                          if (!error)
                              completionBlock(succeeded,nil);
                          else
                              completionBlock(NO,error);
                      }];
                      */
                 }
                 else
                     completionBlock(NO,error);
             }];
        }
        else
            completionBlock(NO,error);
    } progressBlock:^(int percentDone) {} //file upload progress (not using this now)
    ];
    
    
}

@end