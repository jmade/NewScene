//
//  GameViewController.m
//  NewScene
//
//  Created by Justin Madewell on 6/16/15.
//  Copyright (c) 2015 Justin Madewell. All rights reserved.
//

#import "GameViewController.h"
#import "SceneKit Additions.h"
#import "JDMRobotArmNode.h"


// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

#define RANDOM_BOOL     (BOOL)((NSInteger)random() % 2)

#define GRID_WIDTH 4
#define GRID_HEIGHT 6
#define GRID_DEPTH 4

#define RESTACK_TIME 0.85
#define FLASH_TIME 0.20


#pragma mark - Category Mask

static const uint32_t blockCategory     =  0x1 << 0; //00000000000000000000000000000001 - 1
static const uint32_t ballCategory      =  0x1 << 1; //00000000000000000000000000000010 - 2
static const uint32_t floorCategory     =  0x1 << 2; //00000000000000000000000000000100 - 4
static const uint32_t wallCategory      =  0x1 << 3; //00000000000000000000000000001000 - 8
static const uint32_t fieldCategory     =  0x1 << 4; //00000000000000000000000000010000 - 16
                                                     //static const uint32_t robotCategory     =  0x1 << 5; //00000000000000000000000000100000 - 32


@interface GameViewController ()
{
    dispatch_source_t _timer;
    
    SCNScene *_scene;
    
    NSArray *_blocks;
    NSMutableArray *_redBlocks;
    
    BOOL _ballHasBeenThrown;
    BOOL _ballIsVisible;
    BOOL _isExploded;
    BOOL _hasBeenExploded;
    
    SCNNode *_ballNode;
    SCNNode *_physicsCageNode;
    SCNNode *_blocksNode;
    SCNNode *_floorNode;
    
    NSMutableDictionary *_transforms;
    NSMutableArray *_hinges;
    
    SCNGeometry *_blockReferenceGeometry;
    
    SCNIKConstraint *_ik;
    
    BOOL _goingUp;
    
    JDMRobotArmNode *_robotArmNodeLeft;
    JDMRobotArmNode *_robotArmNodeRight;
    JDMRobotArmNode *_robotNode;
    
   
}

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SCNScene *scene = [SCNScene sceneNamed:@"testScene.scnassets/testScene.scn"];
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene;
    scnView.delegate = self;
    _scene = scene;
    _scene.physicsWorld.contactDelegate = self;
    
    [self setBitMasks];
    
    
    [self setupForBlocks];
    
    
    // [self fastTrack];
    
  }

-(void)setupForArm
{
    SCNView *scnView = (SCNView *)self.view;
    scnView.gestureRecognizers = [self gestureRecsForArm];
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
    _goingUp = YES;
    
    [self arm];
    
}



-(void)setupForBlocks
{
    SCNView *scnView = (SCNView *)self.view;
    scnView.gestureRecognizers = [self gestureRecsForBlocks];
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;

    
    
    // Setup For blocks
    _ballHasBeenThrown = NO;
    _isExploded = NO;
    _blockReferenceGeometry = [self makeBlockGeometry];
    _hasBeenExploded = NO;
    _redBlocks = [[NSMutableArray alloc]init];
    _hinges = [NSMutableArray array];
    
    [self makeBlocks];
    [self makeAndPlaceBall];
    [self setBitMasks];
    
    
}


-(NSArray*)gestureRecsForBlocks
{
    // add a tap gesture recognizer
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    [gestureRecognizers addObject:tapGesture];
    
    // double tap
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTouchesRequired = 2;
    [gestureRecognizers addObject:doubleTap];
    
    return gestureRecognizers;
}


-(NSArray*)gestureRecsForArm
{
    // add a tap gesture recognizer
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapForArm:)];
    
    [gestureRecognizers addObject:tapGesture];
    
    // double tap
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTouchesRequired = 2;
    //[gestureRecognizers addObject:doubleTap];
    
    return gestureRecognizers;
}






#pragma mark - Gestures
- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    
    [self demoMode];
}







- (void)handleTapForArm:(UIGestureRecognizer*)gestureRecognize
{
    
    static int checker;
    checker++;
    
    if (checker == 1) {
        NSLog(@"Activating Constraints");
        
        [_robotNode activateIKConstraints];
        return;
    }
    
    if (checker == 2) {
        NSLog(@"Second Tap");
        
        
        
        return;
    }
    
    [self handleforIKMove];
    

}

-(void)handleforIKMove
{
    SCNVector3 toPos;
    
    if (_goingUp) {
        SCNVector3 pos = [_scene.rootNode childNodeWithName:@"targetObject" recursively:YES].position;
        pos = [_scene.rootNode childNodeWithName:@"camera" recursively:YES].position;
        toPos = pos;
    }
    else
    {
        SCNVector3 start = AddVectors(_robotNode.position, SCNVector3Make(0, -10, 0));
        //start = [_scene.rootNode childNodeWithName:@"camera" recursively:YES].position;
        toPos = start;
    }
    
    
    [_robotNode updateTargetPosition:toPos];
    [_robotNode animateFace];
    
    if (_goingUp) {
        _goingUp = NO;
    }
    else
    {
        _goingUp = YES;
    }

}



-(void)handleDoubleTap:(UIGestureRecognizer*)doubleTapRecognizer
{
    [self clearBlocks];
}



#pragma mark - Clear Blocks
-(void)clearBlocks
{
    SCNVector3 center = SCNVector3Make(0,-5,20);
    center = [_floorNode convertPosition:center toNode:nil];
    
    
    [self explosionAt:center receivers:_redBlocks];
}


- (void)explosionAt:(SCNVector3)center receivers:(NSArray *)nodes
{
    GLKVector3 c = SCNVector3ToGLKVector3(center);
    
    for(SCNNode *node in nodes){
        GLKVector3 p = SCNVector3ToGLKVector3(node.presentationNode.position);
        GLKVector3 dir = GLKVector3Subtract(p, c);
        
        float force = 25;
        float distance = GLKVector3Length(dir);
        
        dir = GLKVector3MultiplyScalar(dir, force / MAX(0.01, distance));
        
        [node.physicsBody applyForce:SCNVector3FromGLKVector3(dir) atPosition:SCNVector3Make(randSCNFloat(-0.2, 0.2), randSCNFloat(-0.2, 0.2), randSCNFloat(-0.2, 0.2)) impulse:YES];
        
        [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:2], [SCNAction fadeOutWithDuration:0.5], [SCNAction removeFromParentNode]]]];
    }
}

-(void)clearCubes
{
    SCNVector3 center = SCNVector3Make(0,-5,20);
    center = [_floorNode convertPosition:center toNode:nil];
    
    NSMutableArray *cubesAndBall =  [NSMutableArray arrayWithArray:_blocks];
    [cubesAndBall addObject:_ballNode];
    
    
    [self explosionAt:center receivers:cubesAndBall];

    
}


#pragma mark - Camera animation

-(void)moveCameraToRobot
{
    SCNNode *cameraNode = [_scene.rootNode childNodeWithName:@"camera" recursively:YES];
    SCNVector3 currentPos = cameraNode.position;
    
    LogSCNVector3(currentPos, @"OG POS");
   
    
    SCNVector3 moveAmount = SCNVector3Make(-6.9, -5, -6);
    
    SCNVector3 newPosition = AddVectors(moveAmount, currentPos);
    
    
    //move the camera IN
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration: 1.0];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    // Change properties
    cameraNode.position = newPosition;
    [SCNTransaction commit];

    
    
    
}

-(void)moveCameraWayBack
{
    SCNNode *cameraNode = [_scene.rootNode childNodeWithName:@"camera" recursively:YES];
    SCNVector3 currentPos = cameraNode.position;
    
    LogSCNVector3(currentPos, @"OG POS");
    
    
    SCNVector3 moveAmount = SCNVector3Make(25, 10, 25);
    
    SCNVector3 newPosition = AddVectors(moveAmount, currentPos);
    
    
    //move the camera IN
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration: 1.0];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    // Change properties
    cameraNode.position = newPosition;
    [SCNTransaction commit];
    

}


-(void)moveCameraToStack
{
    SCNNode *cameraNode = [_scene.rootNode childNodeWithName:@"camera" recursively:YES];
    SCNVector3 currentPos = cameraNode.position;
    
    LogSCNVector3(currentPos, @"OG POS");
    
    
    SCNVector3 moveAmount = SCNVector3Make(-20, -5, -15);
    
    SCNVector3 newPosition = AddVectors(moveAmount, currentPos);
    
    
    //move the camera IN
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration: 0.5];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    // Change properties
    cameraNode.position = newPosition;
    [SCNTransaction commit];
    

}


-(void)returnCamera
{
    //move the camera IN
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration: 1.0];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    // Change properties
    [_scene.rootNode childNodeWithName:@"camera" recursively:YES].position = SCNVector3Make(32.28, 9.46, 28.69);
    [SCNTransaction commit];

}


#pragma mark - Hinge

-(void)hingeMethod
{
    int count = 10;
    
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents = [UIColor whiteColor];
    material.specular.contents = [UIColor whiteColor];
    material.locksAmbientWithDiffuse = YES;
    
    CGFloat cubeWidth = 10./count;
    CGFloat cubeHeight = 0.2;
    CGFloat cubeLength = 1.0;
    CGFloat offset = 1.0;
//    CGFloat height = 5 + count * cubeWidth;
    CGFloat height = 1 + count * cubeWidth;
    
    
    SCNNode *oldModel = nil;
    for (int i = 0; i < count; ++i) {
        SCNNode *model = [SCNNode node];
        
        SCNMatrix4 worldtr = [_floorNode convertTransform:SCNMatrix4MakeTranslation(-offset + cubeWidth * i, height, 0.5) toNode:nil];
        
        model.transform = worldtr;
        
        model.geometry = [SCNBox boxWithWidth:cubeWidth height:cubeHeight length:cubeLength chamferRadius:0];
        model.geometry.firstMaterial = material;
        
        SCNPhysicsBody *body = [SCNPhysicsBody dynamicBody];
        body.restitution = 0.5;
        body.mass = 8;
        model.physicsBody = body;
        
        [_scene.rootNode addChildNode:model];
        [_hinges addObject:model];
        
        SCNPhysicsHingeJoint *joint = [SCNPhysicsHingeJoint jointWithBodyA:model.physicsBody axisA:SCNVector3Make(0, 0, 1) anchorA:SCNVector3Make(-cubeWidth*0.5, 0, 0) bodyB:oldModel.physicsBody axisB:SCNVector3Make(0, 0, 1) anchorB:SCNVector3Make(cubeWidth*0.5, 0, 0)];
        
        [_scene.physicsWorld addBehavior:joint];
        
        oldModel = model;
    }
}

-(void)removeHinges
{
    NSLog(@"Removing Hinges");
    
    [_scene.physicsWorld removeAllBehaviors];
    
    for (SCNNode *node in _hinges) {
        [node runAction:[SCNAction sequence:@[[SCNAction fadeOutWithDuration:0.5],[SCNAction removeFromParentNode]]]];
    }
}






#pragma mark - IK
#pragma mark - Arm Creation
// This call makes a new Arm Node and places it into the scene
// Main Arm Node
// adding that to scene
-(void)arm
{
    _robotNode = [JDMRobotArmNode makeRobot];
    _robotNode.position = [self roboArmPosition:_robotNode];
    
    SCNVector3 newPos = SCNVector3Make(_robotNode.position.x+10, _robotNode.position.y-2.8, _robotNode.position.z+6);
    
    LogSCNVector3(newPos, @"New Robot Pos");
    

    _robotNode.position = newPos;

    
    
    // flip robot node around
    _robotNode.rotation = SCNVector4Make(0, 1, 0, DEGREES_TO_RADIANS(215));
    
  
    // make object for robot
    // [self addTargetObjectForNode:_robotNode];
    
    _robotNode.opacity = 0;
    
    [_scene.rootNode addChildNode:_robotNode];
    
    [_robotNode runAction:[SCNAction fadeInWithDuration:0.25]];
    
}




-(void)addTargetObjectForNode:(SCNNode*)node
{
    SCNNode *objectNode = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:0.5 height:0.5 length:0.5 chamferRadius:0.0125]];
    objectNode.name = @"targetObject";
    
    SCNVector3 newTargetPosition = AddVectors(_robotNode.position, SCNVector3Make(4, 0, 6));
    
    
    // objectNode.position = [self targetPositionForObjectNodeConsideringNode:node];
    objectNode.position = newTargetPosition;
    
    [_scene.rootNode addChildNode:objectNode];
}


-(SCNVector3)roboArmPosition:(SCNNode*)roboArmNode
{
    CGFloat corneredXZ = 8;
    
    
    
    
    return [_floorNode convertPosition:SCNVector3Make(corneredXZ, GetNodeSize(roboArmNode).y,corneredXZ) toNode:nil];
    
}


-(SCNVector3)targetPositionForObjectNodeConsideringNode:(SCNNode*)nodeToConsider
{
    return [_floorNode convertPosition:SCNVector3Make(8,(GetNodeSize(nodeToConsider).y * 0.75),8+4) toNode:nil];
}




-(SCNPhysicsBody*)blockPhysicsBodyDynamic:(BOOL)isDynamic
{
    SCNPhysicsShape *blockPhysicsShape = [SCNPhysicsShape shapeWithGeometry:_blockReferenceGeometry options:nil];
    
    SCNPhysicsBody *blockPhysicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:blockPhysicsShape];
    
    if (!isDynamic) {
        blockPhysicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeStatic shape:blockPhysicsShape];
    }
    
    blockPhysicsBody.categoryBitMask = blockCategory;
    
    blockPhysicsBody.collisionBitMask = floorCategory | ballCategory | blockCategory ;
    
    blockPhysicsBody.contactTestBitMask  = floorCategory | ballCategory | fieldCategory;
    
    return blockPhysicsBody;
    
}


#pragma mark - Blocks

-(void)moveVerticalBlocksBack
{
    if (_isExploded) {
         [self restackBlocks];
    }
}

-(void)replaceBlocks
{
    NSMutableDictionary *newTransforms = [NSMutableDictionary dictionary];
    NSMutableArray *newBlocks = [[NSMutableArray alloc]init];
    
    for (SCNNode *node in _blocks) {
        
        SCNNode *replacementNode = [self copyAndRepositionMyself:node];
        
        [newTransforms setValue:[NSValue valueWithSCNMatrix4:replacementNode.transform] forKey:MemoryDescriptionSCN(replacementNode)];
        
        [newBlocks addObject:replacementNode];
    }
    _blocks = newBlocks;
    _transforms = newTransforms;
}




// From Sample code

-(void)makeItRain
{
    int count = 200;
    float spread = 6;
    
    // drop rigid bodies cubes
    CGFloat seconds = 0.75;
    uint64_t intervalTime = NSEC_PER_SEC * seconds / count;
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), intervalTime, 0); // every ms
    
    
    __block NSInteger remainingCount = count;
    dispatch_source_set_event_handler(_timer, ^{
        
        [SCNTransaction begin];
        
        SCNVector3 worldPos = [_floorNode convertPosition:SCNVector3Make(0, 60, 0) toNode:nil];
        
        SCNNode *dice = [self genericBlockNode];
        
        dice.position = worldPos;
        
        //add to scene
        [_scene.rootNode addChildNode:dice];
        
        [dice.physicsBody setVelocity:SCNVector3Make(randSCNFloat(-spread, spread), -10, randSCNFloat(-spread, spread))];
        [dice.physicsBody setAngularVelocity:SCNVector4Make(randSCNFloat(-1, 1),randSCNFloat(-1, 1),randSCNFloat(-1, 1),randSCNFloat(-3, 3))];
        [SCNTransaction commit];
        
        [_redBlocks addObject:dice];
        
        // ensure we stop firing
        if (--remainingCount < 0)
            dispatch_source_cancel(_timer);
        [self removeHinges];
    });
    
    dispatch_resume(_timer);
    
    
    _hasBeenExploded = NO;
    
}



// swap method
-(SCNNode*)copyAndRepositionMyself:(SCNNode*)node
{
    SCNNode *copyNode = [node copy];
    
    SCNMatrix4 trans = node.presentationNode.transform;
    
    SCNAction *placeAction = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        node.transform = trans;
    }];
    
    copyNode.physicsBody = [self blockPhysicsBodyDynamic:NO];
    
    [_scene.rootNode addChildNode:copyNode];
    
    [copyNode runAction:placeAction];
    
    SCNAction *fadeOut = [SCNAction fadeOutWithDuration:0.10];
    fadeOut.timingMode = SCNActionTimingModeEaseOut;
    
    SCNAction *fadeSeq = [SCNAction sequence:@[fadeOut,[SCNAction removeFromParentNode]]];
    [node runAction:fadeSeq];
    
    return copyNode;
}



#pragma mark - Animate Blocks Back the Position
-(void)moveBlocksBack
{
    for (SCNNode *node in _blocks) {
       [node runAction:[self returnBlock]];
    }
    
}
// Action to Return Blocks Back to their Original Grid
-(SCNAction*)returnBlock
{
    SCNAction *resetTransformAction = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        
        SCNMatrix4 toTransform = [[_transforms valueForKey:MemoryDescriptionSCN(node)] SCNMatrix4Value];
        
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:RESTACK_TIME];
        [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        {
            node.transform = toTransform;
        }
        
        [SCNTransaction commit];

    }];
    
    return resetTransformAction;
    
}

-(void)highlightNodes
{
    NSLog(@"HightNodes Called");
    
    for (SCNNode *node in _blocks) {
        
        [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:RESTACK_TIME-0.10],[self highlightAction]]]];
        
        
    }
    
}

-(SCNAction*)highlightAction
{
    SCNAction *highlight = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:FLASH_TIME/2];
        [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [SCNTransaction setCompletionBlock:^{
            [self unLightNode:node];
        }];
        {
            node.geometry.firstMaterial.emission.contents = [UIColor colorWithWhite:0.12 alpha:0.25];
        }
        [SCNTransaction commit];

    }];
    
    return highlight;
    
}

-(void)unLightNode:(SCNNode*)node
{
    [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:FLASH_TIME/2],[self unHighlightAction]]]];
}

-(SCNAction*)unHighlightAction
{
    SCNAction *unHighlight = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:FLASH_TIME/2];
        [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        {
            node.geometry.firstMaterial.emission.contents = [UIColor blackColor];
        }
        [SCNTransaction commit];
        
    }];
    
    return unHighlight;
    
}


-(void)giveBlocksDynamicPhysicsBodys
{
    NSLog(@"Giving Dynamic Bodies");
    
    for (SCNNode *node in _blocks) {
        [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:RESTACK_TIME],[self giveDynamicsAction]]] completionHandler:^{
        }];
    }
    _ballHasBeenThrown = NO;
}

-(SCNAction*)giveDynamicsAction
{
    SCNAction *giveDynamics = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        node.physicsBody = [self blockPhysicsBodyDynamic:YES];
    }];
    
    return giveDynamics;
}



#pragma mark - Create Grid

-(void)makeBlocks
{
    SCNNode *blockNode = [self blockNode];
    
    CGFloat wide = GRID_WIDTH  ;
    CGFloat deep = GRID_DEPTH  ;
    CGFloat tall = GRID_HEIGHT ;
    
    SCNVector3 gridSize = SCNVector3Make(wide, tall, deep);
    
    NSArray *blockNodes = [self stackOfNodesThisSize:gridSize ofThisNode:blockNode];
    
    _blocks = blockNodes;
    
    NSLog(@"Blocks:%i",(int)blockNodes.count);
    
    NSMutableDictionary *newTransforms = [NSMutableDictionary dictionary];
    
    _blocksNode = [SCNNode node];
    
    for (SCNNode *node in blockNodes) {
        
        [_scene.rootNode addChildNode:node];
        [_blocksNode addChildNode:node];
        
        [newTransforms setValue:[NSValue valueWithSCNMatrix4:node.transform] forKey:MemoryDescriptionSCN(node)];
    }
    
    // Add Blocks to the Scene
    [_scene.rootNode addChildNode:_blocksNode];
    _transforms = newTransforms;
    
}

// Grid Helper
-(NSArray*)stackOfNodesThisSize:(SCNVector3)gridStackSize ofThisNode:(SCNNode*)node
{
    NSMutableArray *stackOfNodes = [[NSMutableArray alloc]init];
    
    SCNVector3 unitSize = GetNodeSize(node);
    
    NSArray *gridPositions = GridPositions(unitSize, gridStackSize);
    
    for (NSValue *positionValue in gridPositions) {
        
        SCNNode *cloneNode = [node clone];
        cloneNode.position = [positionValue SCNVector3Value];
        
        [stackOfNodes addObject:cloneNode];
    }
    return stackOfNodes;
}



#pragma mark - Blocks



-(SCNNode*)blockNode
{
    SCNNode *blockNode = [SCNNode node];
    
    blockNode.position = SCNVector3Make(0, 0.5, 0);
    blockNode.geometry = _blockReferenceGeometry;
    blockNode.name = @"BLOCK";
    
    // Add physics Body
    blockNode.physicsBody = [self blockPhysicsBodyDynamic:YES];
    
    return blockNode;
    
}

- (void)duplicateNode:(SCNNode *)node withMaterial:(SCNMaterial *)material
{
    SCNNode *newNode = [node clone];
    newNode.geometry = [node.geometry copy];
    newNode.geometry.firstMaterial = material;
}

-(SCNNode*)genericBlockNode
{
    static int nodeCount = 0;
    
    SCNNode *blockNode = [SCNNode node];
    
    CGFloat blockSize =randSCNFloat(0.25, 2.0);
    
    SCNBox *box = [SCNBox boxWithWidth:blockSize height:blockSize length:blockSize chamferRadius:blockSize/32];
    
    blockNode.geometry = box;
    blockNode.geometry.firstMaterial.diffuse.contents = RandomSCNColor(); //[UIColor redColor];
    
    blockNode.name =[NSString stringWithFormat:@"GENERIC_BLOCK_%i",nodeCount];
    NSLog(@"blockNode.name:%@",blockNode.name);
    
    blockNode.physicsBody =[SCNPhysicsBody dynamicBody];
    
    nodeCount++;
    
    return blockNode;

}

-(SCNGeometry*)makeGenericGeometry
{
    CGFloat blockSize = 1.0;
    
    SCNBox *box = [SCNBox boxWithWidth:blockSize height:blockSize length:blockSize chamferRadius:blockSize/32];
    
    UIImage *boxImage = [UIImage imageNamed:@"crate"];
    
    SKTexture *boxTexture = [SKTexture textureWithImage:boxImage];
    SKTexture *boxTextureNormal = [boxTexture textureByGeneratingNormalMap];
    
    box.firstMaterial.diffuse.contents = boxImage;
    box.firstMaterial.normal.contents = boxTextureNormal;
    
    box.firstMaterial.diffuse.mipFilter = YES;
    box.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    box.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    
    return box;
}

-(SCNGeometry*)makeBlockGeometry
{
    CGFloat blockSize = 1.0;
    
    SCNBox *box = [SCNBox boxWithWidth:blockSize height:blockSize length:blockSize chamferRadius:blockSize/32];
    
    UIImage *boxImage = [UIImage imageNamed:@"crate"];
    
    SKTexture *boxTexture = [SKTexture textureWithImage:boxImage];
    SKTexture *boxTextureNormal = [boxTexture textureByGeneratingNormalMap];
    
    box.firstMaterial.diffuse.contents = boxImage;
    box.firstMaterial.normal.contents = boxTextureNormal;
    
    box.firstMaterial.diffuse.mipFilter = YES;
    box.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    box.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    
    return box;
}


#pragma mark - Set Bit Masks
-(void)setBitMasks
{
    // Floor
    NSArray *floorBlockNodes =  [_scene.rootNode childNodesPassingTest:^BOOL(SCNNode *node, BOOL *stop) {
        return [node.name isEqualToString:@"floor"];
    }];
    
    _floorNode = [floorBlockNodes firstObject];
    
    for (SCNNode *node in floorBlockNodes) {
        node.physicsBody = [SCNPhysicsBody staticBody];

        node.physicsBody.categoryBitMask = floorCategory;
        
        node.physicsBody.collisionBitMask = ballCategory | blockCategory;
        
    }

    
    // Wall
    NSArray *wallBlockNodes =  [_scene.rootNode childNodesPassingTest:^BOOL(SCNNode *node, BOOL *stop) {
        return [node.name isEqualToString:@"wall"];
    }];
    
    for (SCNNode *node in wallBlockNodes) {
        node.physicsBody = [SCNPhysicsBody staticBody];

        node.physicsBody.categoryBitMask = wallCategory;
        node.physicsBody.collisionBitMask = ballCategory | blockCategory;
        
    }
    

    
}



#pragma mark - BALL
-(void)makeAndPlaceBall
{
    SCNVector3 placement = SCNVector3Make(15, 0.5,randSCNFloat(-1.0, 1.0));
    
    SCNNode *ballNode = [SCNNode node];
    SCNSphere *ballSphere = [SCNSphere sphereWithRadius:0.65];
    ballNode.geometry = ballSphere;
    
    ballNode.geometry.firstMaterial.diffuse.contents = [UIColor redColor];
    
    ballNode.position = placement;
    ballNode.name = @"BALL";
    
    SCNPhysicsShape *ballPhysicsShape = [SCNPhysicsShape shapeWithGeometry:ballSphere options:nil];
    
    SCNPhysicsBody *ballPhysicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:ballPhysicsShape];
    
    ballPhysicsBody.categoryBitMask = ballCategory;
    
    ballPhysicsBody.collisionBitMask = floorCategory | blockCategory;
    
    ballPhysicsBody.contactTestBitMask  = blockCategory | floorCategory;
    
    ballPhysicsBody.restitution =0.859;
    ballPhysicsBody.mass = 5.0;
    
    ballNode.physicsBody = ballPhysicsBody;
    
    ballNode.opacity=0;
    
    [_scene.rootNode addChildNode:ballNode];
    
    [ballNode runAction:[SCNAction fadeInWithDuration:0.25]];
    
    _ballNode = ballNode;
    
    NSLog(@"Ball Node Added!");
    
     _ballHasBeenThrown = NO;
    
    
}



// another approach implementing both

-(void)resetupForCubes
{

    
    NSArray *nodes = @[_robotNode];
    
    for (SCNNode *node in nodes) {
        [node runAction:[SCNAction sequence:@[[SCNAction fadeOutWithDuration:0.5], [SCNAction removeFromParentNode]]]];
    }
    
    
    
    // Setup For blocks
    _ballHasBeenThrown = NO;
    _isExploded = NO;
    _blockReferenceGeometry = [self makeBlockGeometry];
    _hasBeenExploded = NO;
    _redBlocks = [[NSMutableArray alloc]init];
    _hinges = [NSMutableArray array];
    
    [self makeBlocks];
    [self makeAndPlaceBall];
    [self setBitMasks];

}

-(void)posistionForRobot
{
    
}

-(void)fastTrack
{
    
    SCNView *scnView = (SCNView *)self.view;
    //scnView.gestureRecognizers = [self gestureRecsForBlocks];
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;

    
    _goingUp = YES;
    [self arm];

}


-(void)demoMode
{
    static int counter;
    
    
    
    if (counter > 11) {
        counter = 0;
    }
    
    switch (counter) {
        case 0:
            [self throwTheBall];
            break;
        case 1:
            [self moveCameraToStack];
            [self restackTheBlocks];
            break;
        case 2:
            
            [self makeItRain];
            [self moveCameraWayBack];
            break;
        case 3:
            [self clearBlocks];
            [self clearCubes];
            break;
        case 4:
            NSLog(@"Cubes should be gone");
            _goingUp = YES;
            [self arm];
            [self returnCamera];
            break;
        case 5:
            [self moveCameraToRobot];
            [_robotNode activateIKConstraints];
            [self handleforIKMove];
            break;
        case 6:
             [self handleforIKMove];
            break;
        case 7:
             [self handleforIKMove];
            break;
        case 8:
             [self handleforIKMove];
            break;
        case 9:
             [self handleforIKMove];
            break;
        case 10:
             [self handleforIKMove];
            break;
        case 11:
            [self resetupForCubes];
            [self returnCamera];
            break;
        default:
            break;
    }
    
    counter++;
   
}






// Ball shooting re-implementation

-(void)throwBalls
{
    static int counter;
    
    if (counter > 4) {
        counter = 0;
    }
    
    switch (counter) {
        case 0:
           
            [self throwTheBall];
            counter++;
            break;
        case 1:
            
            if (!_ballHasBeenThrown) {
                [self throwTheBall];
                counter++;
              
            }
            else
            {
                // nothing, try again
            }
            
            break;
        case 2:
            
            [self makeItRain];
            
            counter++;
            break;
        case 3:
            [self clearBlocks];
            [self throwTheBall];
            counter++;
            break;
            
        case 4:
            [self restackTheBlocks];
            counter++;
            break;
            
        default:
            break;
    }
}





-(void)throwTheBall
{
    [self newThrowBallMethodForDemo];
    //[self throwBall];

}


-(void)restackTheBlocks
{
     [self restackBlocks];
}






// currently not using...
-(void)shootBall
{
    
    if (_ballHasBeenThrown) {
        NSLog(@"Moving Blocks Back");
        [self moveVerticalBlocksBack];
    }
    else
    {
        [self throwBall];
        _ballHasBeenThrown = YES;
        
        
        _hasBeenExploded = YES;
        _isExploded = YES;
    }
    
  
    
}





-(void)newThrowBallMethodForDemo
{
    _ballHasBeenThrown = YES;
    
    SCNVector3 force = SCNVector3Make(-200, 14, -1);
    
    SCNVector3 newForce = RandomizeSCNVector3(force, SCNVector3Make(60, 2.5, 2));
    
    LogSCNVector3(newForce, @"newForce");
    
    [_ballNode.physicsBody applyForce:newForce atPosition:_ballNode.position impulse:YES];
    
    [_ballNode runAction:[SCNAction sequence:@[
                                          [SCNAction waitForDuration:1.25],
                                          [SCNAction fadeOutWithDuration:0.25],
                                          [SCNAction removeFromParentNode]]]];

    
  

}





-(void)throwBall
{
     _ballHasBeenThrown = YES;
    
    SCNVector3 force = SCNVector3Make(-100, 2, -1);
    
    SCNVector3 newForce = RandomizeSCNVector3(force, SCNVector3Make(60, 2.5, 2));
    
    LogSCNVector3(newForce, @"newForce");
    
    [_ballNode.physicsBody applyForce:newForce atPosition:_ballNode.position impulse:YES];
    
    [self fadeOutAndRemove:_ballNode];

}

-(void)fadeOutAndRemove:(SCNNode*)node
{
    
    SCNAction *newBallAction = [SCNAction runBlock:^(SCNNode * __nonnull node) {
        [self makeAndPlaceBall];
    }];
    
    
    [node runAction:[SCNAction sequence:@[
                                          [SCNAction waitForDuration:2.0],
                                          [SCNAction fadeOutWithDuration:0.25],
                                          [SCNAction removeFromParentNode],
                                          [SCNAction waitForDuration:0.25],
                                          newBallAction,
                                          ]]];
    
}



#pragma mark - Restack Method

-(void)restackBlocks
{
    [self replaceBlocks];
    [self moveBlocksBack];
    [self giveBlocksDynamicPhysicsBodys];
    [self highlightNodes];
    _ballHasBeenThrown = NO;
}










#pragma mark - Render Delegate

// Physics
-(void)renderer:(nonnull id<SCNSceneRenderer>)renderer didSimulatePhysicsAtTime:(NSTimeInterval)time
{
    
}

-(void)renderer:(nonnull id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
//    SCNNode *leftArmNode = [_scene.rootNode childNodeWithName:@"leftArm" recursively:YES];
//    
//    
//    leftArmNode.presentationNode.eulerAngles = SCNVector3Make(leftArmNode.presentationNode.eulerAngles.x, 0, 0);
    
}

-(void)renderer:(nonnull id<SCNSceneRenderer>)renderer didRenderScene:(nonnull SCNScene *)scene atTime:(NSTimeInterval)time
{
    // YAHOO!!!???!?!
//    SCNNode *leftArmNode = [_scene.rootNode childNodeWithName:@"leftArm" recursively:YES];
//    
//    
//    leftArmNode.presentationNode.eulerAngles = SCNVector3Make(leftArmNode.presentationNode.eulerAngles.x, 0, 0);
}


#pragma mark - Physics Delegate

-(void)physicsWorld:(nonnull SCNPhysicsWorld *)world didBeginContact:(nonnull SCNPhysicsContact *)contact
{
    
    //    [self checkAndDoForBall:contact];
    //    [self checkAndDoForBlock:contact];
    
}

-(void)physicsWorld:(nonnull SCNPhysicsWorld *)world didUpdateContact:(nonnull SCNPhysicsContact *)contact
{
    //    [self checkAndDoForBall:contact];
    //    [self checkAndDoForBlock:contact];
    
    
}

-(void)physicsWorld:(nonnull SCNPhysicsWorld *)world didEndContact:(nonnull SCNPhysicsContact *)contact
{
    
}


// Check For Block
-(void)checkAndDoForBlock:(nonnull SCNPhysicsContact *)contact
{
    // Check for Ball Node
    if (contact.nodeA.physicsBody.categoryBitMask == blockCategory) {
        
        if (contact.nodeB.physicsBody.categoryBitMask == ballCategory) {
            NSLog(@"Block contacted Ball");
        }
        
        if (contact.nodeB.physicsBody.categoryBitMask == floorCategory) {
            NSLog(@"Block contacted Floor");
        }
    }
    
    
    if (contact.nodeB.physicsBody.categoryBitMask == blockCategory) {
        
        if (contact.nodeA.physicsBody.categoryBitMask == ballCategory) {
            NSLog(@"Block contacted Ball");
        }
        
        if (contact.nodeA.physicsBody.categoryBitMask == floorCategory) {
            NSLog(@"Block contacted Floor");
        }
        
    }
    
}




// Check For Ball
-(void)checkAndDoForBall:(nonnull SCNPhysicsContact *)contact
{
    // Check for Ball Node
    if (contact.nodeA.physicsBody.categoryBitMask == ballCategory) {
        
        if (contact.nodeB.physicsBody.categoryBitMask == blockCategory) {
            NSLog(@"Ball contacted Block");
            
            
        }
        
        if (contact.nodeB.physicsBody.categoryBitMask == floorCategory) {
            NSLog(@"Ball contacted Floor");
        }
    }
    
    
    if (contact.nodeB.physicsBody.categoryBitMask == ballCategory) {
        
        if (contact.nodeA.physicsBody.categoryBitMask == blockCategory) {
            NSLog(@"Ball contacted Block");

        }
        
        if (contact.nodeA.physicsBody.categoryBitMask == floorCategory) {
            NSLog(@"Ball contacted Floor");
        }
        
    }
    
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
