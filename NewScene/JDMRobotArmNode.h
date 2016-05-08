//
//  JDMRobotArmNode.h
//  NewScene
//
//  Created by Justin Madewell on 7/7/15.
//  Copyright © 2015 Justin Madewell. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "JDMUtility.h"

static inline SCNVector3 AAPLMatrix4GetPosition(SCNMatrix4 matrix) {
    return (SCNVector3) {matrix.m41, matrix.m42, matrix.m43};
}

static inline SCNMatrix4 AAPLMatrix4SetPosition(SCNMatrix4 matrix, SCNVector3 v) {
    matrix.m41 = v.x; matrix.m42 = v.y; matrix.m43 = v.z;
    return matrix;
}

static inline CGFloat AAPLRandomPercent() {
    return ((rand() % 100)) * 0.01f;
}



@interface JDMRobotArmNode : SCNNode

@property (nonatomic, strong) SCNIKConstraint *ikConstraint;

@property (nonatomic, strong) SCNIKConstraint *leftArmIKConstraint;
@property (nonatomic, strong) SCNIKConstraint *rightArmIKConstraint;
@property CGFloat leftArmMaxAngle;
@property CGFloat rightArmMaxAngle;

@property (nonatomic, strong) UIColor *effectorColor;

@property (nonatomic, strong) UIColor *upperColor;
@property (nonatomic, strong) UIColor *lowerColor;

@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIColor *secondaryColor;

//@property (nonatomic, strong) JDMTextureLayer *_faceLayer;



@property BOOL rightSided;


+(JDMRobotArmNode*)makeRobot;

+(JDMRobotArmNode*)makeRobotArmRightSided:(BOOL)rightSided;

+(JDMRobotArmNode*)makeRobotArmRightSided:(BOOL)rightSided withColors:(NSArray*)colors;


-(void)moveArm:(NSString*)armString byAmount:(CGFloat)angle;


-(void)activateIKConstraintsForLeftArm;
-(void)activateIKConstraintsForRightArm;
-(void)activateIKConstraints;



-(void)updateTargetPosition:(SCNVector3)newTargetPosition;
-(void)spinTheWheel;

-(void)animateFace;




@end
