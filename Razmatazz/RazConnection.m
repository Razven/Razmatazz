//
//  RazConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazConnection.h"

@interface RazConnection() <NSStreamDelegate>

@property (nonatomic, strong, readwrite) NSInputStream *         inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, strong)            NSString *             clientName;

@end

@implementation RazConnection

- (id) initWithInputStream:(NSInputStream *)inputStream andOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    
    if(self){
        self.inputStream = inputStream;
        self.outputStream = outputStream;
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

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventOpenCompleted: {
            // TODO: stream opened, do stuff here if neccesary
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            // do nothing
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            uint8_t     b[4];
            NSInteger   bytesRead;
            
            assert(stream == self.inputStream);
            
            bytesRead = [self.inputStream read:b maxLength:sizeof(b)];
            if (bytesRead <= 0) {
                // Do nothing; we'll handle EOF and error in the
                // NSStreamEventEndEncountered and NSStreamEventErrorOccurred case,
                // respectively.
            } else {
                NSLog(@"Message received:%s", b);
                [self send:b];
                // We received a remote tap update, forward it to the appropriate view
                //TODO: interpret the message we received in our 'b' buffer.
                
                //                if ((b >= 'A') && (b < ('A' + kTapViewControllerTapItemCount))) {
                //                    [self.tapViewController remoteTouchDownOnItem:b - 'A'];
                //                } else if ( (b >= 'a') && (b < ('a' + kTapViewControllerTapItemCount))) {
                //                    [self.tapViewController remoteTouchUpOnItem:b - 'a'];
                //                } else {
                //                    // Ignore the bogus input.  This is important because it allows us
                //                    // to telnet in to the app in order to test its behaviour.  telnet
                //                    // sends all sorts of odd characters, so ignoring them is a good thing.
                //                }
            }
        } break;
            
        default:
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream end encountered");
            
            [self closeAllStreams];
            if(self.delegate && [self.delegate respondsToSelector:@selector(connectionDidClose:)]){
                [self.delegate connectionDidClose:self];
            }
        } break;
    }
}

- (void)send:(uint8_t*)message
{
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly but in this sample code it's
    // OK to ignore it; if the stream stops transferring data the user is going to have
    // to tap a lot before we fill up our stream buffer (-:
    
    if(!self.outputStream){
        NSLog(@"trying to send a message with a nil output stream");
        return;
    }
    
    if ( [self.outputStream hasSpaceAvailable] ) {
        NSInteger   bytesWritten;
        
        bytesWritten = [self.outputStream write:message maxLength:sizeof(message)];
        if (bytesWritten != sizeof(message)) {
            // TODO: didn't manage to send the whole message
        }
    }
}

@end
