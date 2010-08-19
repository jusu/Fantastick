//
//  GLView.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 2/19/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <AVFoundation/AVAudioPlayer.h>

// Macros
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

// How many times a second to refresh the screen
#define kRenderingFrequency 50.0

@interface GLView : UIView {
	id controller;
	id TouchView;

	// OpenGL
	EAGLContext *context;
	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint depthRenderbuffer;
	NSTimer *animationTimer;
	NSTimeInterval animationInterval;
	GLint backingWidth;
	GLint backingHeight;
	BOOL controllerSetup;
	BOOL clearRequested;

	// Hold GLModels
	NSMutableDictionary* models;
	NSMutableDictionary* models_clearqueue;
}

-(void)activate;
-(void)startOpenGLAnimation;
-(void)stopOpenGLAnimation;
-(void)drawGLView;
-(void)handleMessage: (id)msg;

@property (nonatomic, retain) id controller;
@property (nonatomic, retain) id TouchView;

@end
