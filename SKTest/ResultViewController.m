//
//  ResultViewController.m
//  SKTest
//
//  Created by Christophe Dellac on 3/3/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import "ResultViewController.h"
#import "UIViewController+MJPopupViewController.h"

@interface ResultViewController ()

@property (nonatomic, retain) IBOutlet UILabel *pointLabel;

@end

@implementation ResultViewController

@synthesize count = _count;
@synthesize pointLabel = _pointLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_pointLabel setText:[NSString stringWithFormat:@"You scored %d points bro", _count]];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareResult
{
    [self sendFacebook:nil];
}

- (IBAction)replay
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideBottomTop];
}

#pragma mark -
#pragma mark - Social

-(void)sendFacebook:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *accountTypeFacebook =
    [accountStore accountTypeWithAccountTypeIdentifier:
     ACAccountTypeIdentifierFacebook];
    
    [accountStore requestAccessToAccountsWithType:accountTypeFacebook options:@{
                                                                                ACFacebookAppIdKey: @"792456587448676",
                                                                                ACFacebookPermissionsKey: @[@"email"],
                                                                                ACFacebookAudienceKey: ACFacebookAudienceOnlyMe
                                                                                } completion:^(BOOL granted, NSError *error) {
                                                                                    
                                                                                    if(granted) {
                                                                                        
                                                                                        
                                                                                        NSDictionary *options = @{
                                                                                                                  ACFacebookAppIdKey: @"792456587448676",
                                                                                                                  ACFacebookPermissionsKey: @[@"publish_stream",
                                                                                                                                              @"publish_actions"],
                                                                                                                  ACFacebookAudienceKey: ACFacebookAudienceOnlyMe
                                                                                                                  };
                                                                                        
                                                                                        [accountStore requestAccessToAccountsWithType:accountTypeFacebook
                                                                                                                              options:options
                                                                                                                           completion:^(BOOL granted, NSError *error) {
                                                                                                                               
                                                                                                                               if (granted) {
                                                                                                                                   
                                                                                                                                   NSArray *accounts = [accountStore
                                                                                                                                                        accountsWithAccountType:accountTypeFacebook];
                                                                                                                                   _facebookAccount = [accounts lastObject];
                                                                                                                                   
                                                                                                                                   NSDictionary *parameters =
                                                                                                                                   @{@"access_token":_facebookAccount.credential.oauthToken,
                                                                                                                                     @"message": [NSString stringWithFormat:@"Check that score bro at #CanTotuFly! %d points", _count]};
                                                                                                                                   
                                                                                                                                   NSURL *feedURL = [NSURL
                                                                                                                                                     URLWithString:@"https://graph.facebook.com/me/photos"];
                                                                                                                                   
                                                                                                                                   SLRequest *feedRequest =
                                                                                                                                   [SLRequest
                                                                                                                                    requestForServiceType:SLServiceTypeFacebook
                                                                                                                                    requestMethod:SLRequestMethodPOST
                                                                                                                                    URL:feedURL
                                                                                                                                    parameters:parameters];
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"fireball.png"]);
                                                                                                                                   [feedRequest addMultipartData:imageData withName:@"picture" type:@"image/png" filename:@"fireba.png"];
                                                                                                                                   
                                                                                                                                   [feedRequest 
                                                                                                                                    performRequestWithHandler:^(NSData *responseData,
                                                                                                                                                                NSHTTPURLResponse *urlResponse, NSError *error)
                                                                                                                                    {
                                                                                                                                        NSLog(@"Request failed, %@", 
                                                                                                                                              [urlResponse description]);
                                                                                                                                    }];
                                                                                                                                   
                                                                                                                               }
                                                                                                                               else
                                                                                                                               {
                                                                                                                                   NSLog(@"Access Denied");
                                                                                                                                   NSLog(@"[%@]",[error localizedDescription]);
                                                                                                                               }
                                                                                                                           }];
                                                                                    }
                                                                                }];
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

@end
