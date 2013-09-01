//
//  RazConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-28.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazConnection.h"
#import "RazNetworkRequest.h"

@interface RazConnection() <NSStreamDelegate>

@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;

@property (nonatomic, assign) BOOL                              inputStreamOpened, outputStreamOpened;
@property (nonatomic, assign) BOOL                              isFileTransferInProgress;

@property (nonatomic, assign) NSInteger                         fileSize;
@property (nonatomic, strong) NSString *                        fileName;

@property (nonatomic, strong) NSMutableData *                   inputData;
@property (nonatomic, strong) NSMutableData *                   outputData;
@property (nonatomic, assign) NSUInteger                        readBytes;
@property (nonatomic, assign) NSUInteger                        byteIndex;

@property (nonatomic, strong) NSMutableArray *                  requestQueue;
@property (nonatomic, weak) RazNetworkRequest *                 activeRequest;

@property (nonatomic, assign) int                               inputBufferLength;

@end

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
                
                // if we're connected to a server, send it our nickname
                if(self.connectionType == RazConnectionTypeServer){
                    RazNetworkRequest * nickNameRequest = [[RazNetworkRequest alloc] initWithRazNetworkRequestType:RazNetworkRequestTypeNickNameCommand paramaterDictionary:nil andConnection:self];
                    [self addRequest:nickNameRequest];
                }
            }
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
                    NSUInteger indexOfEnd = [self indexOfDelimiter:kSocketMessageEndDelimiter inData:[[NSString alloc] initWithData:self.inputData encoding:NSUTF8StringEncoding]];
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
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"Stream end encountered");
            
            //TODO: this only gets called once. Take care of our variables somehow
            
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

#pragma mark - input processing

- (void) processCommands:(NSArray*)commands {
    for(int i = 0; i < [commands count]; i += 2){
        NSString *command = [commands objectAtIndex:i];
        if([command isEqualToString:kCommandClientNickName]){ //client registered their nickname
            self.connectionName = [commands objectAtIndex:i + 1];
            NSLog(@"received nick name command: %@", self.connectionName);
            [[NSNotificationCenter defaultCenter] postNotificationName:kClientRegisteredNotification object:self];
        } else if ([command isEqualToString:kCommandFileName]){ //file name was sent through in preparation for a file to be sent
            self.fileName = [commands objectAtIndex:i + 1];
            NSLog(@"received file name command: %@", self.fileName);
        } else if([command isEqualToString:kCommandFileSize]){ //file size was sent through in preparation for a file to be sent
            NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            self.fileSize = [formatter numberFromString:[commands objectAtIndex:i + 1]].integerValue;
            NSLog(@"received file size command: %ld", (long)self.fileSize);
        } else if([command isEqualToString:kCommandFileTransferCompleted]){
            NSLog(@"%@ successfully received the song: %@", self.connectionName, [commands objectAtIndex:i + 1]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kFileTransferCompletedNotification object:self];
        } else if([command isEqualToString:kCommandPlaySong]){
            NSLog(@"received play song command");
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlaySongNotification object:[commands objectAtIndex:i + 1]];
        }
        else {
            NSLog(@"Unrecognized command: %@", command);
        }
    }
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
    
    if([self.inputData length] < kSocketMessageStartDelimiter.length + kSocketMessageEndDelimiter.length){
        NSLog(@"inputData too short to parse");
        return;
    }
    
    NSMutableString * fullMessage = [[self getNSStringFromCommandBytes:[self.inputData bytes]] mutableCopy];
    NSLog(@"full message: %@", fullMessage);
    NSInteger startIndex = [fullMessage rangeOfString:kSocketMessageStartDelimiter].location;
    NSInteger endIndex = 0;
    
    NSArray * startDelimiterSplit = [fullMessage componentsSeparatedByString:kSocketMessageStartDelimiter];
    
    for(int i = 1; i < [startDelimiterSplit count]; i++){
        NSArray * endDelimiterSplit = [[startDelimiterSplit objectAtIndex:i] componentsSeparatedByString:kSocketMessageEndDelimiter];
        if(i == [startDelimiterSplit count] - 1){
            NSInteger localEndIndex = [[startDelimiterSplit objectAtIndex:i] rangeOfString:kSocketMessageEndDelimiter].location;
            
            //the data would have to look something like: name:Razzle Dazzle7539512684razmat
            //notice the end delimiter is cut off, we haven't read it all yet
            if(localEndIndex == NSNotFound){
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
    
    endIndex += startIndex + kSocketMessageStartDelimiter.length;
    
    // if part of message is missing (only possible case is the end) then keep the start delimiter as part of the message so we can parse everything again when we get the full end
    NSRange processedRange = {missingPartOfMessage ? startIndex + kSocketMessageStartDelimiter.length : startIndex, endIndex + kSocketMessageEndDelimiter.length - startIndex};
    [self.inputData replaceBytesInRange:processedRange withBytes:NULL length:0];
}

- (void) processFileData {
    NSData * fileData = [self.inputData subdataWithRange:(NSRange){0, self.fileSize}];
    NSString * filePath = [APPLICATION_SONGS_DIRECTORY stringByAppendingPathComponent:self.fileName];
    
    BOOL fileSaved = [fileData writeToFile:filePath atomically:YES];
    
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
    }
}

- (NSUInteger)indexOfDelimiter:(NSString*)delimiter inData:(NSString*)data {
    NSRange range = [data rangeOfString:delimiter];
    
    return range.location;
}

#pragma mark - network request section

- (void) performRequest:(RazNetworkRequest*)networkRequest {
    self.activeRequest = networkRequest;
    
    NSDictionary * paramDictionary = [networkRequest getParameterDictionary];
    
    switch ([networkRequest getRequestType]) {
        case RazNetworkRequestTypeNickNameCommand:{
            [networkRequest requestCompletedSuccessfully:[self sendNickNameCommand]];
        } break;        
        case RaznetworkRequestTypeFile: {
            NSData *       fileData = [paramDictionary objectForKey:kNetworkParamaterFileData];
            NSString *     fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            
            NSDictionary * fileDataParamDictionary = @{kNetworkParamaterFileData : fileData};
            NSDictionary * fileMetaDataParamDictionary = @{kNetworkParameterFileName : fileName, kNetworkParamaterFileSize : [NSNumber numberWithUnsignedInt:[fileData length]]};
            
            // QUEUE NOW: [fileNetworkRequest] ... [other requests]
            // activeRequest == fileNetworkRequest ** this means our observer WILL NOT process the queue as we modify it
            
            RazNetworkRequest * fileMetaDataNetworkRequest = [[RazNetworkRequest alloc] initWithRazNetworkRequestType:RazNetworkRequestTypeFileMetaDataCommand paramaterDictionary:fileMetaDataParamDictionary andConnection:self];
            [self addRequest:fileMetaDataNetworkRequest atIndex:0];
            
            RazNetworkRequest * fileDataNetworkRequest = [[RazNetworkRequest alloc] initWithRazNetworkRequestType:RazNetworkRequestTypeFileData paramaterDictionary:fileDataParamDictionary andConnection:self];
            [self addRequest:fileDataNetworkRequest atIndex:1];
            
            // QUEUE NOW: [fileMetaDataNetworkRequest][fileDataNetworkRequest][fileNetworkRequest]....[other requests]
            
            // this sets the activeNetwork to nil and removes us from the queue,
            // which will set off the observer and process the queue accordingly
            [networkRequest requestCompletedSuccessfully:YES];
            
            // activeRequest == nil ** this means our observer WILL process the queue
            // QUEUE NOW: [fileMetaDataNetworkRequest][fileDataNetworkRequest]....[other requests]
        } break;
        case RazNetworkRequestTypeFileMetaDataCommand: {
            NSString *     fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            NSNumber *     fileSize = [paramDictionary objectForKey:kNetworkParamaterFileSize];
            
            [networkRequest requestCompletedSuccessfully:[self sendFileMetaDataCommandWithFileName:fileName andFileSize:fileSize.integerValue]];
        } break;
        case RazNetworkRequestTypeFileData: {
            NSData *    fileData = [paramDictionary objectForKey:kNetworkParamaterFileData];
            
            [self sendData:fileData];
        } break;
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            NSString * fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            [networkRequest requestCompletedSuccessfully:[self sendComfirmationOfFileTransferWithName:fileName]];
        } break;
        case RazNetworkRequestTypePlayMusicCommand: {
            NSString * fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            [networkRequest requestCompletedSuccessfully:[self sendPlaySongCommandWithName:fileName]];
        } break;
        default: {
            NSLog(@"attempted to send an unknown request type");
        } break;
    }    
}

- (void) sendData:(NSData *)data {
    self.outputData = [data mutableCopy];
    
    if([self.outputStream hasSpaceAvailable]){
        [self stream:self.outputStream handleEvent:NSStreamEventHasSpaceAvailable];
        NSLog(@"sending %lu bytes to %@", (unsigned long)[self.outputData length], self.connectionName ? self.connectionName : @"unregistered client");
    } else {
        //TODO: handle case where output stream doesn't have available space
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

- (void) sendFile:(NSData*)fileData withName:(NSString*)fileName {
    [self sendFileMetaDataCommandWithFileName:fileName andFileSize:(unsigned long)[fileData length]];
    [self sendData:fileData];
}

- (BOOL) sendNickNameCommand {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartDelimiter, kCommandClientNickName, kCommandDelimiter, [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsClientNickName], kSocketMessageEndDelimiter];
    return [self sendCommandWithString:msgToSend];
}

- (BOOL) sendFileMetaDataCommandWithFileName:(NSString*)fileName andFileSize:(NSInteger)fileSize {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%ld%@", kSocketMessageStartDelimiter, kCommandFileName, kCommandDelimiter, fileName, kCommandDelimiter ,kCommandFileSize, kCommandDelimiter, (long)fileSize, kSocketMessageEndDelimiter];
    return [self sendCommandWithString:msgToSend];
}

- (BOOL) sendComfirmationOfFileTransferWithName:(NSString*)fileName {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartDelimiter, kCommandFileTransferCompleted, kCommandDelimiter, fileName, kSocketMessageEndDelimiter];
    return [self sendCommandWithString:msgToSend];
}

- (BOOL) sendPlaySongCommandWithName:(NSString*)songName {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartDelimiter, kCommandPlaySong, kCommandDelimiter, songName, kSocketMessageEndDelimiter];
    return [self sendCommandWithString:msgToSend];
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
