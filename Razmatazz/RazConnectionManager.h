//
//  RazConnectionManager.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RazConnectionManager : NSObject

- (id) init;

- (NSUInteger) getNumberOfActiveConnections;

- (void) startServer;
- (void) stopServer;

- (void) registerServerWithName:(NSString*)name;

- (void) prepareForBackgrounding;

@end
