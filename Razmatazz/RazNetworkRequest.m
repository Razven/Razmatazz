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
            [self.connection removeRequest:self];
        } break;
        case RaznetworkRequestTypeFile: {
            [self.connection removeRequest:self];
        } break;
        case RazNetworkRequestTypeFileMetaDataCommand: {
            [self.connection removeRequest:self];
        } break;
        case RazNetworkRequestTypeFileData: {
            [self.connection removeRequest:self];
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            [self.connection removeRequest:self];
        } break;
        default: {
            NSLog(@"unknown request type succeeded");
        } break;
    }
}

- (void) requestFailed {
    
}

@end
