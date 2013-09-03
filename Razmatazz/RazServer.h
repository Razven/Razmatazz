//
//  RazServer.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-09-03.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RazServer;

@protocol RazServerDelegate <NSObject>

@optional

- (void)serverDidStart:(RazServer *)server;
- (void)server:(RazServer *)server didStopWithError:(NSError *)error;

// implement only one of these two
- (id)server:(RazServer *)server connectionForSocket:(int)fd;
- (id)server:(RazServer *)server connectionForInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

- (void)server:(RazServer *)server closeConnection:(id)connection;
- (void)server:(RazServer *)server logWithFormat:(NSString *)format arguments:(va_list)argList;

@end

@interface RazServer : NSObject

@property (nonatomic, assign, readonly) NSUInteger              preferredPort;
@property (nonatomic, strong)           NSString *              partyName;
    
@property (nonatomic, copy, readonly)   NSSet *                 connections;
@property (nonatomic, copy, readonly)   NSSet *                 runLoopModes;
@property (nonatomic, assign)           BOOL                    disableIPv6;

@property (nonatomic, weak)             id<RazServerDelegate>   delegate;

@property (nonatomic, assign, readonly, getter=isStarted) BOOL  started;
@property (nonatomic, assign, readonly) NSUInteger              registeredPort;

- (id) initWithPreferredPort:(NSUInteger)preferredPort andPartyName:(NSString*)partyName;
- (id) initWithPreferredPort:(NSUInteger)preferredPort;

- (BOOL) isStarted;

- (void)start;

- (void)stop;

#pragma mark - Connections

- (void)closeOneConnection:(id)connection;

- (void)closeAllConnections;

#pragma mark * Run Loop Modes

// You can't add or remove run loop modes while the server is running.

- (void)addRunLoopMode:(NSString *)modeToAdd;
- (void)removeRunLoopMode:(NSString *)modeToRemove;

- (void)scheduleInRunLoopModesInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;
- (void)removeFromRunLoopModesInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream;

@end
