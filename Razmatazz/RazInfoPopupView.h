//
//  RazInfoPopupView.h
//  Razmatazz
//
//  Created by Razvan Bangu on 2013-08-29.
//  Copyright (c) 2013 Razvan Bangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RazInfoPopupView : UIView

@property (nonatomic, strong) UILabel * infoLabel;
@property (nonatomic, strong) UIButton * actionButton;
//@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong) UIView * activityView;

- (id) init;

@end
