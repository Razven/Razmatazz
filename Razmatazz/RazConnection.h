//
//  RazConnection.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RazConnectionDelegate <NSObject>

@required
- (void)connectionDidClose:(id)connection;

@end

@interface RazConnection : NSObject

@property (nonatomic, strong) id<RazConnectionDelegate>         delegate;
@property (nonatomic, strong) NSString *                        connectionName;

- (id) initWithInputStream:(NSInputStream*)inputStream andOutputStream:(NSOutputStream*)outputStream;

- (void) closeAllStreams;
- (void) openAllStreams;

@end
