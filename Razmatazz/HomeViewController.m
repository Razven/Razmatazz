//
//  HomeViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "HomeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "StyleFactory.h"
#import "HostPartyViewController.h"
#import "RazConnectionManager.h"
#import "JoinPartyViewController.h"

@interface HomeViewController () < UITextFieldDelegate >

@property (nonatomic, strong) UIButton *joinPartyButton, *hostPartyButton;
@property (nonatomic, weak) RazConnectionManager* razConnectionManager;

@property (nonatomic, strong) UIAlertView *             hostPartyAlertView;
@property (nonatomic, strong) UIAlertView *             joinPartyAlertView;

@end

@implementation HomeViewController

- (id) init {
    self = [super init];
    
    if(self) {
        self.joinPartyButton = [[UIButton alloc] init];
        self.hostPartyButton = [[UIButton alloc] init];
        
        self.hostPartyAlertView = [[UIAlertView alloc] initWithTitle:@"Name your party" message:@"Choose a name for your party" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [self.hostPartyAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [self.hostPartyAlertView textFieldAtIndex:0].delegate = self;
        
        self.joinPartyAlertView = [[UIAlertView alloc] initWithTitle:@"Nickname" message:@"Please enter your nickname" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [self.joinPartyAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [self.joinPartyAlertView textFieldAtIndex:0].delegate = self;
    }
    
    return self;
}
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.joinPartyButton.frame = CGRectMake(0, 200, 200, 40);
    self.hostPartyButton.frame = CGRectMake(0, 300, 200, 40);
    self.joinPartyButton.center = CGPointMake(self.view.center.x, self.joinPartyButton.center.y);
    self.hostPartyButton.center = CGPointMake(self.view.center.x, self.hostPartyButton.center.y);
    
    [self.joinPartyButton setTitle:@"Join an existing party" forState:UIControlStateNormal];
    [self.joinPartyButton setTitle:@"Join an existing party" forState:UIControlStateHighlighted];
    [self.hostPartyButton setTitle:@"Host your own party" forState:UIControlStateNormal];    
    [self.hostPartyButton setTitle:@"Host your own party" forState:UIControlStateHighlighted];
    
    self.joinPartyButton.layer.cornerRadius = 5.0f;
    self.joinPartyButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.joinPartyButton.layer.borderWidth = 1.0f;
    self.joinPartyButton.backgroundColor = [UIColor darkGrayColor];
    
    self.hostPartyButton.layer.cornerRadius = 5.0f;
    self.hostPartyButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.hostPartyButton.layer.borderWidth = 1.0f;
    self.hostPartyButton.backgroundColor = [UIColor darkGrayColor];
    
    [self.joinPartyButton setBackgroundImage:[StyleFactory imageWithColor:[UIColor darkGrayColor] andSize:self.joinPartyButton.frame.size] forState:UIControlStateNormal];
    [self.joinPartyButton setBackgroundImage:[StyleFactory imageWithColor:[UIColor grayColor] andSize:self.joinPartyButton.frame.size] forState:UIControlStateHighlighted];
    
    [self.hostPartyButton setBackgroundImage:[StyleFactory imageWithColor:[UIColor darkGrayColor] andSize:self.joinPartyButton.frame.size] forState:UIControlStateNormal];
    [self.hostPartyButton setBackgroundImage:[StyleFactory imageWithColor:[UIColor grayColor] andSize:self.joinPartyButton.frame.size] forState:UIControlStateHighlighted];
    
    [self.joinPartyButton setClipsToBounds:YES];
    [self.hostPartyButton setClipsToBounds:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.hostPartyButton addTarget:self action:@selector(hostPartyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.joinPartyButton addTarget:self action:@selector(joinPartyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.joinPartyButton];
    [self.view addSubview:self.hostPartyButton];
    
    [self.navigationController.navigationBar setTintColor:[UIColor lightGrayColor]];
    
    self.razConnectionManager = [(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:@"Home"];
    
    [self.razConnectionManager stopServer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) pushJoinPartyViewController {
    JoinPartyViewController *jpvc = [[JoinPartyViewController alloc] initWithType:kRazmatazzBonjourType];
    [self.navigationController pushViewController:jpvc animated:YES];
}

#pragma mark - UIButton delegate

- (void) hostPartyButtonPressed {
    [self.hostPartyAlertView show];
}

- (void) joinPartyButtonPressed {
    if(![[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsClientNickName]){
        [self.joinPartyAlertView show];
    } else {
        [self pushJoinPartyViewController];
    }
}

#pragma mark - UIAlertView delegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    // don't allow a chatroom with no name
    // this makes the back button of the clients view to not show up when pushed from here
    return [[[alertView textFieldAtIndex:0] text] length] > 0;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.hostPartyAlertView){
        if(buttonIndex == 1){
            [[self.hostPartyAlertView textFieldAtIndex:0] setText:@""];
            HostPartyViewController *hpvc = [[HostPartyViewController alloc] initWithPartyName:[[alertView textFieldAtIndex:0] text]];
            [self.navigationController pushViewController:hpvc animated:YES];
        }
    } else if(alertView == self.joinPartyAlertView){
        if(buttonIndex == 1){
            [[NSUserDefaults standardUserDefaults] setValue:[[alertView textFieldAtIndex:0] text] forKey:kUserDefaultsClientNickName];
            [self pushJoinPartyViewController];
        }
    }
}

#pragma mark - UITextField delegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return (range.location < 15);
}

@end
