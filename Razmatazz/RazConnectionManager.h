//
//  RazConnectionManager.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RazServerConnection;

@interface RazConnectionManager : NSObject

- (id) init;

- (NSUInteger) getNumberOfActiveClients;
- (NSArray*) getArrayOfClientNames;

- (void) startServer;
- (void) stopServer;

- (void) closePartyServerStream;

- (void) broadcastSongFromURL:(NSURL*)songPath;
- (void) cancelSongBroadcast;
- (void) sendPlayMusicRequestWithSongName:(NSString*)songName;

- (void) setServerConnection:(RazServerConnection*)serverConnection;

- (void) registerServerWithName:(NSString*)name;

- (void) prepareForBackgrounding;

@end
