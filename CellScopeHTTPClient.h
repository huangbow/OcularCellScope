//
//  CellScopeHTTPClient.h
//  OcularCellscope
//
//  Created by PJ Loury on 4/28/14.
//  Copyright (c) 2014 NAYA LOUMOU. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "CellScopeContext.h"
#import "UploadBannerView.h"

@protocol CellScopeHTTPClientDelegate;

@interface CellScopeHTTPClient : AFHTTPSessionManager
@property (nonatomic, weak) id<CellScopeHTTPClientDelegate>delegate;
@property NSMutableArray *imagesToUpload;
@property NSMutableArray *mutableOperations;
@property UploadBannerView *uploadBannerView;

+ (CellScopeHTTPClient *)sharedCellScopeHTTPClient;
- (instancetype)initWithBaseURL:(NSURL *)url;
- (void)updateDiagnosisForExam:(Exam *)exam;
- (void)uploadEyeImagesPJ:(NSArray *)images;
- (void)uploadEyeImagesFromArray:(NSArray *)images;
- (void)batch;
@end

@protocol CellScopeHTTPClientDelegate <NSObject>
@optional
-(void)cellScopeHTTPClient:(CellScopeHTTPClient *)client didUpdateDiagnosis:(id)diagnosis;
-(void)cellScopeHTTPClient:(CellScopeHTTPClient *)client didFailWithError:(NSError *)error;
-(void)cellScopeHTTPClient:(CellScopeHTTPClient *)client didUploadEyeImage:(id)eyeImage;

@end