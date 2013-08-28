//
//  JoinPartyViewController.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JoinPartyViewController : UIViewController

@property (nonatomic, strong, readwrite) NSNetService *         localService;
@property (nonatomic, copy)              NSString *             type;

- (id) initWithType:(NSString*)type;

@end
