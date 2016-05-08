//
//  JDMRobotArmNode.m
//  NewScene
//
//  Created by Justin Madewell on 7/7/15.
//  Copyright © 2015 Justin Madewell. All rights reserved.
//


#import "JDMRobotArmNode.h"
#import "JDMTextureLayer.h"

#define RADTODEG(r) ((180.0f*M_PI)*r)
#define DEGTORAD(d) ((d)/180.0f*M_PI)

static const uint32_t robotCategory =  0x1 << 5 ;

@interface JDMRobotArmNode ()
{
    NSArray *_armNodeTransforms;
    CGFloat _oldAngle;
    JDMTextureLayer *__faceLayer;
   
}

@end

@implementation JDMRobotArmNode



+(JDMRobotArmNode*)makeRobot
{
    JDMRobotArmNode *robotNode = [[self alloc]init];
    [robotNode addChildNode:[robotNode makeRobotUsingSize:2.0]];
    
    return robotNode;

}


#pragma mark - CALayer 



-(JDMTextureLayer*)makeJDMTextureLayer
{
    JDMTextureLayer *layer = [JDMTextureLayer layer];
    return layer;
    
}

-(SCNNode*)makeRobotUsingSize:(CGFloat)size
{
    SCNNode *mainRobotNode = [SCNNode node];
    
    // Set Default Colors
    self.primaryColor = [UIColor redColor];
    self.secondaryColor = [UIColor orangeColor];
    self.effectorColor = [UIColor blueColor];
    
    mainRobotNode.name = [self makeName];
    // make the Body, which also Makes the Arms
    SCNNode *robotBodyNode = [self makeBody:2.0];
    // add body to main node
    [mainRobotNode addChildNode:robotBodyNode];
    
    return mainRobotNode;

}

#pragma mark - Body Creation

-(SCNNode*)makeBody:(CGFloat)size
{
    //TODO: Add sizing Math
    CGFloat bodyRadius = 1.20;
    CGFloat bodyHeight = 2.0;

    SCNNode *bodyNode = [SCNNode node];
    bodyNode.name = @"body";
    
    UIColor *bodyColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
    SCNGeometry *bodyGeometry = [SCNCylinder cylinderWithRadius:bodyRadius height:bodyHeight];
    bodyGeometry.firstMaterial.diffuse.contents = bodyColor;
    bodyGeometry.firstMaterial.ambient.contents = bodyColor;
    bodyGeometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    bodyNode.geometry = bodyGeometry;
    bodyNode.physicsBody = [SCNPhysicsBody kinematicBody];
    bodyNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNVector3 bodySize = GetNodeSize(bodyNode);
    
    CGFloat x = bodySize.x * 1.125;
    CGFloat y = bodySize.y * 0.5;
    
    SCNVector3 leftVec = SCNVector3Make(-x/2,y,0);
    SCNVector3 rightVec = SCNVector3Make(x/2,y,0);
    
    // Arms
    CGFloat armSize = 0.75;
    
    SCNNode *leftArmNode = [self leftArm:armSize];
    SCNNode *rightArmNode = [self rightArm:armSize];
    
    leftArmNode.position = leftVec;
    rightArmNode.position = rightVec;
    
    [bodyNode addChildNode:leftArmNode];
    [bodyNode addChildNode:rightArmNode];
    
    // Set IKs for ArmNodes
    self.leftArmIKConstraint = [self makeIKConstraintForArmNode:leftArmNode withBodyNode:bodyNode];
    self.rightArmIKConstraint = [self makeIKConstraintForArmNode:rightArmNode withBodyNode:bodyNode];
    
    // Head section
    CGFloat headSize = 1.0;
    CGFloat headY = bodySize.y ;//+ headSize;
    
    // to lower
    headY = headY/2;
    
    SCNVector3 headVec = SCNVector3Make(0, headY, 0);
    
    SCNNode *head = [self headNode:headSize];
    head.position = headVec;
    
    [bodyNode addChildNode:head];
    
    // Body Base
    CGFloat baseSize = bodyRadius;
    CGFloat bodyY = bodySize.y/2 + ((baseSize * 1.5)/2);
    
    
    
    SCNVector3 bodyVec = SCNVector3Make(0, -bodyY, 0);
    
    SCNNode *baseNode = [self bodyBaseNode:baseSize];
    baseNode.position = bodyVec;
    
    [bodyNode addChildNode:baseNode];
    
    
    
    
    return bodyNode;
}


#pragma mark - External Animation Call

-(void)updateTargetPosition:(SCNVector3)newTargetPosition
{
    CGFloat time = 0.5;
    
    [self updateIKPosition:newTargetPosition withTime:time];
    
    [self updateArmRotation:[self getAngleForShoulderRotationWithTargetPosition:newTargetPosition] withTime:time];
    
    [self shakeHeadUpAndDown];
    
    //[self spinTheWheel];
}


-(void)updateIKPosition:(SCNVector3)newTargetPosition withTime:(CGFloat)time
{
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:time];
    {
        self.leftArmIKConstraint.targetPosition = newTargetPosition;
        self.rightArmIKConstraint.targetPosition = newTargetPosition;
    }
    
    [SCNTransaction commit];
}

-(void)updateArmRotation:(CGFloat)angle withTime:(CGFloat)time
{
    
    SCNNode *left = [[self childNodeWithName:@"leftArm" recursively:YES] childNodeWithName:@"shoulderSphere" recursively:YES];
    
    SCNNode *right = [[self childNodeWithName:@"rightArm" recursively:YES] childNodeWithName:@"shoulderSphere" recursively:YES];
    
    // create Action
    SCNAction *leftRotateAction = [SCNAction rotateByAngle:DEGTORAD(angle) aroundAxis:SCNVector3Make(1, 0, 0) duration:time];
    
    SCNAction *rightRotateAction = [SCNAction rotateByAngle:DEGTORAD(angle) aroundAxis:SCNVector3Make(-1, 0, 0) duration:time];
    
    // run it
    [left runAction:leftRotateAction];
    [right runAction:rightRotateAction];
    
}


-(CGFloat)getAngleForShoulderRotationWithTargetPosition:(SCNVector3)targetPosition
{
    SCNNode *shoulderShpereNode = [[self childNodeWithName:@"leftArm" recursively:YES] childNodeWithName:@"shoulderSphere" recursively:YES];

    
    SCNVector3 pos = AAPLMatrix4GetPosition(shoulderShpereNode.worldTransform);
    
    CGFloat firstNumber = 0;
    CGFloat secondNumber =  pos.y/2;
    CGFloat thirdNumber =  pos.y;
    CGFloat fourthNumber =  pos.y + pos.y/2 ;
    CGFloat fithNumber =  pos.y * 2 ;
    
    
    CGFloat point = targetPosition.y;
    
    CGFloat angle = 0;
    
    if (point <= firstNumber) {
        angle = 0;
    }
    else if (point > firstNumber && point <= secondNumber)
    {
        angle = 0;
    }
    else if (point > secondNumber && point <= thirdNumber)
    {
        angle = 45;
    }
    else if (point > thirdNumber && point <= fourthNumber)
    {
        angle = 90;
    }
    else if (point > fourthNumber && point <= fithNumber)
    {
        angle = 135;
    }
    else if (point > fithNumber)
    {
        angle = 180;
    }
    
    
    // Angle tracking and Math
    
    //make static Angle Holder
    static CGFloat currentAngle;
    
    // for clairty
    CGFloat angleTo = angle;
    CGFloat angleWeAreAt = currentAngle;
    CGFloat modifier = 1;
    
    if (angleTo < angleWeAreAt) {
        modifier = -1;
    }
    
    angleTo = angleTo * modifier;
    
    CGFloat angleToGetThere = angleWeAreAt + angleTo;
    
    angleToGetThere = angleToGetThere * modifier;
    
    // update the tracker
    currentAngle = currentAngle + angleToGetThere;
    
    return angleToGetThere;

}

-(void)moveArm:(NSString*)armString byAmount:(CGFloat)angle
{
    SCNNode *armNode = [self childNodeWithName:armString recursively:YES];
    
    SCNNode *armShoulderShpereNode = [armNode childNodeWithName:@"shoulderSphere" recursively:YES];
    
    CGFloat rotationAngleAmountAsRadians = DEGTORAD(angle);
    
    SCNAction *rotateAction = [SCNAction rotateByAngle:rotationAngleAmountAsRadians aroundAxis:SCNVector3Make(-1, 0, 0) duration:0.5];
    
    [armShoulderShpereNode runAction:rotateAction];
    
}





#pragma mark - IK constraints

-(SCNIKConstraint*)makeIKConstraintForArmNode:(SCNNode*)armNode withBodyNode:(SCNNode*)bodyNode
{
    SCNNode *armShoulderShpereNode = [armNode childNodeWithName:@"shoulderSphere" recursively:YES];
    SCNNode *armPivotNode = [armShoulderShpereNode childNodeWithName:@"upperArmPivot" recursively:YES];
    SCNNode *upperArmNode = [armPivotNode childNodeWithName:@"upperArm" recursively:YES];
    SCNNode *lowerArmNode = [upperArmNode childNodeWithName:@"lowerArm" recursively:YES];
    SCNNode *handNode = [lowerArmNode childNodeWithName:@"hand" recursively:YES];
    
    SCNIKConstraint *armNodeIKConstraint = [SCNIKConstraint  inverseKinematicsConstraintWithChainRootNode:armShoulderShpereNode];
    
    
    CGFloat maxAngle = 45;
    
    [armNodeIKConstraint setMaxAllowedRotationAngle:maxAngle forJoint:handNode];
    
    [armNodeIKConstraint setMaxAllowedRotationAngle:maxAngle forJoint:lowerArmNode];
    
    [armNodeIKConstraint setMaxAllowedRotationAngle:0 forJoint:upperArmNode];
    
    [armNodeIKConstraint setMaxAllowedRotationAngle:0 forJoint:armPivotNode];
    
    [armNodeIKConstraint setMaxAllowedRotationAngle:maxAngle forJoint:armShoulderShpereNode];
    
    return armNodeIKConstraint;
}


#pragma mark - External Activation Calls

-(void)activateIKConstraintsForLeftArm
{
    SCNNode *leftArmEndEffectorNode = [[self childNodeWithName:@"leftArm" recursively:YES] childNodeWithName:@"endEffector" recursively:YES];
    leftArmEndEffectorNode.constraints = @[self.leftArmIKConstraint];
}

-(void)activateIKConstraintsForRightArm
{
    SCNNode *rightArmEndEffectorNode = [[self childNodeWithName:@"rightArm" recursively:YES] childNodeWithName:@"endEffector" recursively:YES];
    rightArmEndEffectorNode.constraints = @[self.rightArmIKConstraint];
}

-(void)activateIKConstraints
{
    [self activateIKConstraintsForLeftArm];
    [self activateIKConstraintsForRightArm];
}







#pragma mark - Arm Create Methods

-(SCNNode*)leftArm:(CGFloat)size
{
    SCNNode *leftArmNode = [SCNNode node];
    leftArmNode.name = @"leftArm";
    SCNNode *shoulderNode = [self shoulderNodeSize:size];
    [leftArmNode addChildNode:shoulderNode];
    return leftArmNode;
}

-(SCNNode*)rightArm:(CGFloat)size
{
    SCNNode *rightArmNode = [SCNNode node];
    rightArmNode.name = @"rightArm";
    SCNNode *shoulderNode = [self shoulderNodeSize:size];
    [rightArmNode addChildNode:shoulderNode];
    rightArmNode.rotation = SCNVector4Make(0, 1, 0, M_PI);
    return rightArmNode;
}


#pragma mark - Shoulder
-(SCNNode*)shoulderNodeSize:(CGFloat)size
{
    SCNNode *shoulderContainerNode = [self makeShoulderNode:size];
    SCNNode *upperArmPivotNode = [shoulderContainerNode childNodeWithName:@"upperArmPivot" recursively:YES];
    
    // Arm Sizing Math
    CGFloat armRatio = 2.67;
    
    CGFloat armSize = (size * armRatio);
    int armSizeInt = armSize;
    
    SCNNode *upperArmNode = [self upperArmNode:armSizeInt];
    
    [upperArmPivotNode addChildNode:upperArmNode];
    
    SCNVector3 pos = [shoulderContainerNode convertPosition:SCNVector3Make(-1.25, -0.50, 0) toNode:upperArmNode];
    upperArmNode.position = pos;
    
    return shoulderContainerNode;
}

-(SCNNode*)makeShoulderNode:(CGFloat)size
{
    SCNNode *shoulderContainerNode  = [SCNNode node];
    shoulderContainerNode.name = @"shoulderContainer";
    
    // Add ShoulderCude->
    CGFloat cubeRatio = 1.669;
    CGFloat shoulderCubeSize = size * cubeRatio;
    UIColor *cubeColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
    
    // Add with this Function Call
    PlaceConnectionNode(shoulderContainerNode, shoulderContainerNode.position,[UIColor yellowColor],shoulderCubeSize);
    // retrieve the node
    SCNNode *shoulderCubeNode = [[shoulderContainerNode childNodes] firstObject];
    // rename and re-dress
    shoulderCubeNode.name = @"shoulderCube";
    SCNMaterial *cubeMaterial = [SCNMaterial material];
    cubeMaterial.diffuse.contents = cubeColor;
    cubeMaterial.ambient.contents = cubeColor;
    cubeMaterial.locksAmbientWithDiffuse = YES;
    shoulderCubeNode.geometry.firstMaterial = cubeMaterial;
    
    // make Sphere and add it to the ShoulderCube
    SCNNode *shoulderSphereNode = [SCNNode node];
    shoulderSphereNode.name = @"shoulderSphere";
    shoulderSphereNode.physicsBody = [SCNPhysicsBody kinematicBody];
    shoulderSphereNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNGeometry *shoulderGeo = [SCNSphere sphereWithRadius:size];
    shoulderGeo.firstMaterial = ShinyMetalMaterial();
    shoulderSphereNode.geometry = shoulderGeo;
    
    // make upper arm pivot ball point and add it to the ShpereNode
    SCNNode *upperArmPivotNode = [SCNNode node];
    upperArmPivotNode.name = @"upperArmPivot";
    upperArmPivotNode.physicsBody = [SCNPhysicsBody kinematicBody];
    upperArmPivotNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNGeometry *upperArmPivotGeo = [SCNSphere sphereWithRadius:(0.43 * size)];
    upperArmPivotGeo.firstMaterial.diffuse.contents = cubeColor;
    upperArmPivotGeo.firstMaterial.specular.contents = cubeColor;
    upperArmPivotGeo.firstMaterial.locksAmbientWithDiffuse = YES;
    upperArmPivotNode.geometry = upperArmPivotGeo;
    
    // positioning for right /left side -- Just flipped the whole arm for the other side
    upperArmPivotNode.position = [shoulderSphereNode convertPosition:SCNVector3Make(-1, 0, 0) toNode:nil];
    
    [shoulderSphereNode addChildNode:upperArmPivotNode];
    [shoulderContainerNode addChildNode:shoulderSphereNode];
    
    return shoulderContainerNode;

}

#pragma mark - Upper Arm
-(SCNNode*)upperArmNode:(CGFloat)size
{
    SCNNode *upperArmNode = [SCNNode node];
    upperArmNode.name = @"upperArm";
    upperArmNode.physicsBody = [SCNPhysicsBody kinematicBody];
    upperArmNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNGeometry *upperArmGeo = [SCNCapsule capsuleWithCapRadius:size/4 height:size];
    upperArmGeo.firstMaterial.diffuse.contents =  self.primaryColor;
    upperArmGeo.firstMaterial.specular.contents =  self.primaryColor;
    upperArmGeo.firstMaterial.locksAmbientWithDiffuse = YES;
    // Assign Geometry
    upperArmNode.geometry = upperArmGeo;
    // Pivot up to Top
    
    upperArmNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0);
    
    SCNVector3 upperArmSize = GetNodeSize(upperArmNode);
    LogSCNVector3(upperArmSize, @"upperArmSize");
    
    // add Bottom Arm Node
    SCNNode *lowerArmNode = [self lowerArm:size];
    // position lowerArmNode
    lowerArmNode.position = [upperArmNode convertPosition:SCNVector3Make(0, -(size/2), 0) toNode:lowerArmNode];
    
    [upperArmNode addChildNode:lowerArmNode];
    
    return  upperArmNode;
}



#pragma mark - Lower Arm
-(SCNNode*)lowerArm:(CGFloat)size
{
    SCNNode *lowerArmNode = [SCNNode node];
    lowerArmNode.name = @"lowerArm";
    lowerArmNode.physicsBody = [SCNPhysicsBody kinematicBody];
    lowerArmNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNGeometry *lowerArmGeo = [SCNCapsule capsuleWithCapRadius:size/4 height:size];
    lowerArmGeo.firstMaterial.diffuse.contents = self.primaryColor;
    lowerArmGeo.firstMaterial.specular.contents = self.primaryColor;
    lowerArmGeo.firstMaterial.locksAmbientWithDiffuse = YES;
    // Assign Geometry
    lowerArmNode.geometry = lowerArmGeo;
    
    // Pivot up to the Top
    lowerArmNode.pivot = SCNMatrix4MakeTranslation(0, 1.0, 0);
    
    // add Hand Node
    SCNNode *handNode = [self handNode:size/4];
    // Position Hand Node
    SCNVector3 handNodePosition = [lowerArmNode convertPosition:SCNVector3Make(0, -(size/4), 0) toNode:handNode];
    handNode.position = handNodePosition;
    
    // add HandNode
    [lowerArmNode addChildNode:handNode];
    
    return lowerArmNode;
    
}


#pragma mark - Hand
-(SCNNode*)handNode:(CGFloat)size
{
    SCNNode *handNode = [SCNNode node];
    handNode.name = @"hand";
    handNode.physicsBody = [SCNPhysicsBody kinematicBody];
    handNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNGeometry *handGeo = [SCNSphere sphereWithRadius:size];
    handGeo.firstMaterial.diffuse.contents =  self.secondaryColor;
    handGeo.firstMaterial.specular.contents = self.secondaryColor;
    handGeo.firstMaterial.locksAmbientWithDiffuse = YES;
    handNode.geometry = handGeo;
    
    // Pivot up to the top
    handNode.pivot = SCNMatrix4MakeTranslation(0, 1.0, 0);
    
    // add endEffectorNode
    SCNNode *endEffectorNode = [self endEffector:size/2];
    endEffectorNode.position = [handNode convertPosition:SCNVector3Make(0, -(size/2+size), 0) toNode:endEffectorNode];
    
    [handNode addChildNode:endEffectorNode];
    
    return handNode;
}


#pragma mark - End Effector (Tip)
-(SCNNode*)endEffector:(CGFloat)size
{
    SCNNode *endEffector = [SCNNode node];
    endEffector.name = @"endEffector";
    endEffector.physicsBody = [SCNPhysicsBody kinematicBody];
    endEffector.physicsBody.categoryBitMask = robotCategory;
    
    endEffector.geometry = [SCNBox boxWithWidth:size height:size length:size chamferRadius:size/8];
    endEffector.geometry.firstMaterial.diffuse.contents = self.effectorColor;
    
    // Pivot to the Bottom
    endEffector.pivot =  SCNMatrix4MakeTranslation(0, -size, 0);
    
    return endEffector;
}

#pragma mark - Robot Head

-(SCNNode*)headNode:(CGFloat)size
{
  
    UIColor *neckBaseColor = [UIColor orangeColor];
    UIColor *neckColor = [UIColor redColor];
    UIColor *faceColor = [UIColor greenColor];
    
    UIColor *robo = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
    
    faceColor=robo;
    
    // Main Head Node - has no geometry but holds all the head Nodes inside of it
    SCNNode *headNode = [SCNNode node];
    headNode.name = @"head";
    
    //Make the Neck Base Pivot
    SCNNode *neckBasePivot = [SCNNode node];
    neckBasePivot.name = @"neckBasePivot";
    neckBasePivot.physicsBody = [SCNPhysicsBody kinematicBody];
    neckBasePivot.physicsBody.categoryBitMask = robotCategory;
    CGFloat neckBasePivotRadius = (0.45 * size);
    neckBasePivot.geometry = [SCNSphere sphereWithRadius:neckBasePivotRadius];
    neckBasePivot.geometry.firstMaterial.diffuse.contents = neckBaseColor;
    neckBasePivot.geometry.firstMaterial.specular.contents = neckBaseColor;
    neckBasePivot.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    //Make the Neck
    SCNNode *neckNode = [SCNNode node];
    neckNode.name = @"neck";
    neckNode.physicsBody = [SCNPhysicsBody kinematicBody];
    neckNode.physicsBody.categoryBitMask = robotCategory;
    
    CGFloat neckHeight = (0.70 * size);
    
    neckNode.geometry = [SCNCylinder cylinderWithRadius:(0.12 * size) height:neckHeight];
    neckNode.geometry.firstMaterial.diffuse.contents = neckColor;
    neckNode.geometry.firstMaterial.specular.contents = neckColor;
    neckNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    //Make the top pivot
    SCNNode *neckTopPivot = [SCNNode node];
    neckTopPivot.name = @"neckTopPivot";
    neckTopPivot.physicsBody = [SCNPhysicsBody kinematicBody];
    neckTopPivot.physicsBody.categoryBitMask = robotCategory;
    neckTopPivot.geometry = [SCNSphere sphereWithRadius:(0.20 * size)];
    neckTopPivot.geometry.firstMaterial.diffuse.contents = [UIColor orangeColor];
    neckTopPivot.geometry.firstMaterial.specular.contents = [UIColor orangeColor];
    neckTopPivot.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    // Make the Face
    SCNNode *faceNode = [SCNNode node];
    faceNode.name = @"face";
    faceNode.physicsBody = [SCNPhysicsBody kinematicBody];
    faceNode.physicsBody.categoryBitMask = robotCategory;
    CGFloat faceLength = 0.125;
    SCNBox *box = [SCNBox boxWithWidth:1.35 height:1.15 length:faceLength chamferRadius:0.125];
    faceNode.geometry = box;
    faceNode.geometry.firstMaterial.diffuse.contents = faceColor;
    faceNode.geometry.firstMaterial.specular.contents = faceColor;
    faceNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    // add to head node
    [headNode addChildNode:neckBasePivot];
    neckBasePivot.rotation = SCNVector4Make(-1, 0, 0, DEGTORAD(22.5));

    [neckBasePivot addChildNode:neckNode];
    // move pivot point down to the bottom of node
    neckNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0);
    // raise node so it sits on the outside of the neckbase
    neckNode.position = SCNVector3Make(0,neckBasePivotRadius/2,0);
    
    [neckNode addChildNode:neckTopPivot];
    neckTopPivot.position = SCNVector3Make(0, neckHeight/2, 0);
    neckTopPivot.rotation = SCNVector4Make(1, 0, 0, DEGTORAD(22.5));
    
    [neckTopPivot addChildNode:faceNode];
    faceNode.position = SCNVector3Make(0, 0, -(faceLength*2));
    
    // Make faceplane Node
    SCNNode *facePlaneNode = [SCNNode node];
    facePlaneNode.name = @"facePlane";
    
    facePlaneNode.physicsBody = [SCNPhysicsBody kinematicBody];
    facePlaneNode.physicsBody.categoryBitMask = robotCategory;
    
    CGFloat faceplaneW = (1.5 * 0.75);
    CGFloat faceplaneH = (1.25 * 0.75);
    
    SCNPlane *facePlanePlane = [SCNPlane planeWithWidth:faceplaneW height:faceplaneH];
    facePlanePlane.widthSegmentCount = 5;
    facePlanePlane.heightSegmentCount = 5;
    facePlanePlane.cornerRadius = 0.125;
    
    facePlaneNode.geometry = facePlanePlane;
    
    SCNMaterial * faceMat =  [self faceNodeMaterial];
    facePlaneNode.geometry.firstMaterial = faceMat;

    [faceNode addChildNode:facePlaneNode];
    
    CGFloat posZ = faceLength/2 + 0.01;
    
    facePlaneNode.position = SCNVector3Make(0, 0, -posZ);
    facePlaneNode.rotation = SCNVector4Make(0, 1, 0, DEGTORAD(180));
    
    
    
    return headNode;
}


-(SCNMaterial*)faceNodeMaterial
{
    SCNMaterial *material = [SCNMaterial material];
    
    __faceLayer = [self makeJDMTextureLayer];
    material.diffuse.contents = __faceLayer;
    
    material.diffuse.minificationFilter = SCNFilterModeLinear;
    material.diffuse.magnificationFilter = SCNFilterModeLinear;
    material.diffuse.mipFilter = SCNFilterModeLinear;
    
    material.lightingModelName = SCNLightingModelConstant;
    
    
    return material;
}


#pragma mark - Make Head Animations

-(void)shakeHeadUpAndDown
{
    SCNNode *headRotationNode = [self childNodeWithName:@"neckTopPivot" recursively:YES];
    
    //    [headRotationNode runAction:[self noAction]];
    
    [headRotationNode runAction:[self yesAction]];
    
    
    
}

-(SCNAction*)yesAction
{
    SCNAction *firstUp = [SCNAction rotateByAngle:DEGTORAD(15) aroundAxis:SCNVector3Make(1, 0, 0) duration:0.25];
    SCNAction *firstDown = [SCNAction rotateByAngle:DEGTORAD(30) aroundAxis:SCNVector3Make(-1, 0, 0) duration:0.25];
    
    SCNAction *secondUp = [SCNAction rotateByAngle:DEGTORAD(30) aroundAxis:SCNVector3Make(1, 0, 0) duration:0.25];
    SCNAction *secondDown = [SCNAction rotateByAngle:DEGTORAD(15) aroundAxis:SCNVector3Make(-1, 0, 0) duration:0.25];
    
    SCNAction *moveHeadUpAndDown = [SCNAction sequence:@[firstUp,firstDown,secondUp,secondDown]];
    
    SCNAction *yesAction = moveHeadUpAndDown;
    
    return yesAction;
}

-(SCNAction*)noAction
{
    SCNAction *firstLeft = [SCNAction rotateByAngle:DEGTORAD(15) aroundAxis:SCNVector3Make(0, 1, 0) duration:0.25];
    SCNAction *firstRight = [SCNAction rotateByAngle:DEGTORAD(30) aroundAxis:SCNVector3Make(0, -1, 0) duration:0.25];
    
    SCNAction *secondLeft = [SCNAction rotateByAngle:DEGTORAD(30) aroundAxis:SCNVector3Make(0, 1, 0) duration:0.25];
    SCNAction *secondRight = [SCNAction rotateByAngle:DEGTORAD(15) aroundAxis:SCNVector3Make(0, -1, 0) duration:0.25];
    
    SCNAction *moveHeadLeftAndRight = [SCNAction sequence:@[firstLeft,firstRight,secondLeft,secondRight]];
    
    SCNAction *noAction = moveHeadLeftAndRight;
    
    return noAction;

}

-(SCNAction*)confusedAction
{
    // tilt head to the side
    
    SCNAction *tiltAction;
    
    SCNAction *tilt = [SCNAction rotateByAngle:DEGTORAD(30) aroundAxis:SCNVector3Make(1, 0, 0) duration:1.0];
    
    
    
    return tiltAction;
    
    
    
}

-(void)restoreHeadPosition
{
   
    
    SCNNode *headRotationNode = [[[self childNodeWithName:@"body" recursively:YES] childNodeWithName:@"head" recursively:YES] childNodeWithName:@"neckTopPivot" recursively:YES];
    
    [headRotationNode runAction:[SCNAction runBlock:^(SCNNode * __nonnull node) {
        node.presentationNode.transform = node.transform;
    }]];
}









#pragma mark - Body Base / Wheels


-(SCNNode*)bodyBaseNode:(CGFloat)size
{
    UIColor *bodyBaseColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
    SCNNode *bodyBaseNode = [SCNNode node];
    bodyBaseNode.name = @"bodyBase";
    
    bodyBaseNode.physicsBody = [SCNPhysicsBody kinematicBody];
    bodyBaseNode.physicsBody.categoryBitMask = robotCategory;
    
    SCNCone *bodyBaseCone = [SCNCone coneWithTopRadius:size bottomRadius:size/3 height:(size * 1.5)];
    bodyBaseNode.geometry = bodyBaseCone;
    
    bodyBaseNode.geometry.firstMaterial.diffuse.contents = bodyBaseColor;
    bodyBaseNode.geometry.firstMaterial.ambient.contents = bodyBaseColor;
    bodyBaseNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    CGFloat wheelSize = 1.25;
    CGFloat wheelY = ((size * 1.5) * 0.75) + wheelSize/2 ;
    
    SCNVector3 wheelPos = SCNVector3Make(0, -wheelY, wheelSize/2);
    
    SCNNode *wheelNode = [self wheelNode:wheelSize];
    wheelNode.position = wheelPos;
    
    [bodyBaseNode addChildNode:wheelNode];
    
    return bodyBaseNode;
}

#pragma mark - Wheel

-(SCNNode*)wheelNode:(CGFloat)size
{
    
    UIColor *wheelColor = [UIColor blueColor];
    SCNNode *wheelNode = [SCNNode node];
    wheelNode.name = @"wheel";
    
    wheelNode.physicsBody = [SCNPhysicsBody kinematicBody];
    wheelNode.physicsBody.categoryBitMask = robotCategory;
    
    // make the wheel node geo
    CGFloat teeth = 24;
    CGFloat teethHeight = 0.08;
    
    CGFloat extrusionDepth = (size * 0.90);
    
    CGFloat shapeSize = size;
    
    UIBezierPath *path = PathOfGearRounded(teeth, teethHeight, shapeSize, YES);
    
    SCNShape *shape = [SCNShape shapeWithPath:path extrusionDepth:extrusionDepth];
    
    wheelNode.geometry = shape;
    
    wheelNode.geometry.firstMaterial.diffuse.contents = wheelColor;
    wheelNode.geometry.firstMaterial.ambient.contents = wheelColor;
    wheelNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    SCNMatrix4 trans = SCNMatrix4MakeRotation(DEGTORAD(90), 0, 1 ,0);
    wheelNode.transform = trans;
    
    
    return wheelNode;
}

// TODO: Fix this

-(void)spinTheWheel
{
    SCNNode *wheelNode = [[self childNodeWithName:@"body" recursively:YES] childNodeWithName:@"wheel" recursively:YES];
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    {
        wheelNode.rotation = SCNVector4Make(0, 0, 1, DEGTORAD(720));
    }
    
    [SCNTransaction commit];

    
    
//    [SCNAction rotateByAngle:DEGTORAD(720) aroundAxis:SCNVector3Make(1, 0, 0) duration:3.0];
//    
//    [wheelNode runAction:[SCNAction rotateByAngle:DEGTORAD(180) aroundAxis:SCNVector3Make(1, 0, 0) duration:3.0]];
    
    // NSLog(@"wheelNode:%@",wheelNode);
    

}

-(void)animateFace
{
    [__faceLayer animate];
}








#pragma mark - Make Robot Name
-(NSString*)makeName
{
    return GenerateRobotName();
}

+(JDMRobotArmNode *)makeRobotArmRightSided:(BOOL)rightSided
{
    JDMRobotArmNode *robotNode = [[self alloc]init];
    
    robotNode.rightSided = rightSided;
    
    robotNode.primaryColor = [UIColor redColor];
    robotNode.secondaryColor = [UIColor orangeColor];
    robotNode.effectorColor = [UIColor blueColor];
    
    robotNode.name = [robotNode makeName];
    
    SCNNode *armNode = [robotNode shoulderNodeSize:0.75];
    
    [robotNode addChildNode:armNode];
    
    
    return robotNode;
}

+(JDMRobotArmNode *)makeRobotArmRightSided:(BOOL)rightSided withColors:(NSArray *)colors
{
    JDMRobotArmNode *robotNode = [[self alloc]init];
    
    robotNode.rightSided = rightSided;
    
    robotNode.primaryColor = [colors objectAtIndex:0];
    robotNode.secondaryColor = [colors objectAtIndex:1];
    robotNode.effectorColor = [UIColor blueColor];
    
    robotNode.name = [robotNode makeName];
    
    SCNNode *armNode = [robotNode shoulderNodeSize:0.75];
    
    [robotNode addChildNode:armNode];
    
    
    
    return robotNode;
    
}


@end
