//
//  ClientsConnectedViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-27.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "ClientsConnectedViewController.h"
#import "AppDelegate.h"

@interface ClientsConnectedViewController ()

@property (nonatomic, strong) UILabel *numberOfClientsLabel;

@end

@implementation ClientsConnectedViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // TODO: display actual number of connections
    NSUInteger numberOfHTTPConnections = 0;
    NSString *title = [NSString stringWithFormat:@"%lu %@ connected", (unsigned long)numberOfHTTPConnections, numberOfHTTPConnections == 1 ? @"person" : @"people"];
    [self.navigationItem setTitle:title];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
