//
//  HostPartyViewController.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HostPartyViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *statusLabel, *songListLabel;
@property (nonatomic, strong) UITableView *songListTableView;

- (id) initWithPartyName:(NSString*)partyName;

@end
