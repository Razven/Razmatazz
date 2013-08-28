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

#define kRazmatazzBonjourType @"_razmatazz._tcp."

#define kServerStartedNotification @"QServerStarted"
#define kServerStoppedNotification @"QServerStopped"

#define kClientConnectedNotification @"ClientConnected"
#define kClientDisconnectedNotification @"ClientDisconnected"



#endif
