//
//  RazConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazConnection.h"

@implementation RazConnection

- (id) initWithInputStream:(NSInputStream *)inputStream andOutputStream:(NSOutputStream *)outputStream {
    self = [super init];
    
    if(self){
        self.inputStream = inputStream;
        self.outputStream = outputStream;
        self.inputData = [NSMutableData data];
        self.requestQueue = [NSMutableArray array];
        self.inputBufferLength = 1024;
    }
    
    return self;
}

#pragma mark - stream management

- (void) closeAllStreams {
    if(self.inputStream){
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        self.inputStreamOpened = NO;
    }
    
    if(self.outputStream){
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
        self.outputStreamOpened = NO;
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
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            if([stream isEqual:self.inputStream]){
                self.inputStreamOpened = YES;
            } else if([stream isEqual:self.outputStream]){
                self.outputStreamOpened = YES;
            }
            
            //subclass handles what they do when both streams are successfully opened
        } break;

        case NSStreamEventHasSpaceAvailable: {
            if(self.activeRequest && self.outputData){
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
                    self.byteIndex = 0;
                    [self.activeRequest requestCompletedSuccessfully:YES];
                    
                    //TODO: inform other parts of the app that we successfully sent the file through
                    // when implementing the output queue, this would be a good time to inform the activeOutputRequest
                    // that it completed successfully
                }
            } else if(!self.activeRequest){
                [self processNetworkQueue];
            }
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            // TODO: implement dynamic buffer length based on state of connection
            // i.e if we're expecting a file, increase size of buffer,
            // if we're expecting a command, a smaller buffer will suffice
            // this is to reduce the work done when attempting to parse input for commands
            uint8_t     buffer[self.inputBufferLength];
            NSInteger   bytesRead;
            bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
            
            if (bytesRead > 0) {
                [self.inputData appendBytes:buffer length:bytesRead];
                if(!self.isFileTransferInProgress){
                    //TODO: this is kinda heavy too
                    NSUInteger indexOfEnd = [self indexOfDelimiter:kSocketMessageEndTextDelimiter inData:self.inputData];
                    NSLog(@"Read %lu bytes of data", (unsigned long)[self.inputData length]);
                    //we reached the end of the message
                    if(indexOfEnd != NSNotFound){
                        [self parseInputData];
                    }
                } else {
                    if([self.inputData length] >= self.fileSize){
                        NSLog(@"Read %lu bytes of data", (unsigned long)[self.inputData length]);
                        //TODO: implement incoming network queue and tell the activerequest it's finished which will trigger this
                        //rather than doing it manually
                        
                        NSDictionary * paramDictionary = @{kNetworkParameterFileName : self.fileName};
                        RazNetworkRequest* confirmationOfFileTransferRequest = [[RazNetworkRequest alloc] initWithRazNetworkRequestType:RazNetworkRequestTypeConfirmationOfFileTransferCommand paramaterDictionary:paramDictionary andConnection:self];
                        [self addRequest:confirmationOfFileTransferRequest];
                        
                        // file transfer complete
                        [self processFileData];
                    }
                }
            }
        } break;
            
        default:
        case NSStreamEventErrorOccurred: {
            NSLog(@"Error occured connecting: %@", [stream streamError]);
            
            [self closeAllStreams];
            if(self.delegate && [self.delegate respondsToSelector:@selector(connectionDidClose:)]){
                [self.delegate connectionDidClose:self];
            }
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream end encountered");
            
            //if one stream is down, we might as well close them all because we need both streams up
            //to operate normally.
            
            [self closeAllStreams];
            if(self.delegate && [self.delegate respondsToSelector:@selector(connectionDidClose:)]){
                [self.delegate connectionDidClose:self];
            }
        } break;
    }
}

#pragma mark - input processing

- (void) processCommands:(NSArray*)commands {
    // implemented by subclass
}

- (NSString *) getNSStringFromCommandBytes:(const void*)commandBytes {
    NSString * returnString;
    for(int i = [self.inputData length]; i > 0; i--) {
        returnString = [[NSString alloc] initWithBytes:commandBytes length:i encoding:NSUTF8StringEncoding];
        //TODO: this is absolutely filthy
        if(returnString) {
            return returnString;
        }
    }
    
    return returnString;
}

//TODO: this whole function is heavy and needs revision
- (void) parseInputData {    
    BOOL missingPartOfMessage = NO;
    
    if([self.inputData length] < kSocketMessageStartTextDelimiter.length + kSocketMessageEndTextDelimiter.length){
        NSLog(@"inputData too short to parse");
        return;
    }
    
    NSMutableString * fullMessage = [[self getNSStringFromCommandBytes:[self.inputData bytes]] mutableCopy];
    NSLog(@"full message: %@", fullMessage);
    NSInteger startIndex = [fullMessage rangeOfString:kSocketMessageStartTextDelimiter].location;
    NSInteger endIndex = 0;
    
    NSArray * startDelimiterSplit = [fullMessage componentsSeparatedByString:kSocketMessageStartTextDelimiter];
    
    for(int i = 1; i < [startDelimiterSplit count]; i++){
        NSArray * endDelimiterSplit = [[startDelimiterSplit objectAtIndex:i] componentsSeparatedByString:kSocketMessageEndTextDelimiter];
        if(i == [startDelimiterSplit count] - 1){
            NSInteger localEndIndex = [[startDelimiterSplit objectAtIndex:i] rangeOfString:kSocketMessageEndTextDelimiter].location;
            
            //the data would have to look something like: name:Razzle Dazzle7539512684razmat
            //notice the end delimiter is cut off, we haven't read it all yet
            if(localEndIndex == NSNotFound){
                missingPartOfMessage = YES;
                break;
            }
            
            endIndex += localEndIndex;
        } else {
            endIndex += [[startDelimiterSplit objectAtIndex:i] length];
        }
        
        [self processCommands:[[endDelimiterSplit objectAtIndex:0] componentsSeparatedByString:kCommandDelimiter]];
        
        if(self.fileName && self.fileSize > 0){
            // we have all the info for a file transfer, so the next thing
            // coming down the pipe will be our file.
            self.isFileTransferInProgress = YES;
        }
    }
    
    //we need to add in the length of all the start delimiters
    endIndex += startIndex + (kSocketMessageStartTextDelimiter.length * ([startDelimiterSplit count] - 1));
    
    // if part of message is missing (only possible case is the end) then keep the start delimiter as part of the message so we can parse everything again when we get the full end
    NSRange processedRange = {missingPartOfMessage ? startIndex + kSocketMessageStartTextDelimiter.length : startIndex, endIndex + kSocketMessageEndTextDelimiter.length - startIndex};
    [self.inputData replaceBytesInRange:processedRange withBytes:NULL length:0];
}

- (void) processFileData {
    NSData * fileData = [self.inputData subdataWithRange:(NSRange){0, self.fileSize}];
    NSString * filePath = [APPLICATION_SONGS_DIRECTORY stringByAppendingPathComponent:self.fileName];
    
    NSLog(@"File data received: %@", fileData);
    
    BOOL fileSaved;
    NSError * error;
    fileSaved = [fileData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    
    NSLog(@"first 20 bytes received: %@", [fileData subdataWithRange:(NSRange){0,20}]);
    NSLog(@"last 20 bytes received: %@", [fileData subdataWithRange:(NSRange){(unsigned long)[fileData length] - 20,20}]);
    
    if(!fileSaved){
        //TODO: file didn't save, do something
        NSLog(@"File \"%@\" received but not saved!", self.fileName);
    } else {
        // file successfully saved and everyone's happy
        NSLog(@"transfer of song %@ was successful", self.fileName);
        [[NSNotificationCenter defaultCenter] postNotificationName:kFileTransferCompletedNotification object:self.fileName];
        self.inputData = [[self.inputData subdataWithRange:(NSRange){self.fileSize, (unsigned long)[self.inputData length] - self.fileSize}] mutableCopy];
        self.fileName = nil;
        self.fileSize = 0;
        self.isFileTransferInProgress = NO;
        
        if([self indexOfDelimiter:kSocketMessageEndTextDelimiter inData:self.inputData] != NSNotFound){
            [self parseInputData];
        }
        
        
    }
}

//TODO: implement a 'startindex' so we don't have to start from the beginning of the chunk of data each time. This is very heavy.
- (NSUInteger)indexOfDelimiter:(NSString*)delimiter inData:(NSData*)data {
    if((unsigned long)[data length] < [delimiter length]){ // the length of our delimiter is longer than that of our data
                                                           // there's no way the delimiter can be found in the data.
        return NSNotFound;
    } else {
        const char* delimiterBytes = [delimiter UTF8String];
        const char* dataBytes = [data bytes];
        int numMatching;
        
        for(int i = 0; i < (unsigned long)[data length]; i++){
            numMatching = 0;
            for(int j = 0; j < [delimiter length]; j++){
                if(delimiterBytes[j] == dataBytes[j + i]){
                    numMatching++;
                }
            }
            
            if(numMatching == [delimiter length]){ // match found at index i
                return i;
            }
        }
        
        //looped through everything, match not found
        return NSNotFound;
    }
}

#pragma mark - network request section

- (void) performRequest:(RazNetworkRequest*)networkRequest {
    // implemented by subclass
}

- (void) sendData:(NSData *)data {
    self.outputData = [data mutableCopy];
    
    if([self.outputStream hasSpaceAvailable]){
        [self stream:self.outputStream handleEvent:NSStreamEventHasSpaceAvailable];
        NSLog(@"sending %lu bytes to %@", (unsigned long)[self.outputData length], self.connectionName ? self.connectionName : @"unregistered");
    } else {
        //we set the output data, so as soon as we get the stream delegate call telling us the output queue has space,
        //our method will take care of the rest
    }
}

- (BOOL)sendMessage:(uint8_t*)message withLength:(NSUInteger)length {
    if(!self.outputStream){
        NSLog(@"trying to send a message with a nil output stream");
        return NO;
    }
    
    NSInteger bytesWritten = 0;
    //TODO: handle case where we haven't sent the full message and the stream doesn't have space available
    while(bytesWritten < length && [self.outputStream hasSpaceAvailable]) {
        bytesWritten += [self.outputStream write:&message[bytesWritten] maxLength:(length - bytesWritten)];
    }
    
    NSLog(@"sent a %ld byte long message", (long)bytesWritten);
    return bytesWritten == length;
}

- (BOOL) sendCommandWithString:(NSString*) command {
    NSData *someData = [command dataUsingEncoding:NSUTF8StringEncoding];
    const void *bytes = [someData bytes];
    uint8_t *crypto_data = (uint8_t*)bytes;
    
    return [self sendMessage:crypto_data withLength:[someData length]];
}

- (void) addRequest:(RazNetworkRequest*) networkRequest atIndex:(NSInteger)index {
    [self.requestQueue insertObject:networkRequest atIndex:index];
    NSLog(@"requestQueue has %lu objects in it", (unsigned long)[self.requestQueue count]);
    [self processNetworkQueue];
}

- (void) addRequest:(RazNetworkRequest *)networkRequest {
    [self.requestQueue addObject:networkRequest];
    NSLog(@"requestQueue has %lu objects in it", (unsigned long)[self.requestQueue count]);
    [self processNetworkQueue];
}

- (void) removeRequest:(RazNetworkRequest*) networkRequest {
    if(self.activeRequest == networkRequest){
        self.activeRequest = nil;
    }
    
    [self.requestQueue removeObject:networkRequest];
    NSLog(@"requestQueue has %lu objects in it", (unsigned long)[self.requestQueue count]);
    [self processNetworkQueue];
}

- (void) cancelSongRequests {
    for(RazNetworkRequest * networkRequest in self.requestQueue){
        RazNetworkRequestType requestType = [networkRequest getRequestType];
        if(requestType == RaznetworkRequestTypeFile || requestType == RazNetworkRequestTypeFileMetaDataCommand || requestType == RazNetworkRequestTypeFileData){
            //let's avoid removing requests from the queue which have already been started
            if(self.activeRequest != networkRequest){
                [self removeRequest:networkRequest];
            }
        }
    }
}

- (void) resetVariables {
    self.activeRequest = nil;
    self.outputData = nil;
    self.byteIndex = 0;
    self.fileName = nil;
    self.fileSize = 0;
}

- (void) retryActiveRequest {
    NSLog(@"retrying request of type %u now", (RazNetworkRequestType)[self.activeRequest getRequestType]);
    [self resetVariables];
    [self processNetworkQueue];
}

- (void) retryRequestLater:(RazNetworkRequest*) networkRequest {
    NSLog(@"retrying request of type %u later", (RazNetworkRequestType)[networkRequest getRequestType]);
    [self resetVariables];
    [self.requestQueue removeObject:networkRequest];
    [self.requestQueue addObject:networkRequest];
    [self processNetworkQueue];
}





#pragma mark - queue processing

- (void)processNetworkQueue {
    if(self.activeRequest || ![self.outputStream hasSpaceAvailable]){
        // do nothing, a request is already in the process of sending
        // or the output stream isn't ready to send stuff yet
    } else {
        if([self.requestQueue count] > 0){
            [self performRequest:[self.requestQueue objectAtIndex:0]];
        } else {
            // no more requests to be made. Queue is empty :)
        }
    }
}

@end
