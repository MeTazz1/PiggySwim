//
//  MyScene.m
//  SKTest
//
//  Created by Christophe Dellac on 2/24/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import "MyScene.h"
#import "FireBall.h"
#import "ResultViewController.h"

// TODO
// 1. Faire la vue de debut, avec animation et buttons play and score
// 2. Quand click ok, lancer la game avec le code existant
// 3. Fin de game ok, retourner sur l'ecran de debut ou ajouter quitter

@implementation MyScene

@synthesize ship = _ship;
@synthesize splashPlayer = _splashPlayer;

static const uint32_t playerCategory    =  0x1 << 0;
static const uint32_t fireballCategory  =  0x1 << 1;
static const uint32_t pipeCategory       =  0x1 << 2;

static UIViewController *_controller;
@synthesize adBannerView = _adBannerView;

+ (SKScene*)sceneWithSize:(CGSize)size forParentController:(UIViewController*)controller
{
    _controller = controller;
    return [MyScene sceneWithSize:size];
}


#pragma mark - 
#pragma mark - Menu stuff

- (void)initMenuView
{
    _menu = YES;
    _menuView = [SKSpriteNode new];
    _adBannerView.alpha = 0.0f;
    SKTexture *backgroundTexture = [SKTexture textureWithImage:[UIImage imageNamed:@"background.jpg"]];
    backgroundTexture.filteringMode = SKTextureFilteringLinear;
    
    _background1 = [SKSpriteNode spriteNodeWithTexture:backgroundTexture size:CGSizeMake(backgroundTexture.size.width, backgroundTexture.size.height + 20)];
    _background1.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    _background2 = [SKSpriteNode spriteNodeWithTexture:backgroundTexture size:CGSizeMake(_background1.size.width, _background1.size.height)];
    _background2.position = CGPointMake(_background1.size.width, CGRectGetMidY(self.frame));
    
    SKTexture *playbuttonTexture = [SKTexture textureWithImage:[UIImage imageNamed:@"fireball.png"]];
    playbuttonTexture.filteringMode = SKTextureFilteringLinear;
    SKSpriteNode *startButton = [SKSpriteNode spriteNodeWithTexture:playbuttonTexture size:CGSizeMake(80, 30)];
    startButton.position = CGPointMake(CGRectGetMidX(self.frame) - 80, CGRectGetMidY(self.frame) - 30);
    startButton.name = @"startButtonNode";

    SKTexture *statbuttonTexture = [SKTexture textureWithImage:[UIImage imageNamed:@"fireball.png"]];
    statbuttonTexture.filteringMode = SKTextureFilteringLinear;
    SKSpriteNode *statButton = [SKSpriteNode spriteNodeWithTexture:statbuttonTexture size:CGSizeMake(80, 30)];
    statButton.position = CGPointMake(CGRectGetMidX(self.frame) + 80, CGRectGetMidY(self.frame) - 30);
    statButton.name = @"statButtonNode";

    [_menuView addChild:_background1];
    [_menuView addChild:_background2];
    [_menuView addChild:startButton];
    [_menuView addChild:statButton];
    [self addChild:_menuView];
}

- (void)launchGame
{
    _menu = NO;
    [_menuView removeAllChildren];
    [_menuView removeFromParent];
    [self initGame];
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replayAfterResult) name:@"kReplayGame" object:nil];
        
        NSError *error;
        NSURL * backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"Game-Break" withExtension:@"mp3"];
        _splashPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
        _splashPlayer.numberOfLoops = 1;
        [_splashPlayer prepareToPlay];
        [self createAdBannerView];
        [self initMenuView];
    }
    return self;
}

- (void)initGame
{
    _step = 1;
    _shipAlive = YES;
    _updatePosition = 0;
    _count = 0;
    _nodeList = [NSMutableArray new];
    _fireballList = [NSMutableArray new];

    if (![[self children] containsObject:_background1])
    {
        [self addChild:_background1];
        [self addChild:_background2];
    }

    if (_countLabel == nil)
    {
        _countLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        _countLabel.fontSize = 30;
        _countLabel.position = CGPointMake(50,
                                           CGRectGetMaxY(self.frame) - 50);
    }
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    [self addChild:_countLabel];
    
    if (_ship == nil)
    {
        _ship = [[SKSpriteNode alloc] init];
        _ship = [SKSpriteNode spriteNodeWithImageNamed:@"egg.png"];
        _ship.name = @"Ship";
        _ship.size = CGSizeMake(40, 60);
        _ship.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_ship.size.width / 2];
        _ship.physicsBody.dynamic = YES;
        _ship.physicsBody.usesPreciseCollisionDetection = YES;
        _ship.physicsBody.categoryBitMask = playerCategory;
    }
    _ship.position = CGPointMake(100, CGRectGetMidY(self.frame) + 200);
    
    SKAction *action = [SKAction rotateToAngle:2 * M_PI duration:1];
    [_ship runAction:action];
    
    _adBannerView.alpha = 1.0f;
    [self addChild:_ship];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    if (!_menu)
    {
        _ship.physicsBody.velocity = self.physicsBody.velocity;
        [_ship.physicsBody applyImpulse:CGVectorMake(0.0f, 25.0f)];
        
        SKAction *rotationAction = [SKAction rotateByAngle:0.4 duration:0.2];
        SKAction *action = [SKAction sequence:@[rotationAction, [SKAction runBlock:^{
            [_ship runAction:[SKAction rotateByAngle:-0.4 duration:0.5]];
        }]]];
        [_ship runAction:[SKAction repeatAction:action count:1]];
        [self runAction:[SKAction playSoundFileNamed:@"bubble.mp3" waitForCompletion:NO]];
    }
    else
    {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInNode:self];
        SKNode *node = [self nodeAtPoint:location];
        
        //if fire button touched, bring the rain
        if ([node.name isEqualToString:@"startButtonNode"])
        {
            [self launchGame];
        }
    }
}

- (void)replayAfterResult
{
    if (_shipAlive == NO)
    {
        [self clearGame];
        [self initGame];
    }
}

- (void)clearGame
{
    [self removeAllChildren];
    [self removeAllActions];
    [_nodeList removeAllObjects];
    _nodeList = nil;
    
    [_fireballList removeAllObjects];
    _fireballList = nil;
    
    _count = 0;
    _updatePosition = 0;
    
    [_countLabel setText:@""];
    
}

- (void)replayGame
{
    _adBannerView.alpha = 1.0f;
    
    ResultViewController *result = [ResultViewController new];
    result.count = _count - 3;
    [_controller presentPopupViewController:result animationType:MJPopupViewAnimationSlideBottomTop];
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    [self runAction:[SKAction playSoundFileNamed:@"Game-Break.mp3" waitForCompletion:NO]];
    if (_shipAlive == YES)
        [self performSelector:@selector(replayGame) withObject:self afterDelay:0.5f];
    _shipAlive = NO;
}

- (void)generateFireBallForNode:(SKSpriteNode*)node
{
    if (arc4random() % 400 <= (2 + _count / 50))
    {
        FireBall *newFireBall = [FireBall spriteNodeWithTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"fireball.png"]] size:CGSizeMake(25, 25)];
        newFireBall.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:newFireBall.size.width / 2];
        newFireBall.physicsBody.dynamic = NO;
        newFireBall.physicsBody.categoryBitMask = fireballCategory;
        newFireBall.physicsBody.contactTestBitMask = playerCategory;
        newFireBall.physicsBody.collisionBitMask = 0;
        newFireBall.position = CGPointMake(node.position.x, CGRectGetMaxY(node.frame));
        switch (_step) {
            case 1:
                newFireBall.direction = None;
                break;
            case 2:
                newFireBall.direction = arc4random() % 2;
                break;
            case 3:
                newFireBall.direction = arc4random() % 3;
                break;
            default:
                newFireBall.direction = arc4random() % 3;
                break;
        }
        
        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
        [newFireBall runAction:[SKAction repeatActionForever:action]];
        [self addChild:newFireBall];
        [_fireballList addObject:newFireBall];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (_shipAlive == NO && _menu == NO)
        return;
    _updatePosition += 2;
    
    [_background1 setPosition:CGPointMake(_background1.position.x - 2, _background1.position.y)];
    [_background2 setPosition:CGPointMake(_background2.position.x - 2, _background2.position.y)];
    if (_background2.position.x == 0 || _background2.position.x == 1)
        [_background1 setPosition:CGPointMake(_background1.size.width, _background1.position.y)];
    if (_background1.position.x == 0 || _background1.position.x == 1)
        [_background2 setPosition:CGPointMake(_background1.size.width, _background1.position.y)];
    
    if (_count - 3 > 0)
    {
        // hide iAd
        _adBannerView.alpha = 0.0f;

        [_countLabel setText:[NSString stringWithFormat:@"%i", _count - 3]];
    }
    
    if (_count > 0 && _updatePosition % 5000 == 0)
        ++_step;

    if (_updatePosition % 150 == 0)
    {
        ++_count;
        SKSpriteNode *newPipe = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"plante.png"]] size:CGSizeMake(50, 100)];
        newPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:newPipe.frame];
        newPipe.physicsBody.categoryBitMask = pipeCategory;
        newPipe.physicsBody.contactTestBitMask = playerCategory;
        newPipe.position = CGPointMake(CGRectGetMaxX(self.frame) + 250, newPipe.size.height / 2);
        [self addChild:newPipe];
        [_nodeList addObject:newPipe];
    }
    
    for (SKSpriteNode *node in [_nodeList copy])
    {
        node.position = CGPointMake(node.position.x - 2, node.position.y);
        if (node.position.x < -node.size.width)
            [_nodeList removeObject:node];
        [self generateFireBallForNode:node];
    }
    
    for (FireBall *ball in [_fireballList copy])
    {
        switch (ball.direction) {
            case None:
                ball.position = CGPointMake(ball.position.x - 2, ball.position.y + 2);
                break;
            case Left:
                ball.position = CGPointMake(ball.position.x - 3, ball.position.y + 2);
                break;
            case Right:
                ball.position = CGPointMake(ball.position.x - 1, ball.position.y + 2);
                break;
            default:
                break;
        }
        if (ball.position.x < -ball.size.width)
            [_fireballList removeObject:ball];
            
    }
}

#pragma mark -
#pragma mark - iAd

- (void) adjustBannerView
{
    CGRect contentViewFrame = CGRectMake(0, 0, self.view.frame.size.width, 50);
    CGRect adBannerFrame = self.adBannerView.frame;
    
    if ([self.adBannerView isBannerLoaded])
    {
        CGSize bannerSize = [ADBannerView sizeFromBannerContentSizeIdentifier:self.adBannerView.currentContentSizeIdentifier];
        contentViewFrame.size.height = contentViewFrame.size.height - bannerSize.height;
        adBannerFrame.origin.y = 0;
    }
    else
    {
        adBannerFrame.origin.y = self.view.frame.size.height - _adBannerView.frame.size.height;
    }
    [UIView animateWithDuration:2.0 animations:^{
        self.adBannerView.frame = adBannerFrame;
        [self.view addSubview:self.adBannerView];
    }];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self adjustBannerView];
    
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (_adBannerView)
    {
        _adBannerView.alpha = 0.0f;
        
        if ([_adBannerView respondsToSelector:@selector(removeFromSuperview)])
            [UIView animateWithDuration:2.0 animations:^{
                [_adBannerView removeFromSuperview];
            }];
        _adBannerView = nil;
        
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    NSLog(@"finish");
}

- (void) createAdBannerView
{
    _adBannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    CGRect bannerFrame = self.adBannerView.frame;
    bannerFrame.origin.y = 0;
    self.adBannerView.frame = bannerFrame;
    self.adBannerView.delegate = self;
}


@end
