//
//  RazConnectionManager.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazConnectionManager.h"
#import "RazConnection.h"
#import "QServer.h"

@interface RazConnectionManager() < QServerDelegate, NSStreamDelegate, RazConnectionDelegate >

@property (nonatomic, strong, readwrite) QServer *              server;
@property (nonatomic, assign, readwrite) NSUInteger             streamOpenCount;
@property (nonatomic, strong)            NSMutableArray*        connectionsArray;

@end

@implementation RazConnectionManager

- (id) init {
    self = [super init];
    
    if(self) {
        self.server = [[QServer alloc] initWithDomain:@"local." type:kRazmatazzBonjourType name:nil preferredPort:44444];
        [self.server setDelegate:self];
        
        self.connectionsArray = [NSMutableArray array];
    }
    
    return self;
}

- (void) startServer {
    [self.server start];
    if(self.server.registeredName != nil){
        // TODO: we've already registered the server, do stuff
    }
}

- (void) registerServerWithName:(NSString*)serverName {
    if([self.server isDeregistered]){
        [self.server reregisterWithName:serverName];
    } else {
        [self.server deregister];
        [self.server reregisterWithName:serverName];
    }
}

- (void) stopServer {
    [self.server stop];
}

- (void) prepareForBackgrounding {
    // TODO: for now, just close all the streams and clear the connections array.
    // could handle this better in the future
    [self closeStreamsAndEmptyConnectionsArray];
       
    [self.server stop];
}

- (void) closeStreamsAndEmptyConnectionsArray {
    for(RazConnection* connection in self.connectionsArray){
        [connection closeAllStreams];
    }
    
    [self.connectionsArray removeAllObjects];
}

- (void) setupForNewParty {
    [self closeStreamsAndEmptyConnectionsArray];
    
    if (self.server.isDeregistered) {
        [self.server reregister];
    }
}

#pragma mark - Stream management

- (void)openStreams
{
    for(RazConnection* connection in self.connectionsArray){
        [connection openAllStreams];
    }
}

- (void)closeStreams {
    for(RazConnection* connection in self.connectionsArray){
        [connection closeAllStreams];
    }
}


#pragma mark - QServer delegate

- (void)serverDidStart:(QServer *)server {
    [[NSNotificationCenter defaultCenter] postNotificationName:kServerStartedNotification object:server];
}

- (void)server:(QServer *)server didStopWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kServerStoppedNotification object:@[server, error]];
}

- (id)server:(QServer *)server connectionForInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    id  result;
    
    RazConnection *connection = [[RazConnection alloc] initWithInputStream:inputStream andOutputStream:outputStream];
    [connection setDelegate:self];
    [connection openAllStreams];
    
    [self.connectionsArray addObject:connection];
    
    result  = connection;    
    return result;
}

- (void)server:(QServer *)server closeConnection:(id)connection {
    [(RazConnection*)connection closeAllStreams];
    [self.connectionsArray removeObject:connection];
}

#pragma mark - RazConnection delegate

- (void)connectionDidClose:(id)connection {
    [self.connectionsArray removeObject:connection];
}

@end
