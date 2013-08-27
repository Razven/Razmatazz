//
//  HostPartyViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "HostPartyViewController.h"
#import "AppDelegate.h"

@interface HostPartyViewController ()

@property (nonatomic, strong) NSString* partyName;
@property (nonatomic, strong) NSError* serverError;
@end

@implementation HostPartyViewController

- (id) initWithPartyName:(NSString *)partyName {
    self = [super init];
    
    if(self){                
        self.partyName = partyName;
        self.serverError = [(AppDelegate*)[UIApplication sharedApplication].delegate startServer];
    }
    
    return self;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:self.partyName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    self.statusLabel.center = CGPointMake(self.view.center.x, self.statusLabel.center.y);
    
    if(self.serverError){
        // there was an error starting the server
        // TODO: provide a more descriptive error message based on the error returned
        [self updateStatus:@"error starting the party"];

        self.serverError = nil;
    } else {
        // server started up successfully
        
        [self updateStatus:@"party room created!"];
        
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];    
    [(AppDelegate*)[UIApplication sharedApplication].delegate stopServer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) updateStatus:(NSString*)status {
    if(self.statusLabel){
        self.statusLabel.text = [NSString stringWithFormat:@"Status: %@", status];
    }
}


@end
