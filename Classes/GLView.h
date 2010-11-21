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

typedef enum { portrait, left, right } orientation;

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
	
	// JS
	UIWebView *web;
	NSTimer *jsTimer;
	NSMutableArray *jsCode;
}

-(void)activate;
-(void)startOpenGLAnimation;
-(void)stopOpenGLAnimation;
-(void)drawGLView;
-(void)handleMessage: (id)msg;
-(BOOL)jsActive;
-(void)touch: (char)type x: (int)xpos y: (int)ypos num: (int)finger radius: (float)rad;
-(void)accelxacc: (double)x yacc: (double)y zacc: (double)z;
@property (nonatomic, retain) id controller;
@property (nonatomic, retain) id TouchView;

+ (orientation) orientation;

@end
