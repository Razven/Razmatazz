//
//  RazClientConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-09-04.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazClientConnection.h"

@implementation RazClientConnection

#pragma mark - input processing

- (void) processCommands:(NSArray*)commands {
    for(int i = 0; i < [commands count]; i += 2){
        NSString *command = [commands objectAtIndex:i];
        if([command isEqualToString:kCommandClientNickName]){ //client registered their nickname
            self.connectionName = [commands objectAtIndex:i + 1];
            NSLog(@"received nick name command: %@", self.connectionName);
            [[NSNotificationCenter defaultCenter] postNotificationName:kClientRegisteredNotification object:self];
        } else if([command isEqualToString:kCommandFileTransferCompleted]){
            NSLog(@"client successfully received song");
            [[NSNotificationCenter defaultCenter] postNotificationName:kFileTransferCompletedNotification object:nil];
        }
        else {
            NSLog(@"Unrecognized command: %@", command);
        }
    }
}

#pragma mark - stream delegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    //call super class method for it to take care of most of the work
    [super stream:stream handleEvent:eventCode];
}

#pragma mark - network queue

- (void) performRequest:(RazNetworkRequest*)networkRequest {
    self.activeRequest = networkRequest;
    [self.activeRequest requestIsNowActive];
    
    NSDictionary * paramDictionary = [networkRequest getParameterDictionary];
    
    switch ([networkRequest getRequestType]) {
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
        case RazNetworkRequestTypePlayMusicCommand: {
            NSString * fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            [networkRequest requestCompletedSuccessfully:[self sendPlaySongCommandWithName:fileName]];
        } break;
        default: {
            NSLog(@"attempted to send an unknown request type to client");
        } break;
    }
}

- (BOOL) sendFileMetaDataCommandWithFileName:(NSString*)fileName andFileSize:(NSInteger)fileSize {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%ld%@", kSocketMessageStartTextDelimiter, kCommandFileName, kCommandDelimiter, fileName, kCommandDelimiter ,kCommandFileSize, kCommandDelimiter, (long)fileSize, kSocketMessageEndTextDelimiter];
    return [self sendCommandWithString:msgToSend];
}

- (BOOL) sendPlaySongCommandWithName:(NSString*)songName {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartTextDelimiter, kCommandPlaySong, kCommandDelimiter, songName, kSocketMessageEndTextDelimiter];
    return [self sendCommandWithString:msgToSend];
}

@end
