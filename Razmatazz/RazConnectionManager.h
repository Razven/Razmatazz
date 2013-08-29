//
//  RazConnectionManager.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RazConnection;

@interface RazConnectionManager : NSObject

- (id) init;

- (NSUInteger) getNumberOfActiveClients;

- (void) startServer;
- (void) stopServer;

- (void) closePartyServerStream;

- (void) setServerConnection:(RazConnection*)serverConnection;

- (void) registerServerWithName:(NSString*)name;

- (void) prepareForBackgrounding;

@end
