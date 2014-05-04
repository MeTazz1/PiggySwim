//
//  FireBall.h
//  SKTest
//
//  Created by Christophe Dellac on 2/25/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum
{
    None,
    Left,
    Right
} FireBallDirection;

@interface FireBall : SKSpriteNode

@property (nonatomic) FireBallDirection direction;
@end
