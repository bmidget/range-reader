//
//  RangeSdkViewController.h
//  RangeSdk
//
//  Created by David Clift-Reaves on 2/6/14.
//  Copyright (c) 2014 Supermechanical. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RangeSdkViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *headsetLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableSwitch;

@property (weak, nonatomic) IBOutlet UIWebView *webView;


@end
