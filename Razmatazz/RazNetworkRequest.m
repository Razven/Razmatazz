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

- (void) dealloc {
    if(self.timeoutTimer){
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (RazNetworkRequestType)getRequestType {
    return _requestType;
}

- (NSDictionary *)getParameterDictionary {
    return _parameterDictionary;
}

- (void) stopTimeoutTimer {
    if(self.timeoutTimer){
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void) requestCompletedSuccessfully:(BOOL)success {
    // we got some sort of response so stop the timeout timer from running
    [self stopTimeoutTimer];
    
    if(success) {
        [self requestSucceeded];
    } else {
        [self requestFailed];
    }
}

- (void) requestIsNowActive {
    self.timeoutTimer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(requestFailed) userInfo:nil repeats:NO];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:kFileSuccessfullySentNotification object:nil];
            [self.connection removeRequest:self];
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            NSLog(@"successfully sent confirmation of file transfer command");
            [self.connection removeRequest:self];            
        } break;
        case RazNetworkRequestTypePlayMusicCommand: {
            NSLog(@"successfully sent play music command");
            [self.connection removeRequest:self];
        } break;
        default: {
            NSLog(@"unknown request type succeeded");
        } break;
    }
}

- (void) requestFailed {
    self.numberOfRequestAttempts++;
    NSLog(@"request of type %u failed.", (RazConnectionType)self.requestType);
    
    if(self.numberOfRequestAttempts == 3){
        //TODO: failed too many times. Do something.
        NSLog(@"connection of type: %u failed too many times. Disconnecting.", (RazNetworkRequestType)self.requestType);
        [self.connection closeAllStreams];        
    } else {
        
    }
    
    switch (self.requestType){
        case RazNetworkRequestTypeNickNameCommand: {
            [self.connection retryRequestLater:self];
        } break;
        case RaznetworkRequestTypeFile: {
            [self.connection retryRequestLater:self];
        } break;
        case RazNetworkRequestTypeFileMetaDataCommand: {
            [self.connection retryActiveRequest];
        } break;
        case RazNetworkRequestTypeFileData: {
            [self.connection retryActiveRequest];
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            [self.connection retryRequestLater:self];
        } break;
        case RazNetworkRequestTypePlayMusicCommand: {
            [self.connection retryActiveRequest];
        } break;
        default: {
            NSLog(@"unknown request type succeeded");
        } break;
    }
}

@end
