//
//  RazConnection.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RazNetworkRequest.h"

@protocol RazConnectionDelegate <NSObject>

@required
- (void)connectionDidClose:(id)connection;

@end

typedef enum {
    RazConnectionTypeServer,
    RazConnectionTypeClient
} RazConnectionType;

@interface RazConnection : NSObject

@property (nonatomic, strong) id<RazConnectionDelegate>         delegate;
@property (nonatomic, strong) NSString *                        connectionName;

- (id) initWithInputStream:(NSInputStream*)inputStream andOutputStream:(NSOutputStream*)outputStream;

- (void) closeAllStreams;
- (void) openAllStreams;

- (void) addRequest:(RazNetworkRequest*)networkRequest;
- (void) removeRequest:(RazNetworkRequest*)networkRequest;

- (void) retryActiveRequest;
- (void) retryRequestLater:(RazNetworkRequest*) networkRequest;
- (void) cancelSongRequests;

@end

//for subclassing
@interface RazConnection() <NSStreamDelegate>

@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;

@property (nonatomic, assign) BOOL                              inputStreamOpened, outputStreamOpened;
@property (nonatomic, assign) BOOL                              isFileTransferInProgress;

@property (nonatomic, assign) NSInteger                         fileSize;
@property (nonatomic, strong) NSString *                        fileName;

@property (nonatomic, strong) NSMutableData *                   inputData;
@property (nonatomic, strong) NSMutableData *                   outputData;
@property (nonatomic, assign) NSUInteger                        readBytes;
@property (nonatomic, assign) NSUInteger                        byteIndex;

@property (nonatomic, strong) NSMutableArray *                  requestQueue;
@property (nonatomic, weak) RazNetworkRequest *                 activeRequest;

@property (nonatomic, assign) int                               inputBufferLength;

- (void) addRequest:(RazNetworkRequest*) networkRequest atIndex:(NSInteger)index;
- (void) addRequest:(RazNetworkRequest *)networkRequest;
- (void) removeRequest:(RazNetworkRequest*) networkRequest;
- (BOOL) sendCommandWithString:(NSString*) command;
- (void) sendData:(NSData*)data;

@end
