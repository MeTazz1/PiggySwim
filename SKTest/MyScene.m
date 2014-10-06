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

@synthesize turtle = _turtle;
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

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replayAfterResult) name:@"kReplayGame" object:nil];
        
        NSError *error;
        NSURL * backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"Game-Break" withExtension:@"mp3"];
        _splashPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
        _splashPlayer.numberOfLoops = 1;
        [_splashPlayer prepareToPlay];
        
        NSMutableArray *bubbleFrames = [NSMutableArray new];
        SKTextureAtlas *bubbleAnimated = [SKTextureAtlas atlasNamed:@"Bubbles"];
        NSInteger numImages = bubbleAnimated.textureNames.count;
        
        for (int i = 1; i < numImages; ++i)
        {
            NSString *textureName = [NSString stringWithFormat:@"bubble%d.png", i];
            SKTexture *tmp = [bubbleAnimated textureNamed:textureName];
            [bubbleFrames addObject:tmp];
        }
        _bubbleFrames = bubbleFrames;
        _bubbles = [SKSpriteNode spriteNodeWithTexture:_bubbleFrames[0]];
        _bubbles.xScale = 0.2;
        _bubbles.yScale = 0.2;
        [self createAdBannerView];
        [self initMenuView];
    }
    return self;
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
    
    SKTexture *playbuttonTexture = [SKTexture textureWithImage:[UIImage imageNamed:@"play.png"]];
    playbuttonTexture.filteringMode = SKTextureFilteringLinear;
    SKSpriteNode *startButton = [SKSpriteNode spriteNodeWithTexture:playbuttonTexture size:CGSizeMake(130, 130)];
    startButton.position = CGPointMake(CGRectGetMidX(self.frame) - 75, CGRectGetMidY(self.frame) - 30);
    startButton.name = @"startButtonNode";

    SKTexture *statbuttonTexture = [SKTexture textureWithImage:[UIImage imageNamed:@"stats.png"]];
    statbuttonTexture.filteringMode = SKTextureFilteringLinear;
    SKSpriteNode *statButton = [SKSpriteNode spriteNodeWithTexture:statbuttonTexture size:CGSizeMake(130, 130)];
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
        _countLabel.position = CGPointMake(self.view.frame.size.width - 70,
                                           CGRectGetMaxY(self.frame) - 80);
    }
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    [self addChild:_countLabel];
    
    if (_turtle == nil)
    {
        _turtle = [SKSpriteNode spriteNodeWithImageNamed:@"egg.png"];
        _turtle.name = @"Ship";
        _turtle.size = CGSizeMake(50, 60);
        _turtle.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_turtle.size.width / 2];
        _turtle.physicsBody.dynamic = YES;
        _turtle.physicsBody.usesPreciseCollisionDetection = YES;
        _turtle.physicsBody.categoryBitMask = playerCategory;
    }
    [_turtle setTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"egg.png"]]];
    _turtle.position = CGPointMake(100, CGRectGetMidY(self.frame) + 200);
    _bubbles.position = _turtle.position;
    [self addChild:_bubbles];

    [_bubbles runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:_bubbleFrames
                                                                       timePerFrame:0.4f
                                                                             resize:NO
                                                                            restore:YES]] withKey:@"bubbleAnimated"];


    SKAction *action = [SKAction rotateToAngle:2 * M_PI duration:1];
    [_turtle runAction:action];
    [SKView animateWithDuration:0.5f animations:^{
        _adBannerView.alpha = 1.0f;
    }];
    [self addChild:_turtle];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    if (!_menu && _shipAlive)
    {
        _turtle.physicsBody.velocity = self.physicsBody.velocity;
        [_turtle.physicsBody applyImpulse:CGVectorMake(0.0f, 40.0f)];
        
        SKAction *rotationAction = [SKAction rotateByAngle:0.4 duration:0.2];
        SKAction *action = [SKAction sequence:@[rotationAction, [SKAction runBlock:^{
            [_turtle runAction:[SKAction rotateByAngle:-0.4 duration:0.5]];
        }]]];
        [_turtle runAction:[SKAction repeatAction:action count:1]];
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
    [SKView animateWithDuration:0.5f animations:^{
        _adBannerView.alpha = 1.0f;
    }];
    
    ResultViewController *result = [ResultViewController new];
    result.count = _count - 2;
    [_controller presentPopupViewController:result animationType:MJPopupViewAnimationSlideBottomTop];
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    [self runAction:[SKAction playSoundFileNamed:@"Game-Break.mp3" waitForCompletion:NO]];
    [_bubbles removeFromParent];
    [_turtle setTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"deadPiggy.png"]]];
    if (_shipAlive == YES)
        [self performSelector:@selector(replayGame) withObject:self afterDelay:0.5f];
    _shipAlive = NO;
}

- (void)generateFireBallForNode:(SKSpriteNode*)node
{
    if (arc4random() % 1000 <= (2 + _count / 50))
    {
        FireBall *newFireBall = [FireBall spriteNodeWithTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"fireball.png"]] size:CGSizeMake(30, 30)];
        newFireBall.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:newFireBall.size.width / 2];
        newFireBall.physicsBody.dynamic = NO;
        newFireBall.physicsBody.categoryBitMask = fireballCategory;
        newFireBall.physicsBody.contactTestBitMask = playerCategory;
        newFireBall.physicsBody.collisionBitMask = 0;
        
        NSLog(@"node pos y = %f comparing to %f", node.position.y, (self.view.frame.size.height - (node.size.height / 2)));
        if ((int)node.position.y == (int)(self.view.frame.size.height - (node.size.height / 2)))
        {
            newFireBall.position = CGPointMake(node.position.x, self.view.frame.size.height - node.size.height);
            newFireBall.orientation = BOTTOM;
        }
        else
        {
            newFireBall.position = CGPointMake(node.position.x, CGRectGetMaxY(node.frame));
            newFireBall.orientation = TOP;
        }
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
    
    _bubbles.position = CGPointMake(_turtle.position.x + 20, _turtle.position.y + 40);
    [_background1 setPosition:CGPointMake(_background1.position.x - 2, _background1.position.y)];
    [_background2 setPosition:CGPointMake(_background2.position.x - 2, _background2.position.y)];
    if (_background2.position.x == 0 || _background2.position.x == 1)
        [_background1 setPosition:CGPointMake(_background1.size.width, _background1.position.y)];
    if (_background1.position.x == 0 || _background1.position.x == 1)
        [_background2 setPosition:CGPointMake(_background1.size.width, _background1.position.y)];
    
    if (_count - 2 > 0)
    {
        // hide iAd
        [SKView animateWithDuration:0.5f animations:^{
            _adBannerView.alpha = 0.0f;
        }];

        [_countLabel setText:[NSString stringWithFormat:@"%i", _count - 2]];
    }
    
    if (_count > 0 && _updatePosition % 3000 == 0)
        ++_step;

    if (_updatePosition % 150 == 0 && _shipAlive)
    {
        ++_count;
        SKSpriteNode *newPipe = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:[UIImage imageNamed:@"plante.png"]] size:CGSizeMake(50, 100)];
        newPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:newPipe.frame];
        newPipe.physicsBody.categoryBitMask = pipeCategory;
        newPipe.physicsBody.contactTestBitMask = playerCategory;
        
        if (_step < 1)
            newPipe.position = CGPointMake(150 + 250, newPipe.size.height / 2);
        else
        {
            if (arc4random() % 2 == 1)
            {
                newPipe.yScale = -1;
                newPipe.position = CGPointMake(150 + 250, self.view.frame.size.height - (newPipe.size.height / 2));
            }
            else
                newPipe.position = CGPointMake(150 + 250, newPipe.size.height / 2);
        }
        
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
                ball.position = CGPointMake(ball.position.x - 2, ball.orientation == TOP ? ball.position.y + 2 : ball.position.y - 2);
                break;
            case Left:
                ball.position = CGPointMake(ball.position.x - 3, ball.orientation == TOP ? ball.position.y + 2 : ball.position.y - 2);
                break;
            case Right:
                ball.position = CGPointMake(ball.position.x - 1, ball.orientation == TOP ? ball.position.y + 2 : ball.position.y - 2);
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
