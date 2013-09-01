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
#import <AVFoundation/AVFoundation.h>
#import "RazConnectionManager.h"
#import "QServer.h"
#import "RazInfoPopupView.h"

@interface HostPartyViewController ()

@property (nonatomic, strong) NSString *              partyName;
@property (nonatomic, strong) NSError *               serverError;

@property (nonatomic, strong) UIView *                songListLabelBackgroundView;

@property (nonatomic, weak) RazConnectionManager *    razConnectionManager;

@property (nonatomic, strong) RazInfoPopupView *      songTransferProgressPopup;
@property (nonatomic, strong) UIProgressView *        songTransferProgressView;

@property (nonatomic, assign) float                   numberOfClientsToReceiveSong;
@property (nonatomic, assign) float                   numberOfClientsWhoSuccessfullyReceivedSong;

@property (nonatomic, strong) NSIndexPath *           selectedSongIndex;

@property (nonatomic, strong) UIBarButtonItem *       playMusicBarButton;

@property (nonatomic, strong) NSArray *               songsArray;
@property (nonatomic, strong) AVAudioPlayer *         audioPlayer;


@end

@implementation HostPartyViewController

- (id) initWithPartyName:(NSString *)partyName {
    self = [super init];
    
    if(self){                
        self.partyName = partyName;
        
        self.statusLabel = [[UILabel alloc] init];
        self.songListLabel = [[UILabel alloc] init];
        self.songListTableView = [[UITableView alloc] init];
        self.songListLabelBackgroundView = [[UIView alloc] init];
        
        self.razConnectionManager = [(AppDelegate*)[UIApplication sharedApplication].delegate sharedRazConnectionManager];
        
        [self.razConnectionManager startServer];
        [self.razConnectionManager registerServerWithName:self.partyName];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStart:) name:kServerStartedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStop:) name:kServerStoppedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileTransferSuccessful:) name:kFileTransferCompletedNotification object:nil];
        
        self.songTransferProgressPopup = [[RazInfoPopupView alloc] init];
        self.songTransferProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        
        UIImage *playIcon = [UIImage imageNamed:@"group.png"];
        self.playMusicBarButton = [[UIBarButtonItem alloc] initWithImage:playIcon style:UIBarButtonItemStyleBordered target:self action:@selector(sendPlayMusicRequest)];
        [self.playMusicBarButton setEnabled:NO];
        
        self.songsArray = [NSArray array];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.statusLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    // [UIColor underPageBackgroundColor];
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
    
    self.songListTableView.frame = CGRectMake(5, CGRectGetMaxY(self.songListLabelBackgroundView.frame) - 10, self.view.frame.size.width - 10, self.view.frame.size.height - (CGRectGetMaxY(self.songListLabelBackgroundView.frame) - 5));
    
    self.songListTableView.delegate = self;
    self.songListTableView.dataSource = self;
    
    self.songListTableView.layer.cornerRadius = 5.0f;
    self.songListTableView.layer.borderWidth = 1.0f;
    self.songListTableView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    [self.songListTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongNameCell"];
    
    [self.songTransferProgressPopup setFrame:CGRectMake(0, 0, 200, 200)];
    [self.songTransferProgressPopup setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
    [self.songTransferProgressPopup.infoLabel setText:@"Broadcasting song to everyone in your party"];
    [self.songTransferProgressPopup.actionButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.songTransferProgressPopup.actionButton setTitle:@"Cancel" forState:UIControlStateHighlighted];
    [self.songTransferProgressPopup.actionButton addTarget:self action:@selector(hideFileTransferPopup) forControlEvents:UIControlEventTouchUpInside];
    
    self.songTransferProgressView.center = CGPointMake(CGRectGetMidX(self.songTransferProgressPopup.bounds), CGRectGetMidY(self.songTransferProgressPopup.bounds) - 17);
    [self.songTransferProgressView setTrackTintColor:[UIColor whiteColor]];
    [self.songTransferProgressView setProgressTintColor:[UIColor darkGrayColor]];
    [self.songTransferProgressPopup setActivityView:self.songTransferProgressView];
    
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
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    self.songsArray = [everything items];
    
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.songListLabel];
    [self.view addSubview:self.songListLabelBackgroundView];
    [self.view addSubview:self.songListTableView];
    
    UIImage *groupIcon = [UIImage imageNamed:@"group.png"];
    UIBarButtonItem *viewClientsConnected = [[UIBarButtonItem alloc] initWithImage:groupIcon style:UIBarButtonItemStyleBordered target:self action:@selector(openClientsConnectedView)];
    [self.navigationItem setRightBarButtonItems:@[viewClientsConnected, self.playMusicBarButton]];
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
        
        //user has no songs in their iPod library
        if([self.songsArray count] == 0){
            self.songListLabelBackgroundView.frame = CGRectMake(self.songListLabelBackgroundView.frame.origin.x, self.songListLabelBackgroundView.frame.origin.y, self.songListLabelBackgroundView.frame.size.width, 45);
            self.songListLabel.text = @"No songs found! Add some songs to your iPod library and try again";
            self.songListLabel.numberOfLines = 0;
            self.songListLabel.textAlignment = NSTextAlignmentCenter;
            [self.songListLabel sizeToFit];
            self.songListTableView.hidden = YES;
        }
        return [self.songsArray count];
    } else {
        return 0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: copy song from ipod library to app directory and send it to all clients connected to the web server
    // URLs to look at: http://stackoverflow.com/questions/4746349/copy-ipod-music-library-audio-file-to-iphone-app-folder
    // https://www.google.ca/search?q=ios+xcode+copy+song+from+ipod+to+app+directory&oq=ios+xcode+copy+song+from+ipod+to+app+directory&aqs=chrome..69i57.5915j0&sourceid=chrome&ie=UTF-8
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showFileTransferPopup];
    [self transferSongToDoumentsDirectoryWithSongIndex:indexPath];
    self.selectedSongIndex = indexPath;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SongNameCell"];
    
    MPMediaItem* song = [self.songsArray objectAtIndex:indexPath.row];
    NSString *songTitle = [song valueForProperty:MPMediaItemPropertyTitle];
    [cell.textLabel setText:songTitle];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

#pragma mark - Music copying methods

- (void)transferSongToDoumentsDirectoryWithSongIndex:(NSIndexPath*)songIndex {
    [self updateStatus:@"exporting song"];
    
    MPMediaItem* song = [self.songsArray objectAtIndex:songIndex.row];
    NSURL *songURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
    NSString *songTitle = [song valueForProperty:MPMediaItemPropertyTitle];
    
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:songURL options:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]
                                      initWithAsset: songAsset
                                      presetName: AVAssetExportPresetPassthrough];
    
    exporter.outputFileType = @"com.apple.m4a-audio";
     NSString *exportFile = [APPLICATION_SONGS_DIRECTORY stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", songTitle]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {        
        [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
    }
    
    NSURL* exportURL = [NSURL fileURLWithPath:exportFile];
    exporter.outputURL = exportURL;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{        	
        [self updateStatus:@"song exported"];        
        NSLog(@"Successfully exported %@", songTitle);
        
        self.numberOfClientsToReceiveSong = [self.razConnectionManager getNumberOfActiveClients];
        [self sendSongToClientsFromURL:exportURL];
    }];
}

- (void) sendSongToClientsFromURL:(NSURL*)songPath {
    [self.razConnectionManager broadcastSongFromURL:songPath];
}

- (void) sendPlayMusicRequest {
    MPMediaItem* song = [self.songsArray objectAtIndex:self.selectedSongIndex.row];
    NSString *songTitle = [NSString stringWithFormat:@"%@%@", [song valueForProperty:MPMediaItemPropertyTitle], @".mp4"];
    [self.razConnectionManager sendPlayMusicRequestWithSongName:songTitle];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", APPLICATION_SONGS_DIRECTORY, songTitle]] error:nil];
    [self.audioPlayer prepareToPlay];
}

#pragma mark - popup management

- (void) showFileTransferPopup {
    [self.view addSubview:self.songTransferProgressPopup];
    self.songListTableView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.songTransferProgressPopup.center = CGPointMake(self.view.center.x, self.view.center.y);
    }];
}

- (void) hideFileTransferPopup {
    [UIView animateWithDuration:0.3f animations:^{
        self.songTransferProgressPopup.frame = CGRectMake(self.songTransferProgressPopup.frame.origin.x, self.view.frame.size.height, self.songTransferProgressPopup.frame.size.width, self.songTransferProgressPopup.frame.size.height);
    } completion:^(BOOL finished) {
        [self.songTransferProgressPopup removeFromSuperview];
        self.songListTableView.userInteractionEnabled = YES;
    }];
}

- (void) cancelSongRequest {
    [self.razConnectionManager cancelSongBroadcast];
}

#pragma mark - BarButtonItem selectors

- (void) openClientsConnectedView {
    ClientsConnectedViewController *ccvc = [[ClientsConnectedViewController alloc] init];
    [self.navigationController pushViewController:ccvc animated:YES];
}

#pragma mark - QServer delegate

- (void)serverDidStart:(NSNotification*)notification {
    [self updateStatus:@"server is running!"];
}

- (void)serverDidStop:(NSNotification*)notification {
    [self updateStatus:@"server is down!"];
}

#pragma mark - FileTransfer notification update

- (void)fileTransferSuccessful:(NSNotification*)notification {
    self.numberOfClientsWhoSuccessfullyReceivedSong++;
    [self updateProgress];
    
    if(self.numberOfClientsWhoSuccessfullyReceivedSong == self.numberOfClientsToReceiveSong){
        [self hideFileTransferPopup];
        self.numberOfClientsToReceiveSong = 0;
        self.numberOfClientsWhoSuccessfullyReceivedSong = 0;
        [self.songTransferProgressView setProgress:0];
        [self.playMusicBarButton setEnabled:YES];
    }
}

- (void) updateProgress {
    float progress = self.numberOfClientsWhoSuccessfullyReceivedSong;
    progress /= self.numberOfClientsToReceiveSong;
    [self.songTransferProgressView setProgress:progress];
}

@end
