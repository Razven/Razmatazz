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
@property (nonatomic, strong)            NSMutableArray *       connectionsArray;
@property (nonatomic, strong)            RazConnection *        serverConnection;

@end

@implementation RazConnectionManager

- (id) init {
    self = [super init];
    
    if(self) {
        self.server = [[QServer alloc] initWithDomain:@"local." type:kRazmatazzBonjourType name:nil preferredPort:44444];
        [self.server setDelegate:self];
        
        self.connectionsArray = [NSMutableArray array];
        
        self.serverConnection = nil;
    }
    
    return self;
}

- (NSUInteger) getNumberOfActiveClients {
    return [self.connectionsArray count];
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
    
    if(self.serverConnection){
        [self.serverConnection closeAllStreams];
    }
    
    self.serverConnection = nil;
}

- (void) setupForNewParty {
    [self closeStreamsAndEmptyConnectionsArray];
    
    if (self.server.isDeregistered) {
        [self.server reregister];
    }
}

- (void) setServerConnection:(id)serverConnection {    
    _serverConnection = serverConnection;
    [self.serverConnection setDelegate:self];
}

- (void) broadcastSongFromURL:(NSURL *)songPath {
    NSString *  path = [songPath path];
    NSData *    data = [[NSFileManager defaultManager] contentsAtPath:path];
    
    if(data && [data length] > 0){
        for(RazConnection * client in self.connectionsArray){
            [client sendData:data];
        }
    }    
}

#pragma mark - Stream management

- (void)openClientStreams
{
    for(RazConnection* connection in self.connectionsArray){
        [connection openAllStreams];
    }
}

- (void)closeClientStreams {
    for(RazConnection* connection in self.connectionsArray){
        [connection closeAllStreams];
    }
}

- (void)openPartyServerStream {
    [self.serverConnection openAllStreams];
}

- (void)closePartyServerStream {
    [self.serverConnection closeAllStreams];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kClientConnectedNotification object:connection];
    return result;
}

- (void)server:(QServer *)server closeConnection:(id)connection {
    [(RazConnection*)connection closeAllStreams];
    [self.connectionsArray removeObject:connection];
}

#pragma mark - RazConnection delegate

- (void)connectionDidClose:(id)connection {
    if(self.serverConnection && [connection isEqual:self.serverConnection]){
        [[NSNotificationCenter defaultCenter] postNotificationName:kServerDisconnectedNotification object:connection];
//        self.serverConnection = nil;
    } else {
        [self.connectionsArray removeObject:connection];
        [[NSNotificationCenter defaultCenter] postNotificationName:kClientDisconnectedNotification object:connection];
    }
}

@end
