//
//  HostPartyViewController.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-26.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "HostPartyViewController.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ClientsConnectedViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface HostPartyViewController ()

@property (nonatomic, strong) NSString* partyName;
@property (nonatomic, strong) NSError* serverError;

@property (nonatomic, strong) UIView *songListLabelBackgroundView;
@end

@implementation HostPartyViewController

- (id) initWithPartyName:(NSString *)partyName {
    self = [super init];
    
    if(self){                
        self.partyName = partyName;
        self.serverError = [(AppDelegate*)[UIApplication sharedApplication].delegate startServer];
        
        self.statusLabel = [[UILabel alloc] init];
        self.songListLabel = [[UILabel alloc] init];
        self.songListTableView = [[UITableView alloc] init];
        self.songListLabelBackgroundView = [[UIView alloc] init];
    }
    
    return self;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.statusLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    self.statusLabel.backgroundColor = [UIColor darkGrayColor];
    [self.statusLabel setTextColor:[UIColor whiteColor]];
    
    self.songListLabelBackgroundView.frame = CGRectMake(5, CGRectGetMaxY(self.statusLabel.frame) + 5, self.view.frame.size.width - 10, 40);
    self.songListLabelBackgroundView.backgroundColor = [UIColor grayColor];
    self.songListLabelBackgroundView.layer.cornerRadius = 3.0f;
    
    self.songListLabel.frame = CGRectMake(5, 0, self.songListLabelBackgroundView.frame.size.width - 10, 30);
    self.songListLabel.backgroundColor = [UIColor clearColor];
    [self.songListLabel setTextColor:[UIColor whiteColor]];
    self.songListLabel.text = @"Pick a song to play";
//    [self.songListLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0f]];
    
    [self.songListLabelBackgroundView addSubview:self.songListLabel];
    
    self.songListTableView.frame = CGRectMake(5, CGRectGetMaxY(self.songListLabelBackgroundView.frame) - 10, self.view.frame.size.width - 10, self.view.frame.size.height - CGRectGetMaxY(self.songListLabel.frame) - 5);
    
    self.songListTableView.delegate = self;
    self.songListTableView.dataSource = self;
    
    self.songListTableView.layer.cornerRadius = 5.0f;
    self.songListTableView.layer.borderWidth = 1.0f;
    self.songListTableView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    [self.songListTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongNameCell"];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:self.partyName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.serverError){
        // there was an error starting the server
        // TODO: provide a more descriptive error message based on the error returned
        [self updateStatus:@"error starting the party"];

        self.serverError = nil;
    } else {
        // server started up successfully
        
        [self updateStatus:@"party room created!"];
    }
    
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.songListLabel];
    [self.view addSubview:self.songListLabelBackgroundView];
    [self.view addSubview:self.songListTableView];    
    
    UIImage *groupIcon = [UIImage imageNamed:@"group.png"];
    UIBarButtonItem *viewClientsConnected = [[UIBarButtonItem alloc] initWithImage:groupIcon style:UIBarButtonItemStyleBordered target:self action:@selector(openClientsConnectedView)];
    [self.navigationItem setRightBarButtonItem:viewClientsConnected];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) updateStatus:(NSString*)status {
    if(self.statusLabel){
        self.statusLabel.text = [NSString stringWithFormat:@" Status: %@", status];
    }
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        MPMediaQuery *everything = [[MPMediaQuery alloc] init];
        NSArray *itemsFromGenericQuery = [everything items];
        
        //user has no songs in their iPod library
        if([itemsFromGenericQuery count] == 0){
            self.songListLabel.text = @"No songs found! Add some songs to your iPod library and try again";
            self.songListLabel.center = self.view.center;
            self.songListLabel.numberOfLines = 0;
            self.songListLabel.textAlignment = NSTextAlignmentCenter;
            [self.songListLabel sizeToFit];
            self.songListTableView.hidden = YES;
        }
        return [itemsFromGenericQuery count];
    } else {
        return 0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: copy song from ipod library to app directory and send it to all clients connected to the web server
    // URLs to look at: http://stackoverflow.com/questions/4746349/copy-ipod-music-library-audio-file-to-iphone-app-folder
    // https://www.google.ca/search?q=ios+xcode+copy+song+from+ipod+to+app+directory&oq=ios+xcode+copy+song+from+ipod+to+app+directory&aqs=chrome..69i57.5915j0&sourceid=chrome&ie=UTF-8
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongNameCell"];
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    
    MPMediaItem* song = [itemsFromGenericQuery objectAtIndex:indexPath.row];
    NSURL *songURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    NSString *songTitle = [song valueForProperty:MPMediaItemPropertyTitle];
    [cell.textLabel setText:songTitle];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

#pragma mark - BarButtonItem selectors

- (void) openClientsConnectedView {
    ClientsConnectedViewController *ccvc = [[ClientsConnectedViewController alloc] init];
    [self.navigationController pushViewController:ccvc animated:YES];
}

@end
