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
#import <QuartzCore/QuartzCore.h>

@interface ClientsConnectedViewController () < UITableViewDataSource, UITableViewDelegate >

@property (nonatomic, strong) UITableView *             clientsConnectedTableView;
@property (nonatomic, weak) RazConnectionManager *      razConnectionManager;
@property (nonatomic, strong) NSArray *                 clientNamesArray;

@property (nonatomic, strong) UILabel *                 noClientsConnectedLabel;

@end

@implementation ClientsConnectedViewController

- (id) init {
    self = [super init];
    
    if(self){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newClientConnected:) name:kClientRegisteredNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDisconnected:) name:kClientDisconnectedNotification object:nil];
        
        self.clientsConnectedTableView = [[UITableView alloc] init];
        self.clientsConnectedTableView.delegate = self;
        self.clientsConnectedTableView.dataSource = self;
        
        self.clientNamesArray = [NSArray array];
        
        self.noClientsConnectedLabel = [[UILabel alloc] init];
        
        self.razConnectionManager =[(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupTitle];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.clientsConnectedTableView.frame = CGRectMake(5, 5, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
    self.clientsConnectedTableView.layer.cornerRadius = 3.0f;
    self.clientsConnectedTableView.layer.borderWidth = 1.0f;
    self.clientsConnectedTableView.layer.borderColor = [UIColor whiteColor].CGColor;    
    self.clientsConnectedTableView.backgroundColor = [UIColor lightGrayColor];
    
    self.noClientsConnectedLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.noClientsConnectedLabel.center = self.clientsConnectedTableView.center;
    self.noClientsConnectedLabel.textAlignment = NSTextAlignmentCenter;
    self.noClientsConnectedLabel.backgroundColor = [UIColor clearColor];
    [self.noClientsConnectedLabel setText:@"You're the only one partying :("];
    self.noClientsConnectedLabel.textColor = [UIColor whiteColor];
}

- (void)viewDidLoad
{
    [self setupTitle];
    [super viewDidLoad];
    
    
//    [self.clientsConnectedTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:self.clientsConnectedTableView];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
}

- (void)setupTitle {
    NSUInteger numberOfHTTPConnections = [self.razConnectionManager getNumberOfActiveClients];
    NSString *title = [NSString stringWithFormat:@"%lu %@ connected", (unsigned long)numberOfHTTPConnections, numberOfHTTPConnections == 1 ? @"person" : @"people"];
    [self.navigationItem setTitle:title];
    
    self.clientNamesArray = [self.razConnectionManager getArrayOfClientNames];
    [self.clientsConnectedTableView reloadData];
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

#pragma mark - UITableView delegate/data source selectors

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if(!cell){
        cell =  [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    [cell.textLabel setText:[self.clientNamesArray objectAtIndex:indexPath.row]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfClientsRegistered = [self.clientNamesArray count];
    
    if(numberOfClientsRegistered == 0){
        [self.clientsConnectedTableView addSubview:self.noClientsConnectedLabel];
    } else {
        [self.noClientsConnectedLabel removeFromSuperview];
    }
    
    return numberOfClientsRegistered;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end
