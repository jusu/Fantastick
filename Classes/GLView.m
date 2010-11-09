//
//  GLView.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 2/19/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "GLView.h"
#import "GLModel.h"
#import "FSCache.h"
#import "FSBlockInfo.h"
#import "Transport.h"
#import "FantaStickViewController.h"

#define kSquareX 200.0
#define kSquareY 200.0

const GLfloat squareVertices[] = {
-kSquareX, -kSquareY,
kSquareX,  -kSquareY,
-kSquareX,  kSquareY,
kSquareX,   kSquareY
};

@interface GLView (private)

- (id)initGLES;
- (void)setupView;
- (void)drawView;
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)processImageBlock: (NSData*)d;
- (void)processCommand: (char*)cmd;

@end

@implementation GLView

@synthesize controller;
@synthesize TouchView;

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder 
{
	if (self = [super initWithCoder:coder]) {
		// Initialization code
		self.clearsContextBeforeDrawing = NO;
		
		models = [[NSMutableDictionary alloc] init];
		models_clearqueue = [[NSMutableDictionary alloc] init];

		controllerSetup = NO;
		clearRequested = NO;
		[self initGLES];
		
		web = [[UIWebView alloc] init];
		[web loadHTMLString: @"<html></html>" baseURL: [NSURL URLWithString: @"file:///"]];
		NSString *res = [web stringByEvaluatingJavaScriptFromString: @"(function(){ return 42; })();"];
		res = [web stringByEvaluatingJavaScriptFromString: @"var draw = function(){}"];
		res = [web stringByEvaluatingJavaScriptFromString: @"var _cmdq = []; var draw = function() {};"
			   "var _cmdq_poll = function() { var s; draw(); s = _cmdq.join('°'); _cmdq = []; return s; };"
			   "var touch = function(type, x, y, id) {}; var accel = function(x, y, z) {};"
			   "var fs = { cmd: function(s) { _cmdq.push('0'+s); }, send: function(s) { _cmdq.push('1'+s); } };"];
		jsCode = [[NSMutableArray alloc] init];

		jsTimer = nil;
	}
    return self;
}

-(void)activate
{
	self.hidden = NO; 
	[self startOpenGLAnimation];
}

-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}

-(id)initGLES
{
	CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
	
	// Configure it so that it is opaque, does not retain the contents of the backbuffer when displayed, and uses RGBA8888 color.
	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
									kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
									nil];
	
	// Create our EAGLContext, and if successful make it current and create our framebuffer.
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer])
	{
		[self release];
		return nil;
	}
	
	// Default the animation interval to 1/nth of a second.
	animationInterval = 1.0 / kRenderingFrequency;
	return self;
}

- (BOOL)createFramebuffer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen whereever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)startOpenGLAnimation
{
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}

- (void)stopOpenGLAnimation
{
	[animationTimer invalidate];
	animationTimer = nil;
	[self performSelectorOnMainThread: @selector(stopJSAnimation) withObject: nil waitUntilDone: NO];
}

- (void)startJSAnimation
{
	jsTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f / 25.0f target:self selector:@selector(pollJS) userInfo:nil repeats:YES];
}

- (void)stopJSAnimation
{
	[jsTimer invalidate];
	jsTimer = nil;
}

- (void)setAnimationInterval:(NSTimeInterval)interval
{
	animationInterval = interval;
	
	if(animationTimer)
	{
		[self stopOpenGLAnimation];
		[self startOpenGLAnimation];
	}
}

- (void) pollJS
{
	@synchronized(jsCode) {
		for(NSString *js in jsCode) {
			if(js) {
				NSString *res = [web stringByEvaluatingJavaScriptFromString: js];
				if(res.length) {
					NSLog(@"js '%@'", res);
				}
			}
		}
		[jsCode removeAllObjects];
	}

	NSString *s = [web stringByEvaluatingJavaScriptFromString: @"_cmdq_poll();"];
	if(s.length > 0) {
		char *next, *js = (char*)[s cStringUsingEncoding: NSUTF8StringEncoding];
		while(js) {
			next = strstr(js, "\xc2\xb0"); // °
			if(next) {
				next[0] = 0;
			}

			if(js[0] == '0') { // cmd
				[self processCommand: js+1];
			} else {
				if(js[0] == '1') { // send
					[[Transport sharedTransport] send: [NSString stringWithFormat: @"%s", js+1]];
				}
			}

			js = next;
			if(js) {
				js += 2;
			}
		}
	}
}

-(BOOL)jsActive
{
	return jsTimer != nil;
}

// evaluate js right away (instead of periodic polling)
- (void) doJS: (NSString*) s
{
	[web stringByEvaluatingJavaScriptFromString: s];
}

-(void)touch: (char) type x: (int) xpos y: (int) ypos num: (int) finger
{
	NSString *s = [NSString stringWithFormat: @"touch('%c', %d, %d, %d);", type, xpos, ypos, finger];
	[self doJS: s];
}

-(void)accelxacc: (double)x yacc: (double)y zacc: (double)z;
{
	NSString *s = [NSString stringWithFormat: @"accel(%f, %f, %f);", x, y, z];
	[self doJS: s];
}

// Updates the OpenGL view when the timer fires
- (void)drawView
{
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
	
	if(!controllerSetup)
	{
		[self setupView];
		controllerSetup = YES;
	}
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	[self drawGLView];
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	GLenum err = glGetError();
	if(err)
		NSLog(@"%x error", err);
}

-(void)setupView
{
	const GLfloat zNear = 0.1, 
	zFar = 1000.0, 
	fieldOfView = 54.5; 
	GLfloat size; 
	
	glMatrixMode(GL_PROJECTION); 
	glEnable(GL_DEPTH_TEST); 
	size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0); 
	CGRect rect = self.bounds; 
	glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size / 
			   (rect.size.width / rect.size.height), zNear, zFar); 
	glViewport(0, 0, rect.size.width, rect.size.height);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glMatrixMode(GL_MODELVIEW); 
	glShadeModel(GL_FLAT);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);

	glLoadIdentity();
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawGLView
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	@synchronized(models) {
		NSArray *glmodels = [models allValues];
		if(!clearRequested) {
			// DRAW opaque objects
			glDepthMask(GL_TRUE);
			for(GLModel *m in glmodels) {
				if(m.isOpaque) {
					@synchronized(m) {
						[m draw];
					}
				}
			}
			// Draw translucent objects
			glDepthMask(GL_FALSE);
			for(GLModel *m in glmodels) {
				if(!m.isOpaque) {
					@synchronized(m) {
						[m draw];
					}
				}
			}
			glDepthMask(GL_TRUE);
		} else {
			// CLEAR
			@synchronized(models_clearqueue) {
				for(GLModel *m in [models_clearqueue allValues]) {
					[m clear];
				}
				[models_clearqueue removeAllObjects];
				clearRequested = NO;
			}
		}
	}
}

#define BUFFERMAXLEN 65536
char buffer[BUFFERMAXLEN+4];

- (void)handleMessage: (id)msg
{
	// Avoid Cocoa allocations!
	NSData *d = (NSData*)msg;

	//NSLog(@"data length: %d", [d length]);
	
	unsigned char *s = (unsigned char*)[d bytes];
	// if last character is space, zero it. Fixes strange bug with Max/MSP and js object
	int len = [d length];
	if(s[len-1] == 32) {
		s[len-1] = 0;
	}

	if(len > BUFFERMAXLEN) {
		len = BUFFERMAXLEN;
	}

	bcopy(s, buffer, len);
	buffer[len] = 0;

	[self processCommand: (char*)&buffer];
}

- (void)processCommand: (char*)cmd
{
	// MODEL
	if(strncmp(cmd, "model ", 6) == 0) {
		cmd += 6;
		char *name_end = strchr(cmd, ' ');
		if(!name_end)
			return;
		name_end[0] = 0;

		// Model already created?
		NSString *s = [[NSString alloc] initWithCString: cmd];
		GLModel *m = 0;
		@synchronized(models) {
			m = [models objectForKey: s];
		}

		name_end[0] = ' ';
		name_end++;

		if(m == nil) {
			// No model, create
			m = [[GLModel alloc] initWithBytes: name_end];
			@synchronized(models) {
				[models setObject: m forKey: s];
			}
			[m release];
		} else {
			// Update existing model
			[m updateWithBytes: name_end];
		}
		[s release];
	} else
	// CLEAR
	if(strncmp(cmd, "clear ", 6) == 0) {
		cmd += 6;
		
		// Model already created?
		NSString *s = [[NSString alloc] initWithCString: cmd];
		GLModel *m = 0;
		@synchronized(models) {
			@synchronized(models_clearqueue) {
				m = [models objectForKey: s];
				if(m) {
					[models_clearqueue setObject: m forKey: s];
					[models removeObjectForKey: s];
					clearRequested = YES;
				}
			}
		}
		[s release];
	} else
	if(strncmp(cmd, "clearmodels", 11) == 0) {
		@synchronized(models) {
			@synchronized(models_clearqueue) {
				[models_clearqueue addEntriesFromDictionary: models];
				[models removeAllObjects];
				clearRequested = YES;
			}
		}
	} else
	if(strncmp(cmd, "accelerometer ", 14) == 0) {
		cmd += 14;
		if(!cmd)
			return;
		float accel = atof(cmd);
		UIAccelerometer *a = [UIAccelerometer sharedAccelerometer];
		if(accel == 0.0) {
			a.delegate = nil;
		} else {
			if(accel < 0.01)
				accel = 0.01;
			a.updateInterval = accel;
			a.delegate = controller;
		}
	} else
	if(strncmp(cmd, "clearimagecache", 15) == 0) {
		[TouchImage clearImageCache];
	} else
	if(strncmp(cmd, "clearmodelcache", 15) == 0) {
		[FSCache clearModelCache];
	} else
	// Back to Quartz?
	if(strncmp(cmd, "opengl 0", 8) == 0) {
		// Disable opengl
		[self stopOpenGLAnimation];
		self.hidden = YES;
		[TouchView activate];
	} else
	if(strncmp(cmd, "js ", 3) == 0) {
		cmd += 3;
		NSString *s = [[NSString alloc] initWithCString: cmd];
		@synchronized(jsCode) {
			[jsCode addObject: s];
		}
		[s release];
		
		if(jsTimer == nil) {
			[self performSelectorOnMainThread: @selector(startJSAnimation) withObject: nil waitUntilDone: NO];
		}
	} else
	if(strncmp(cmd, "jsurl ", 6) == 0) {
		cmd += 6;
		NSString *us = [[NSString alloc] initWithCString: cmd];
		NSURL *u = [[NSURL alloc] initWithString: us];
		NSString *s = [[NSString alloc] initWithContentsOfURL: u];
		if(s && s.length) {
			@synchronized(jsCode) {
				[jsCode addObject: s];
			}
		}
		[s release];
		[u release];
		[us release];

		if(jsTimer == nil) {
			[self performSelectorOnMainThread: @selector(startJSAnimation) withObject: nil waitUntilDone: NO];
		}
	} else
	if(strncmp(cmd, "camera ", 7) == 0) {
		cmd += 7;
		if(!cmd)
			return;
		int i=0;
		float cam[2];
		cam[0] = 0.0f;
		cam[1] = 0.0f;
		for(cmd = strtok(cmd, " "); i<2 && cmd; i++, cmd = strtok(NULL, " ")) {
			cam[i] = atof(cmd);
		}
		[GLModel setCamera: -cam[0] Y: -cam[1]];
	} else
	if(strncmp(cmd, "offset ", 7) == 0) {
		cmd += 7;
		if(!cmd)
			return;
		int i=0;
		int offset[2];
		offset[0] = 0.0f;
		offset[1] = 0.0f;
		for(cmd = strtok(cmd, " "); i<2 && cmd; i++, cmd = strtok(NULL, " ")) {
			offset[i] = atoi(cmd);
		}
		[FantaStickViewController setTouchOffset: offset[0] Y: offset[1]];
	}
	
}

- (void)dealloc {
	[self stopOpenGLAnimation];
	
	if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	[context release];
	context = nil;
	
	@synchronized(models) {
		[models release];
	}
				
	@synchronized(models_clearqueue) {
		[models_clearqueue release];
	}

	[web release];
	[jsCode release];
	
    [super dealloc];
}

@end

/*
 You can use std::map<std::string, functionpointer> to do this:
 
 std::map<std::string, void(*)(void)> x;
 x["bar"]=&function1;
 x["foo"]=&function2; //and so on
 
 //in input routine:
 std::string input;
 if(x.find(input)==x.end()) error(); // invalid input
 x[input](); // calls the associated function
 
 */
