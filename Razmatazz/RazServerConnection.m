//
//  RazServerConnection.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-09-04.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazServerConnection.h"

@implementation RazServerConnection

#pragma mark - Input processing

- (void) processCommands:(NSArray*)commands {
    for(int i = 0; i < [commands count]; i += 2){
        NSString *command = [commands objectAtIndex:i];
        if ([command isEqualToString:kCommandFileName]){ //file name was sent through in preparation for a file to be sent
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

#pragma mark - NSStream delegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
    //call super class method for it to take care of most of the work
    [super stream:stream handleEvent:eventCode];
    
    switch(eventCode) {
        case NSStreamEventOpenCompleted: {
            if(self.inputStreamOpened && self.outputStreamOpened){
                NSLog(@"New server connection!");
                [[NSNotificationCenter defaultCenter] postNotificationName:kServerConnectedNotification object:self];
                
                // send server our nickname
                RazNetworkRequest * nickNameRequest = [[RazNetworkRequest alloc] initWithRazNetworkRequestType:RazNetworkRequestTypeNickNameCommand paramaterDictionary:nil andConnection:self];
                [self addRequest:nickNameRequest];
            }
        } break;
        default:
            break;
    }
}

#pragma mark - network queue

- (void) performRequest:(RazNetworkRequest*)networkRequest {
    
    NSDictionary * paramDictionary = [networkRequest getParameterDictionary];
    
    switch ([networkRequest getRequestType]) {
        case RazNetworkRequestTypeNickNameCommand:{
            [networkRequest requestCompletedSuccessfully:[self sendNickNameCommand]];
        } break;            
        case RazNetworkRequestTypeConfirmationOfFileTransferCommand: {
            NSString * fileName = [paramDictionary objectForKey:kNetworkParameterFileName];
            [networkRequest requestCompletedSuccessfully:[self sendComfirmationOfFileTransferWithName:fileName]];
        } break;
        default: {
            NSLog(@"attempted to send an unknown request type to server");
        } break;
    }
}

- (BOOL) sendNickNameCommand {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartTextDelimiter, kCommandClientNickName, kCommandDelimiter, [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsClientNickName], kSocketMessageEndTextDelimiter];
    return [self sendCommandWithString:msgToSend];
}

- (BOOL) sendComfirmationOfFileTransferWithName:(NSString*)fileName {
    NSString * msgToSend = [NSString stringWithFormat:@"%@%@%@%@%@", kSocketMessageStartTextDelimiter, kCommandFileTransferCompleted, kCommandDelimiter, fileName, kSocketMessageEndTextDelimiter];
    return [self sendCommandWithString:msgToSend];
}


@end
