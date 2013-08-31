//
//  RazConnection.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RazNetworkRequest;

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
@property (nonatomic, assign) RazConnectionType                 connectionType;

- (id) initWithInputStream:(NSInputStream*)inputStream andOutputStream:(NSOutputStream*)outputStream;

- (void) closeAllStreams;
- (void) openAllStreams;

- (void) sendFile:(NSData*)fileData withName:(NSString*)fileName;

- (void) addRequest:(RazNetworkRequest*)networkRequest;
- (void) removeRequest:(RazNetworkRequest*)networkRequest;

@end
