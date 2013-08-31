//
//  RazNetworkRequest.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-31.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazNetworkRequest.h"
#import "RazConnection.h"

@interface RazNetworkRequest ()

@property (nonatomic, assign) RazNetworkRequestType  requestType;
@property (nonatomic, strong) NSDictionary *         parameterDictionary;
@property (nonatomic, strong) NSTimer *              timeoutTimer;
@property (nonatomic, weak) RazConnection *          connection;

@end

@implementation RazNetworkRequest

- (id) initWithRazNetworkRequestType:(RazNetworkRequestType)networkRequestType paramaterDictionary:(NSDictionary *)paramDictionary andConnection:(RazConnection *)razConnection {
    self = [super init];
    
    if(self) {
        self.requestType = networkRequestType;
        self.parameterDictionary = paramDictionary;
        self.numberOfRequestAttempts = 0;
        self.connection = razConnection;
    }
    
    return self;
}

- (RazNetworkRequestType)getRequestType {
    return _requestType;
}

- (NSDictionary *)getParameterDictionary {
    return _parameterDictionary;
}

- (void) timeoutCheck {
    self.numberOfRequestAttempts++;
    if(self.numberOfRequestAttempts == 3){
        //TODO: request failed too many times
    }
    
    [self.connection addRequest:self];
}

- (void) requestCompletedSuccessfully:(BOOL)success {
    if(success) {
        [self requestSucceeded];
    } else {
        [self requestFailed];
    }
}

- (void) requestSucceeded {
    switch (self.requestType){
        case RazNetworkRequestTypeNickNameCommand: {
            NSLog(@"successfully sent nickname command");
            [self.connection removeRequest:self];            
        } break;
        case RaznetworkRequestTypeFile: {
            NSLog(@"successfuly converted file request to metadata and data requests");
            [self.connection removeRequest:self];            
        } break;
        case RazNetworkRequestTypeFileMetaDataCommand: {
            NSLog(@"successfully sent file metadata command");
            [self.connection removeRequest:self];            
        } break;
        case RazNetworkRequestTypeFileData: {
            NSLog(@"successfully sent file data");
            [self.connection removeRequest:self];            
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            NSLog(@"successfully sent confirmation of file transfer command");
            [self.connection removeRequest:self];            
        } break;
        default: {
            NSLog(@"unknown request type succeeded");
        } break;
    }
}

- (void) requestFailed {
    switch (self.requestType){
        case RazNetworkRequestTypeNickNameCommand: {
            
        } break;
        case RaznetworkRequestTypeFile: {
            
        } break;
        case RazNetworkRequestTypeFileMetaDataCommand: {
            
        } break;
        case RazNetworkRequestTypeFileData: {
            
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            
        } break;
        default: {
            NSLog(@"unknown request type succeeded");
        } break;
    }
}

@end
