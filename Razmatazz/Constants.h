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

#define kServerStartedNotification              @"QServerStarted"
#define kServerStoppedNotification              @"QServerStopped"

#define kClientConnectedNotification            @"ClientConnected"
#define kClientDisconnectedNotification         @"ClientDisconnected"

#define kClientRegisteredNotification           @"ClientRegistered"

#define kServerConnectedNotification            @"ServerConnected"
#define kServerDisconnectedNotification         @"ServerDisconnected"

#define kFileTransferCompletedNotification      @"FileTransferCompleted"

#define kSocketMessageStartDelimiter            @"razmatazz1597534862"
#define kSocketMessageEndDelimiter              @"7539512684razmatazz"

#define kUserDefaultsClientNickName             @"clientNickName"

#define kCommandDelimiter                       @":"
#define kCommandClientNickName                  @"clientNickName"
#define kCommandFileName                        @"fileName"
#define kCommandFileSize                        @"fileSize"
#define kCommandFileTransferCompleted           @"fileTransferCompleted"

#define kNetworkParameterFileName               @"fileName"
#define kNetworkParamaterFileSize               @"fileSize"
#define kNetworkParamaterFileData               @"fileData"


#endif
