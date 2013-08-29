//
//  ClientsConnectedViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-27.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "ClientsConnectedViewController.h"
#import "RazConnectionManager.h"
#import "AppDelegate.h"

@interface ClientsConnectedViewController ()

@property (nonatomic, strong) UILabel *numberOfClientsLabel;

@end

@implementation ClientsConnectedViewController

- (id) init {
    self = [super init];
    
    if(self){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newClientConnected:) name:kClientConnectedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDisconnected:) name:kClientDisconnectedNotification object:nil];
    }
    
    return self;
}

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
    [self setupTitle];
}

- (void)setupTitle {
    NSUInteger numberOfHTTPConnections = [[(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager] getNumberOfActiveClients];
    NSString *title = [NSString stringWithFormat:@"%lu %@ connected", (unsigned long)numberOfHTTPConnections, numberOfHTTPConnections == 1 ? @"person" : @"people"];
    [self.navigationItem setTitle:title];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotificationCenter selectors

- (void)newClientConnected:(NSNotification*)notification {
    [self setupTitle];
}

- (void)clientDisconnected:(NSNotification*)notification {
    [self setupTitle];
}

@end
