//
//  MyScene.h
//  SKTest
//

//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIViewController+MJPopupViewController.h"
#import <iAd/iAd.h>

@interface MyScene : SKScene <SKPhysicsContactDelegate, ADBannerViewDelegate, UITextViewDelegate>
{
    SKSpriteNode *_background1;
    SKSpriteNode *_background2;
    SKSpriteNode *_menuView;
    
    
    NSArray *_bubbleFrames;
    SKSpriteNode *_bubbles;
    
    NSMutableArray *_nodeList;
    NSMutableArray *_fireballList;
    
    SKLabelNode *_countLabel;
    int _count;
    int _updatePosition;
    
    BOOL _shipAlive;
    BOOL _menu;
    int _step;
}

@property (nonatomic) AVAudioPlayer *splashPlayer;
@property (nonatomic, retain) SKSpriteNode *turtle;
@property (nonatomic, retain) ADBannerView *adBannerView;

+ (SKScene*)sceneWithSize:(CGSize)size forParentController:(UIViewController*)controller;

@end
