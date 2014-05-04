//
//  ResultViewController.h
//  SKTest
//
//  Created by Christophe Dellac on 3/3/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ResultViewController : UIViewController

- (IBAction)shareResult;
- (IBAction)replay;

@property (nonatomic) int count;
@property ACAccount* facebookAccount;

@end
