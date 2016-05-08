# NewScene
SceneKit take 2


## Overview

This project revisits the `SceneKit` framework with the introduction of the Scene Editor. meanwhile I had spent a few weeks working with Maya to learn more about 3D work. With new API's and a more understood approach to 3D programming I put together a "Demo" of experiments and allow you to cycle through each one by tapping on the screen.  

## Ball and Cube Physics 

![Alt Text](https://github.com/jmade/jmade.github.io/blob/master/throwball.gif?raw=true)

It was initially inspired by a rendered demo I saw and wanted to experiment with animations and physics in `SceneKit`.
Programattically created the cube grid, stacked them. tapping the screen will move the ball into the stack and you can watch boxes fall down using physics. 

![Alt Text](https://github.com/jmade/jmade.github.io/blob/master/restack.gif?raw=true)

Tapping again will animate the boxes back to their original position. 

## Its Raining SCNNodes

![Alt Text](https://github.com/jmade/jmade.github.io/blob/master/falling.gif?raw=true)

This step is to demo falling cubes from above.

## Explosions in the Sky

![Alt Text](https://github.com/jmade/jmade.github.io/blob/master/explode.gif?raw=true)

Tapping again will emit a force that will explode upon the cubes and boxes and fade them out. 

## Robo-Node

![Alt Text](https://github.com/jmade/jmade.github.io/blob/master/robot.gif?raw=true)

Tapping one more time will introduce you to a programatically created Robot! *The Robot will also get a name generated too!*

This was an experiment of creating a character and animating it using inverse kinematic constraints.

Tapping on the screen the robot will take turns pointing at the camera and pointing at the floor. All motions are simply reactions to telling the blue tip what to point at. The benefit is a somewhat realistic movement performed by a 3D object only by responding or reacting to the movement of the objects parts. 

The face for the Robot is created by using a custom `CALayer` as a texture for the `SCNMaterial` 

## CAShapeLayer...

Creating the shape of the mouth led me down an interesting road. If you pay close attention to the mouth when its animating you can see this phenomenon occur. Well maybe not "phenonmenon" but unexpected results. basically in order to change the bezier path shape I supply it with two different paths: Normal, a straight line and Smile, a curved line. The process of smiling is a transform of the first state and the last state but kinda like a smile "loading" from left to right. Since `CoreAnimation` does not get anymore information about the Smile, it simply stamps out a transform animation and thats what you have. This got me thinking about how shapes are made, or drawn, or "occur" and how a line works? What do the start and end of a line in a shape do when the shape is forming into another shape?!? To be continued...
