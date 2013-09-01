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
#import "RazInfoPopupView.h"
#import <AVFoundation/AVFoundation.h>

@interface PartyRoomViewController () < UIAlertViewDelegate >

@property (nonatomic, strong) NSString *                    partyName;
@property (nonatomic, weak) RazConnectionManager *          connectionManager;
@property (nonatomic, strong) RazInfoPopupView *            serverDisconnectedView;

@property (nonatomic, strong) AVAudioPlayer *               audioPlayer;

@end

@implementation PartyRoomViewController

- (id) initWithPartyName:(NSString *)partyName {
    self = [super init];
    
    if(self){
        self.partyName = partyName;
        self.connectionManager = [(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager];
        self.serverDisconnectedView = [[RazInfoPopupView alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDisconnected:) name:kServerDisconnectedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playSong:) name:kPlaySongNotification object:nil];
    }
    
    return self;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self.serverDisconnectedView setFrame:CGRectMake(0, self.view.frame.size.height, 200, 200)];
    [self.serverDisconnectedView setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
    
    self.serverDisconnectedView.infoLabel.text = @"The server has disconnected, please try again or join a different party";
    [self.serverDisconnectedView.actionButton setTitle:@"Okay" forState:UIControlStateNormal];
    [self.serverDisconnectedView.actionButton setTitle:@"Okay" forState:UIControlStateHighlighted];
    
    [self.serverDisconnectedView.actionButton addTarget:self action:@selector(hideServerDisconnectedView) forControlEvents:UIControlEventTouchUpInside];
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

- (void) showServerDisconnectedView {
    [self.view addSubview:self.serverDisconnectedView];
    [UIView animateWithDuration:0.3f animations:^{
        self.serverDisconnectedView.center = CGPointMake(self.view.center.x, self.view.center.y);
    }];
}

- (void) hideServerDisconnectedView {
    // just in case
    [UIView animateWithDuration:0.3f animations:^{
        self.serverDisconnectedView.frame = CGRectMake(self.serverDisconnectedView.frame.origin.x, self.view.frame.size.height, self.serverDisconnectedView.frame.size.width, self.serverDisconnectedView.frame.size.height);
    } completion:^(BOOL finished) {
        [self.serverDisconnectedView removeFromSuperview];;
    }];
    
    [self.connectionManager closePartyServerStream];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1){
        //TODO: exiting party; do any cleanup we need to do here
        
        [self.connectionManager closePartyServerStream];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - NSNotificationCenter

- (void)serverDisconnected:(NSNotification*)notification {
    [self showServerDisconnectedView];
}

- (void) playSong:(NSNotification*)notification {
    NSLog(@"playing song: %@", [notification object]);
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APPLICATION_SONGS_DIRECTORY, [notification object]]] error:nil];
    [self.audioPlayer play];
}

@end
