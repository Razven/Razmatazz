//
//  RazInfoPopupView.m
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-29.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import "RazInfoPopupView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RazInfoPopupView

- (id) init {
    self = [super init];
    
    if(self) {
        self.infoLabel = [[UILabel alloc] init];
        self.actionButton = [[UIButton alloc] init];
//        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    
    return self;
}

- (void)layoutSubviews {
    self.layer.cornerRadius = 3.0f;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 1.0f;
    self.backgroundColor = [UIColor darkGrayColor];
    self.clipsToBounds = YES;
    
    [self.infoLabel setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.infoLabel setNumberOfLines:0];
    [self.infoLabel sizeToFit];
    [self.infoLabel setFrame:CGRectMake(0, 0, self.frame.size.width, self.infoLabel.frame.size.height)];
    [self.infoLabel setBackgroundColor:[UIColor clearColor]];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.backgroundColor = [UIColor lightGrayColor];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    
    self.actionButton.frame = CGRectMake(0, self.frame.size.height * 2.0f / 3.0f, self.frame.size.width / 3, 30);
    self.actionButton.center = CGPointMake(CGRectGetMidX(self.bounds), self.actionButton.center.y);
    self.actionButton.layer.cornerRadius = 3.0f;
    self.actionButton.layer.borderWidth = 1.0f;
    self.actionButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.actionButton.backgroundColor = [UIColor lightGrayColor];
    
    [self addSubview:self.infoLabel];
    [self addSubview:self.actionButton];
    
    if(self.activityView){
        [self addSubview:self.activityView];
    }
}

@end
