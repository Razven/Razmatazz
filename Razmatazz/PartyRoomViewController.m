//
//  PartyRoomViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-29.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "PartyRoomViewController.h"
#import "RazConnectionManager.h"
#import "AppDelegate.h"

@interface PartyRoomViewController () < UIAlertViewDelegate >

@property (nonatomic, strong) NSString *                    partyName;
@property (nonatomic, weak) RazConnectionManager *          connectionManager;

@end

@implementation PartyRoomViewController

- (id) initWithPartyName:(NSString *)partyName {
    self = [super init];
    
    if(self){
        self.partyName = partyName;
        self.connectionManager = [(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager];
    }
    
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setTitle:self.partyName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationItem setHidesBackButton:YES];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(confirmExitPartyRoom)];    
    [self.navigationItem setLeftBarButtonItem:backButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) confirmExitPartyRoom {
    UIAlertView * confirmExit = [[UIAlertView alloc] initWithTitle:@"Exiting party" message:@"You are about to leave the party. Do you wish to continue?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [confirmExit show];
}

#pragma mark - UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1){
        //TODO: exiting party; do any cleanup we need to do here
        
        [self.connectionManager closePartyServerStream];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
