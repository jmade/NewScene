//
//  GameViewController.h
//  NewScene
//

//  Copyright (c) 2015 Justin Madewell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
@import SpriteKit;

typedef NS_OPTIONS(NSUInteger, CollisionCategory) {
    CollisionCategoryBlock    = 1 << 0,
    CollisionCategoryBall     = 1 << 1,
    CollisionCategoryFloor     = 1 << 2,
};

@interface GameViewController : UIViewController <SCNPhysicsContactDelegate, SCNSceneRendererDelegate>

@end
