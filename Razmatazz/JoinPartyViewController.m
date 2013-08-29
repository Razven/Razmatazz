//
//  JoinPartyViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "JoinPartyViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface JoinPartyViewController () < UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate >

@property (nonatomic, strong)            UITableView *          clientsConnectedTableView;
@property (nonatomic, strong)            NSMutableArray *       services;
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  browser;

@property (nonatomic, strong)            UIView *               connectView;
@property (nonatomic, strong)            UILabel *              connectViewInfolabel;

@end

@implementation JoinPartyViewController

- (id) initWithType:(NSString*)type {
    self = [super init];
    
    if(self){
        self.clientsConnectedTableView = [[UITableView alloc] init];
        self.clientsConnectedTableView.delegate = self;
        self.clientsConnectedTableView.dataSource = self;
        
        self.connectView = [[UIView alloc] init];
        self.connectViewInfolabel = [[UILabel alloc] init];
    
        self.type = type;
        
        [self addObserver:self forKeyPath:@"localService" options:0 context:&self->_localService];
        
        self.services = [NSMutableArray array];
    }
    
    return self;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.clientsConnectedTableView.frame = CGRectMake(5, 5, self.view.frame.size.width - 10, self.view.frame.size.height - 10);
    self.clientsConnectedTableView.backgroundColor = [UIColor lightGrayColor];
    self.clientsConnectedTableView.layer.cornerRadius = 3.0f;
    self.clientsConnectedTableView.layer.borderWidth = 1.0f;
    self.clientsConnectedTableView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self.connectView setFrame:CGRectMake(0, self.view.frame.size.height, 200, 200)];
    self.connectView.center = CGPointMake(self.view.center.x, self.connectView.center.y);
    self.connectView.layer.cornerRadius = 3.0f;
    self.connectView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.connectView.layer.borderWidth = 1.0f;
    self.connectView.backgroundColor = [UIColor darkGrayColor];
    self.connectView.clipsToBounds = YES;
    
    [self.connectViewInfolabel setFrame:CGRectMake(0, 0, self.connectView.frame.size.width, 45)];
    [self.connectViewInfolabel setNumberOfLines:0];
    [self.connectViewInfolabel setBackgroundColor:[UIColor clearColor]];
    self.connectViewInfolabel.textColor = [UIColor whiteColor];
    self.connectViewInfolabel.backgroundColor = [UIColor lightGrayColor];
    self.connectViewInfolabel.textAlignment = NSTextAlignmentCenter;
    
    UIButton *cancelConnectionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.connectView.frame.size.height - 80, 70, 30)];
    cancelConnectionButton.center = CGPointMake(CGRectGetMidX(self.connectView.bounds), cancelConnectionButton.center.y);
    [cancelConnectionButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelConnectionButton setTitle:@"Cancel" forState:UIControlStateHighlighted];
    cancelConnectionButton.layer.cornerRadius = 3.0f;
    cancelConnectionButton.layer.borderWidth = 1.0f;
    cancelConnectionButton.layer.borderColor = [UIColor whiteColor].CGColor;
    cancelConnectionButton.backgroundColor = [UIColor lightGrayColor];
    
    UIActivityIndicatorView * spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinnerView.center = CGPointMake(CGRectGetMidX(self.connectView.bounds), CGRectGetMidY(self.connectView.bounds) - 17);
    [spinnerView startAnimating];
    
    [cancelConnectionButton addTarget:self action:@selector(cancelConnectingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.connectView addSubview:self.connectViewInfolabel];
    [self.connectView addSubview:cancelConnectionButton];
    [self.connectView addSubview:spinnerView];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.clientsConnectedTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:self.clientsConnectedTableView];
	
    [self.navigationItem setTitle:@"Join a party"];
    
    [self start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) dealloc {
    [self removeObserver:self forKeyPath:@"localService" context:&self->_localService];
}

- (void)start {    
    self.browser = [[NSNetServiceBrowser alloc] init];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:self.type inDomain:@"local"];
}

- (void)stop {
    [self.browser stop];
    self.browser = nil;
    
    [self.services removeAllObjects];
    
    if (self.isViewLoaded) {
        [self.clientsConnectedTableView reloadData];
    }
}

#pragma mark - ObserveValueForKeyPath

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_localService) {        
        // There's a chance that the browser saw our service before we heard about its successful
        // registration, at which point we need to hide the service.  Doing that would be easy,
        // but there are other edge cases to consider (for example, if the local service changes
        // name, we would have to unhide the old name and hide the new name).  Rather than attempt
        // to handle all of those edge cases we just stop and restart when the service name changes.
        
        if (self.browser != nil) {
            [self stop];
            [self start];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - UITableView delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *	cell;
    NSNetService *      service;
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];
    
    cell = [self.clientsConnectedTableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = service.name;
    
    cell.textLabel.textColor = [UIColor whiteColor];
    
    UIView * cellSelectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cellSelectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    cell.selectedBackgroundView = cellSelectedBackgroundView;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNetService * service;
    
    [self.clientsConnectedTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Find the service associated with the cell and start a connection to that.
    
    service = [self.services objectAtIndex:(NSUInteger) indexPath.row];
    [self showConnectViewForService:service];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
    self.connectViewInfolabel.text = [NSString stringWithFormat:@"Connecting to %@", [service name]];
    [self.clientsConnectedTableView addSubview:self.connectView];
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.connectView.center = CGPointMake(self.connectView.center.x, self.view.center.y);
    }];
    
    self.clientsConnectedTableView.scrollEnabled = NO;
    self.clientsConnectedTableView.allowsSelection = NO;
}

- (void)hideConnectView {
    if (self.connectView.superview != nil) {
        
        [UIView animateWithDuration:0.3f animations:^{
            self.connectView.frame = CGRectMake(self.connectView.frame.origin.x, self.view.frame.size.height, self.connectView.frame.size.width, self.connectView.frame.size.height);
        } completion:^(BOOL finished) {
            [self.connectView removeFromSuperview];
            [self.navigationItem setHidesBackButton:NO animated:YES];
        }];
        
        self.clientsConnectedTableView.scrollEnabled = YES;
        self.clientsConnectedTableView.allowsSelection = YES;
    }
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
        [self.clientsConnectedTableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {    
    if ((self.localService == nil) || ![self.localService isEqual:service]) {
        [self.services removeObject:service];
    }
    
    if (!moreComing) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    if ((self.localService == nil) || ! [self.localService isEqual:service]) {
        [self.services addObject:service];
    }
    
    if (!moreComing) {
        [self sortAndReloadTable];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"browser did not search.");
}

@end
