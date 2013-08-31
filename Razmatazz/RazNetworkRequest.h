//
//  RazNetworkRequest.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-31.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  RazConnection;

typedef enum {
    RazNetworkRequestTypeNickNameCommand,
    RazNetworkRequestTypeFileMetaDataCommand,
    RaznetworkRequestTypeFile, // this is an empty request so that the programmer can just send this request with the file and name and let it figure everything out
    RazNetworkRequestTypeFileData,
    RazNetworkRequestTypeConfirmationOfFileTransferCommand,
} RazNetworkRequestType;

//typedef void(^RazNetworkRequestBlock)();

@interface RazNetworkRequest : NSObject

@property (nonatomic, assign) NSUInteger numberOfRequestAttempts;

- (id) initWithRazNetworkRequestType:(RazNetworkRequestType)networkRequestType paramaterDictionary:(NSDictionary*)paramDictionary andConnection:(RazConnection*)razConnection;

- (RazNetworkRequestType) getRequestType;
- (NSDictionary *) getParameterDictionary;

- (void) requestCompletedSuccessfully:(BOOL)success;

@end
