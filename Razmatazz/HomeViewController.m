//
//  HomeViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "HomeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "StyleFactory.h"

@interface HomeViewController ()

@property (nonatomic, strong) UIButton *joinPartyButton, *hostPartyButton;

@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.joinPartyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.hostPartyButton = [UIButton buttonWithType:UIButtonTypeCustom];        
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIButton delegate

- (void) hostPartyButtonPressed {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Name your party" message:@"Choose a name for your party" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
}

- (void) joinPartyButtonPressed {
    NSLog(@"Joining party!");
}

#pragma mark - UIAlertView delegate 

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"Party name: %@", [[alertView textFieldAtIndex:0] text]);
}

@end
