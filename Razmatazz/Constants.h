//
//  Constants.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-27.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#ifndef Razmatazz_Constants_h
#define Razmatazz_Constants_h

#define APPLICATION_SONGS_DIRECTORY [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Songs"]

#define kRazmatazzBonjourType                   @"_razmatazz._tcp."

#define kServerStartedNotification              @"QServerStartedNotification"
#define kServerStoppedNotification              @"QServerStoppedNotification"

#define kClientConnectedNotification            @"ClientConnectedNotification"
#define kClientDisconnectedNotification         @"ClientDisconnectedNotification"

#define kClientRegisteredNotification           @"ClientRegisteredNotification"

#define kServerConnectedNotification            @"ServerConnectedNotification"
#define kServerDisconnectedNotification         @"ServerDisconnectedNotification"

#define kFileSuccessfullySentNotification       @"fileSuccessfullySentNotification"
#define kFileTransferCompletedNotification      @"FileTransferCompletedNotification"
#define kPlaySongNotification                   @"playSongNotification"

#define kSocketMessageStartTextDelimiter        @"razmatazz1597534862"
#define kSocketMessageEndTextDelimiter          @"7539512684razmatazz"
#define kSocketMessageStartBytesDelimiter       [kSocketMessageStartTextDelimiter UTF8String]
#define kSocketMessageEndBytesDelimiter         [kSocketMessageEndTextDelimiter UTF8String]

#define kUserDefaultsClientNickName             @"clientNickName"

#define kCommandDelimiter                       @":"
#define kCommandClientNickName                  @"clientNickName"
#define kCommandFileName                        @"fileName"
#define kCommandFileSize                        @"fileSize"
#define kCommandFileTransferCompleted           @"fileTransferCompleted"
#define kCommandPlaySong                        @"playSong"

#define kNetworkParameterFileName               @"fileName"
#define kNetworkParamaterFileSize               @"fileSize"
#define kNetworkParamaterFileData               @"fileData"


#endif
