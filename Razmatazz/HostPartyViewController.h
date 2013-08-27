//
//  HostPartyViewController.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HostPartyViewController : UIViewController

@property (nonatomic, strong) UILabel *statusLabel, *usersConnectedLabel, *songListLabel;
@property (nonatomic, strong) UITableView *usersConnectedTableView, *songListTableView;

- (id) initWithPartyName:(NSString*)partyName;

@end
