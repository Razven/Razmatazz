//
//  RazConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazConnection.h"

@interface RazConnection() <NSStreamDelegate>

@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;

@property (nonatomic, assign) BOOL                              inputStreamOpened, outputStreamOpened;
@property (nonatomic, assign) BOOL                              hasSentName;

@property (nonatomic, strong) NSMutableData *                   inputData;
@property (nonatomic, strong) NSMutableData *                   outputData;
@property (nonatomic, assign) NSUInteger                        readBytes;
@property (nonatomic, assign) NSUInteger                        byteIndex;

@end

@implementation RazConnection

- (id) initWithInputStream:(NSInputStream *)inputStream andOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    
    if(self){
        self.inputStream = inputStream;
        self.outputStream = outputStream;
        self.inputData = [NSMutableData data];
        self.hasSentName = NO;
    }
    
    return self;
}

- (void) closeAllStreams {
    if(self.inputStream){
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
    }
    
    if(self.outputStream){
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
}

- (void) openAllStreams {
    if(self.inputStream){
        [self.inputStream  setDelegate:self];
        [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream  open];
    }
    
    if(self.outputStream){
        [self.outputStream setDelegate:self];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream open];
    }
}

#pragma mark - NSStream delegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventOpenCompleted: {
            // TODO: stream opened, do stuff here if neccesary
            if([stream isEqual:self.inputStream]){
                self.inputStreamOpened = YES;
            } else if([stream isEqual:self.outputStream]){
                self.outputStreamOpened = YES;
            }            
            
            if(self.inputStreamOpened && self.outputStreamOpened){
                NSLog(@"New connection!");       
                [[NSNotificationCenter defaultCenter] postNotificationName:kServerConnectedNotification object:self];
            }
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            if(!self.hasSentName){
                [self sendName];
                break;
            }
            if(self.outputData){
                uint8_t *readBytes = (uint8_t *)[self.outputData mutableBytes];
                readBytes += self.byteIndex; // instance variable to move pointer
                int data_len = [self.outputData length];
                unsigned int len = ((data_len - self.byteIndex >= 1024) ?
                                    1024 : (data_len - self.byteIndex));
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                len = [self.outputStream write:(const uint8_t *)buf maxLength:len];
                self.byteIndex += len;
                if(self.byteIndex == data_len){
                    self.outputData = nil;
                }
            }            
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            uint8_t     b[1024];
            NSInteger   bytesRead;
            
            bytesRead = [self.inputStream read:b maxLength:sizeof(b)];
            if (bytesRead <= 0) {
                // Do nothing; we'll handle EOF and error in the
                // NSStreamEventEndEncountered and NSStreamEventErrorOccurred case,
                // respectively.
            } else {
                [self.inputData appendBytes:b length:bytesRead];
                
                NSUInteger indexOfEnd = [self indexOfDelimiter:[kSocketMessageEndDelimiter dataUsingEncoding:NSUTF8StringEncoding] inData:self.inputData];
                
                //we reached the end of the message
                if(indexOfEnd != NSNotFound){
                    // TODO: do something with the data now that we have it all
                    NSLog(@"Finished reading data");
                }
                
                //                else {
                //                        NSUInteger indexOfStart = [self indexOfDelimiter:[kSocketMessageStartDelimiter dataUsingEncoding:NSUTF8StringEncoding] inData:[NSData dataWithBytes:b length:bytesRead]];
//                    
//                    // we found the start delimiter, start appending data to our array
//                    if(indexOfStart != NSNotFound){
//                        self.inputData = [NSMutableData data];
//                        [self.inputData appendBytes:&b[indexOfStart + kSocketMessageStartDelimiter.length] length:bytesRead - indexOfStart];
//                    }
//                }
                NSLog(@"Read %lu bytes of data", (unsigned long)[self.inputData length]);
            }
        } break;
            
        default:
        case NSStreamEventErrorOccurred: {
            NSLog(@"Error occured connecting: %@", [stream streamError]);
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream end encountered");
            
            if([stream isEqual:self.inputStream]){
                self.inputStreamOpened = NO;
            } else if([stream isEqual:self.outputStream]){
                self.outputStreamOpened = NO;
            }
            
            [self closeAllStreams];
            if(self.delegate && [self.delegate respondsToSelector:@selector(connectionDidClose:)]){
                [self.delegate connectionDidClose:self];
            }
        } break;
    }
}

- (NSUInteger)indexOfDelimiter:(NSData*)delimiter inData:(NSData*)data
{
    const char* delimiterBytes = [delimiter bytes];
    const char* dataBytes = [data bytes];
    
    if([data length] < [delimiter length]){
        return NSNotFound;
    }
    
    // walk the length of the buffer, looking for a byte that matches the start
    // of the pattern; we can skip (|needle|-1) bytes at the end, since we can't
    // have a match that's shorter than needle itself
    for (int i = 0; i < [data length] - [delimiter length] + 1; i++) {
        // walk needle's bytes while they still match the bytes of haystack
        // starting at i; if we walk off the end of needle, we found a match
        int j = 0;
        while (j < [delimiter length] && delimiterBytes[j] == dataBytes[i + j]) {
            j++;
        }
        if (j == [delimiter length]) {
            return i;
        }
    }
    return NSNotFound;
}

//- (void)sendFile:(NSMutableData*)data {
//    uint8_t *readBytes = (uint8_t *)[data mutableBytes];
//    uint8_t buf[1024];
//    int len = 1024;
//    NSInteger * bytesWritten;
//    
//    while (YES) {
//        if (len == 0) {
//            break;
//        }
//        if ( [self.outputStream hasSpaceAvailable] ) {
//            (void)strncpy(buf, readBytes, len);
//            readBytes += len;
//            if ([self.outputStream write:(const uint8_t *)buf maxLength:len] == -1) {
//                [self handleError:[self.outputStream streamError]];
//                break;
//            }
//            [bytesWritten setIntValue:[bytesWritten intValue]+len];
//            len = (([data length] - [bytesWritten intValue] >= 1024) ? 1024 :
//                   [data length] - [bytesWritten intValue]);
//        }
//    }
//    NSData *newData = [self.outputStream propertyForKey:
//                       NSStreamDataWrittenToMemoryStreamKey];
//    if (!newData) {
//        NSLog(@"No data written to memory!");
//    } else {
////        [self processData:newData];
//    }
//}

- (void) sendData:(NSData *)data {
    self.outputData = [data mutableCopy];
    
    if([self.outputStream hasSpaceAvailable]){
        [self stream:self.outputStream handleEvent:NSStreamEventHasSpaceAvailable];
        NSLog(@"sending %lu bytes of data to %@", (unsigned long)[self.outputData length], self.connectionName);
    }
}

- (void)sendMessage:(uint8_t*)message
{
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly but in this sample code it's
    // OK to ignore it; if the stream stops transferring data the user is going to have
    // to tap a lot before we fill up our stream buffer (-:
    
    if(!self.outputStream){
        NSLog(@"trying to send a message with a nil output stream");
        return;
    }
    
    NSInteger   bytesWritten = 0;
    
    while(bytesWritten < sizeof(message) && [self.outputStream hasSpaceAvailable]) {
        bytesWritten += [self.outputStream write:&message[bytesWritten] maxLength:(sizeof(message) - bytesWritten)];
    }
    
    NSLog(@"sent %ld bytes of name message", (long)bytesWritten);
    
    self.hasSentName = YES;
}

- (void) sendName {
    //TODO: send actual name of client once we have a way for them to enter their name
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@", kSocketMessageStartDelimiter, @"name:raz", kSocketMessageEndDelimiter];
    
    NSData *someData = [msgToSend dataUsingEncoding:NSUTF8StringEncoding];
    const void *bytes = [someData bytes];
    uint8_t *crypto_data = (uint8_t*)bytes;
    
    [self sendMessage:crypto_data];
}

@end
