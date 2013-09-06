//
//  JoinPartyViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "JoinPartyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RazInfoPopupView.h"
#import "RazServerConnection.h"
#import "AppDelegate.h"
#import "RazConnectionManager.h"
#import "PartyRoomViewController.h"

@interface JoinPartyViewController () < UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate >

@property (nonatomic, strong)            UITableView *          partiesAvailableTableView;
@property (nonatomic, strong)            NSMutableArray *       services;
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;

@property (nonatomic, strong)            RazInfoPopupView *     connectView;
@property (nonatomic, strong)            RazInfoPopupView *     connectionDissapearedView;

@property (nonatomic, strong)            UILabel *              noPartiesAvailableLabel;

@end

@implementation JoinPartyViewController

- (id) initWithType:(NSString*)type {
    self = [super init];
    
    if(self){
        self.partiesAvailableTableView = [[UITableView alloc] init];
        self.partiesAvailableTableView.delegate = self;
        self.partiesAvailableTableView.dataSource = self;
        
        self.connectView = [[RazInfoPopupView alloc] init];
        self.connectionDissapearedView = [[RazInfoPopupView alloc] init];
        self.noPartiesAvailableLabel = [[UILabel alloc] init];
    
        self.type = type;
        
        self.services = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedToServer:) name:kServerConnectedNotification object:nil];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.partiesAvailableTableView.frame = CGRectMake(5, 5, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
    self.partiesAvailableTableView.backgroundColor = [UIColor lightGrayColor];
    self.partiesAvailableTableView.layer.cornerRadius = 3.0f;
    self.partiesAvailableTableView.layer.borderWidth = 1.0f;
    self.partiesAvailableTableView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self.connectView setFrame:CGRectMake(0, self.view.frame.size.height, 200, 200)];
    [self.connectView setCenter:CGPointMake(self.view.center.x, self.connectView.center.y)];
    [self.connectView.actionButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.connectView.actionButton setTitle:@"Cancel" forState:UIControlStateHighlighted];
    [self.connectView.actionButton addTarget:self action:@selector(hideConnectView) forControlEvents:UIControlEventTouchUpInside];
    
    UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.center = CGPointMake(CGRectGetMidX(self.connectView.bounds), CGRectGetMidY(self.connectView.bounds) - 17);
    [activityIndicator startAnimating];
    
    [self.connectView setActivityView:activityIndicator];
    
    [self.connectionDissapearedView setFrame:CGRectMake(0, self.view.frame.size.height, 200, 200)];
    [self.connectionDissapearedView setCenter:CGPointMake(self.view.center.x, self.connectionDissapearedView.center.y)];
    
    self.connectionDissapearedView.infoLabel.text = @"The connection was lost, please try again or join a different party";
    [self.connectionDissapearedView.actionButton setTitle:@"Okay" forState:UIControlStateNormal];
    [self.connectionDissapearedView.actionButton setTitle:@"Okay" forState:UIControlStateHighlighted];
    
    [self.connectionDissapearedView.actionButton addTarget:self action:@selector(hideConnectionDissapearedView) forControlEvents:UIControlEventTouchUpInside];
    
    self.noPartiesAvailableLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.noPartiesAvailableLabel.center = self.partiesAvailableTableView.center;
    self.noPartiesAvailableLabel.textAlignment = NSTextAlignmentCenter;
    self.noPartiesAvailableLabel.backgroundColor = [UIColor clearColor];
    [self.noPartiesAvailableLabel setText:@"No parties found"];
    self.noPartiesAvailableLabel.textColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(!self.browser){
        [self start];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.partiesAvailableTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:self.partiesAvailableTableView];
	
    [self.navigationItem setTitle:@"Join a party"];
    
    [self start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)start {    
    self.browser = [[NSNetServiceBrowser alloc] init];
    [self.browser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:self.type inDomain:@""];
}

- (void)stop {
    [self.browser stop];
    self.browser = nil;
    
    [self.services removeAllObjects];
    
    if (self.isViewLoaded) {
        [self.partiesAvailableTableView reloadData];
    }
}

#pragma mark - UITableView delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *	cell;
    NSNetService *      service;
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];
    
    cell = [self.partiesAvailableTableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = service.name;
    
    cell.textLabel.textColor = [UIColor whiteColor];
    
    UIView * cellSelectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cellSelectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    cell.selectedBackgroundView = cellSelectedBackgroundView;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNetService * service;
    
    [self.partiesAvailableTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Find the service associated with the cell and start a connection to that.
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];    
    [self showConnectViewForService:service withCompletionBlock:^{
        [self connectToService:service];
    }];   
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int numOfConnections = [self.services count];
    
    if(numOfConnections == 0){
        [self.partiesAvailableTableView addSubview:self.noPartiesAvailableLabel];
    } else {
        [self.noPartiesAvailableLabel removeFromSuperview];
    }
    return [self.services count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 0.0f;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

#pragma mark * Connection-in-progress UI management

- (void)showConnectViewForService:(NSNetService *)service {    
    [self showConnectViewForService:service withCompletionBlock:nil];
}

- (void) showConnectViewForService:(NSNetService*)service withCompletionBlock:(void(^)())completion {
    self.connectView.infoLabel.text = [NSString stringWithFormat:@"Connecting to %@", [service name]];
    [self.partiesAvailableTableView addSubview:self.connectView];
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.connectView.center = CGPointMake(self.connectView.center.x, self.view.center.y);
        if(completion){
            completion();
        }
    }];
    
    self.partiesAvailableTableView.scrollEnabled = NO;
    self.partiesAvailableTableView.allowsSelection = NO;
    
    self.connectingToService = service;
    
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(connectionTimedOut) userInfo:nil repeats:NO];
}

- (void) showConnectionDissapearedView {
    [self.partiesAvailableTableView addSubview:self.connectionDissapearedView];
    [UIView animateWithDuration:0.3f animations:^{
        self.connectionDissapearedView.center = CGPointMake(self.connectView.center.x, self.view.center.y);
    }];
}

- (void) hideConnectView {
    [self hideConnectViewWithCompletionBlock:nil];
}

- (void)hideConnectViewWithCompletionBlock:(void (^)())completion {
    if (self.connectView.superview != nil) {        
        [UIView animateWithDuration:0.3f animations:^{
            self.connectView.frame = CGRectMake(self.connectView.frame.origin.x, self.view.frame.size.height, self.connectView.frame.size.width, self.connectView.frame.size.height);
        } completion:^(BOOL finished) {
            [self.connectView removeFromSuperview];
            [self.navigationItem setHidesBackButton:NO animated:YES];
            if(completion){
                completion();
            }
        }];
        
        self.partiesAvailableTableView.scrollEnabled = YES;
        self.partiesAvailableTableView.allowsSelection = YES;
        
        self.connectingToService = nil;
    }
}

- (void) hideConnectViewAndShowConnectionDissapearedView {
    [self hideConnectViewWithCompletionBlock:^{
        [self showConnectionDissapearedView];
    }];
}

- (void) hideConnectionDissapearedView {
    if(self.connectionDissapearedView.superview != nil){
        [UIView animateWithDuration:0.3f animations:^{
            self.connectionDissapearedView.frame = CGRectMake(self.connectView.frame.origin.x, self.view.frame.size.height, self.connectView.frame.size.width, self.connectView.frame.size.height);
        } completion:^(BOOL finished) {
            [self.connectionDissapearedView removeFromSuperview];
            [self.navigationItem setHidesBackButton:NO animated:YES];
        }];
        
        self.partiesAvailableTableView.scrollEnabled = YES;
        self.partiesAvailableTableView.allowsSelection = YES;
    }
}

- (void) connectionTimedOut {
    if(self.connectingToService){
        [self hideConnectViewAndShowConnectionDissapearedView];
    }
    
    self.connectingToService = nil;
}

- (void)cancelConnectingButtonPressed {
    [self hideConnectView];
}

#pragma mark * Browser view callbacks

- (void)sortAndReloadTable
{
    // Sort the services by name.
    
    [self.services sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name] localizedCaseInsensitiveCompare:[obj2 name]];
    }];
    
    if (self.isViewLoaded) {
        [self.partiesAvailableTableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // the service we're connecting to has gone missing from the network
    
    if(self.connectingToService != nil && [self.connectingToService isEqual:service]){
        [self hideConnectViewAndShowConnectionDissapearedView];
    }
    
    [self.services removeObject:service];
    
    if (!moreComing) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {    
    [self.services addObject:service];
    NSLog(@"Found service");
    
    if (!moreComing) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"browser did not search.");
}

#pragma mark - Connect to server

- (void) connectToService:(NSNetService *)service {
    BOOL                success;
    NSInputStream *     inStream;
    NSOutputStream *    outStream;
    
    success = [service getInputStream:&inStream outputStream:&outStream];
    if (!success) {
        [self hideConnectViewAndShowConnectionDissapearedView];
        
        if(inStream){
            [inStream close];
        }
        
        if(outStream){
            [outStream close];
        }
        
        inStream = nil;
        outStream = nil;
        
    } else {
        RazServerConnection* connection = [[RazServerConnection alloc] initWithInputStream:inStream andOutputStream:outStream];
        [connection setConnectionName:service.name];
        [connection openAllStreams];
        [[(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager] setServerConnection:connection];
    }
}

- (void) connectedToServer:(NSNotification*)notification {
    [self hideConnectViewWithCompletionBlock:^{
        PartyRoomViewController * prvc = [[PartyRoomViewController alloc] initWithPartyName:[(RazConnection*)notification.object connectionName]];
        [self.navigationController pushViewController:prvc animated:YES];
    }];
}


@end
