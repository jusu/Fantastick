//
//  TouchView.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "TouchView.h"
#import "TouchImage.h"
#import "FantaStickViewController.h"

#define RADIANS( degrees ) ( degrees * M_PI / 180 )

@interface TouchView (private)

- (void)startAnimation;
- (void)stopAnimation;
- (void)processDrawing: (id)msg;

@end

@implementation TouchView

@synthesize resolvingView;
@synthesize startupLabel;
@synthesize animationIndicator;

@synthesize controller;
@synthesize GLView;
@synthesize bHaveSomething;

- (id)initWithCoder:(NSCoder*)coder 
{

	if (self = [super initWithCoder:coder]) {
		// Initialization code
		self.clearsContextBeforeDrawing = NO;

		drawLayer = frontLayer = 0;
		width = [self bounds].size.width;
		height = [self bounds].size.height;
		touchObjects = [[NSMutableDictionary alloc] init];
		
		strokeRed = strokeGreen = strokeBlue = 1.0f;
		textAngle = 0.0f;
		lineWidth = 2.0f;

//		[cmdArray addObject: @"font TimesNewRomanPSMT 18"];

		bNeedsDisplay = YES;
		bHaveSomething = NO; // Received anything via udp yet?
		isOpenGLEnabled = NO;

		[self startAnimation];
	}
    return self;
}

- (void)activate
{
	isOpenGLEnabled = NO;
	[self startAnimation];
	self.hidden = NO;
}

- (void)startAnimation
{
	drawTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / 100.0f) target:self selector:@selector(draw) userInfo:nil repeats:YES];
}

- (void)stopAnimation
{
	[drawTimer invalidate];
}

- (TouchImage*)touchPoint: (CGPoint)p mode: (int)m
{
	if(![touchObjects count])
		return NULL;
	
	NSEnumerator *e = [touchObjects objectEnumerator];
	TouchImage *ti = 0;
	while((ti = [e nextObject])) {
		if(!ti.isHidden && ti.isMovable && (ti.isBeingMoved || CGRectContainsPoint(ti.bounds, p))) {
			[ti touch: p mode: m];
// no. check other images too.			return ti;
		}
	}
	return NULL;
}

- (void)handleMessage: (id)msg
{
	if(isOpenGLEnabled) {
		[GLView handleMessage: msg];
		return;
	}

	bHaveSomething = YES;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self processDrawing: msg];
	[pool release];
}

- (void)draw
{
	if(bNeedsDisplay) {
		[self setNeedsDisplay];
		bNeedsDisplay = NO;
	}
}

// ??
void swapf(float *a, float *b)
{
	float x = *a;
	*a = *b;
	*b = x;
}

- (void)processDrawing: (id)msg
{
	if(!frontLayer)
		return;

	NSData *d = msg;
	//NSString *s = [[[NSString alloc] initWithCString: [d bytes] encoding: NSASCIIStringEncoding] autorelease];
	NSString *s = [[[NSString alloc] initWithData: d encoding: NSASCIIStringEncoding] autorelease];

	// If drawArray includes the refresh-command, mark refreshing neccessary, and refresh after handling all commands.
	// This way refreshing is done only once at the end.
	BOOL doRefresh = NO;

	CGContextRef c = drawContext;

	do {
		NSArray *i = [s componentsSeparatedByString: @" "];
		NSString *cmd = [i objectAtIndex: 0];
		int count = [i count];

		// SWAPBUFFERS
		if([cmd isEqualToString: @"@"]) {
			doRefresh = YES;
			continue;
		}

		// BASIC DRAWING
		if(count == 4 && [cmd isEqualToString: @"color"]) {
			strokeRed = [[i objectAtIndex: 1] floatValue];
			strokeGreen = [[i objectAtIndex: 2] floatValue];
			strokeBlue = [[i objectAtIndex: 3] floatValue];
			continue;
		}

		if(count == 2 && [cmd isEqualToString: @"width"]) {
			lineWidth = [[i objectAtIndex: 1] floatValue];
			continue;
		}

		if(count == 5 && [cmd isEqualToString: @"line"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];
		
			CGContextSetLineWidth(c, lineWidth);
			CGContextSetRGBStrokeColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextMoveToPoint(c, x1, y1);
			CGContextAddLineToPoint(c, x2, y2);
			CGContextStrokePath(c);
			continue;
		}

		if(count == 5 && [cmd isEqualToString: @"rect"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];

			if(x1 > x2)
				swapf(&x1, &x2);
			if(y1 > y2)
				swapf(&y1, &y2);

			CGContextSetRGBFillColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextFillRect(c, CGRectMake(x1, y1, x2-x1, y2-y1));
			continue;
		}

		// CLEARING
		if(count < 5 && [cmd isEqualToString: @"clear"]) {

//			CGContextSetRGBFillColor(c, 0.0, 0.0, 0.0, 1.0);
//			CGContextFillRect(c, CGRectMake(0, 0, width, height));

			CGContextClearRect(c, CGRectMake(0, 0, width, height));
			continue;
		}
	
		if(count == 5 && [cmd isEqualToString: @"clear"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];

			if(x1 > x2)
				swapf(&x1, &x2);
			if(y1 > y2)
				swapf(&y1, &y2);

//			CGContextSetRGBFillColor(c, 0.0, 0.0, 0.0, 1.0);
//			CGContextFillRect(c, CGRectMake(x1, y1, fabsf(x2-x1), fabsf(y2-y1)));

			CGContextClearRect(c, CGRectMake(x1, y1, x2-x1, y2-y1));
			continue;
		}

		// IMAGE related
		if(count == 2 && [cmd isEqualToString: @"image"]) {
			NSString *url = [i objectAtIndex: 1];
			TouchImage *ti = [[TouchImage alloc] initWithURLString: url context: c];

			// Same image already loaded? Remove previous
			id previous = [touchObjects objectForKey: [ti name]];
			if(previous != nil) {
				[touchObjects removeObjectForKey: [ti name]];
			}

			[touchObjects setObject: ti forKey: [ti name]];
			[ti release];
			continue;
		}
		
		if(count > 2 && [cmd isEqualToString: @"set"]) {
			// See if object with name on index 1 exists, and forward message
			NSString *name = [i objectAtIndex: 1];
			id o = [touchObjects objectForKey: name];
			if(o != nil) {
				[o handle: s];
			}
			continue;
		}

		if([cmd isEqualToString: @"clearimages"]) {
			[touchObjects removeAllObjects];
			continue;
		}

		if([cmd isEqualToString: @"clearimagecache"]) {
			[TouchImage clearImageCache];
			continue;
		}
		
		// TEXT related
		if(count == 3 && [cmd isEqualToString: @"font"]) {
			float size = [[i objectAtIndex: 2] floatValue];
			CGContextSelectFont(c, [[i objectAtIndex: 1] cStringUsingEncoding: NSUTF8StringEncoding], size, kCGEncodingMacRoman);
			CGContextSetTextDrawingMode(c, kCGTextFill);
			textMatrix = CGAffineTransformMakeScale(1.0, -1.0);
			continue;
		}

		if(count >= 4 && [cmd isEqualToString: @"text"]) {
			float x = [[i objectAtIndex: 1] floatValue];
			float y = [[i objectAtIndex: 2] floatValue];
			NSRange range = NSMakeRange(3, [i count] - 3);
			NSArray *text_arr = [i subarrayWithRange: range];
			NSString *text_str = [text_arr componentsJoinedByString: @" "];

			CGAffineTransform t =  CGAffineTransformMakeRotation(RADIANS(textAngle));
			CGContextSetTextMatrix(c, CGAffineTransformConcat(t, textMatrix));
			CGContextSetRGBFillColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextShowTextAtPoint(c, x, y, [text_str cStringUsingEncoding: NSUTF8StringEncoding], [text_str length]);
			continue;
		}

		if(count == 2 && [cmd isEqualToString: @"textangle"]) {
			textAngle = [[i objectAtIndex: 1] floatValue];
			continue;
		}

		if(count == 2 && [cmd isEqualToString: @"accelerometer"]) {
			float accel = [[i objectAtIndex: 1] floatValue];
			UIAccelerometer *a = [UIAccelerometer sharedAccelerometer];
			if(accel == 0.0) {
				a.delegate = nil;
			} else {
				if(accel < 0.01)
					accel = 0.01;
				a.updateInterval = accel;
				a.delegate = controller;
			}
			continue;
		}
		
		if(count == 2 && [cmd isEqualToString: @"opengl"]) {
			int state = [[i objectAtIndex: 1] intValue];
			if(state == 1) {
				// Enable opengl
				isOpenGLEnabled = YES;
				[self stopAnimation];
				[GLView activate];
			}
		}
		
		if (count == 2 && [cmd isEqualToString: @"area"]) {
			int state = [[i objectAtIndex: 1] intValue];
			if (state == 0) {
				[FantaStickViewController setAreaData: NO];
			} else if (state == 1) {
				[FantaStickViewController setAreaData: YES];
			}
			continue;
		}
		
	} while(false);

	if(doRefresh) {
		@synchronized(drawTimer) {
			CGContextClearRect(frontContext, CGRectMake(0, 0, width, height));
		
			// draw other touchObject layers
			NSEnumerator *obe = [touchObjects objectEnumerator];
			TouchImage *ti = 0;
			while((ti = [obe nextObject])) {
				if(!ti.isHidden) {
					CGContextDrawLayerInRect(frontContext, ti.bounds, ti.imageLayer);
				}
			}
		
			// "swap" drawLayer to front
			CGContextDrawLayerAtPoint(frontContext, CGPointMake(0.0f, 0.0f), drawLayer);
		}

		bNeedsDisplay = YES;
	}
}

- (void)drawRect:(CGRect)rect {
	
	bNeedsDisplay = NO;
	
	if(!drawLayer) {
		drawLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(width, height), NULL);
		frontLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(width, height), NULL);
		drawContext = CGLayerGetContext(drawLayer);
		frontContext = CGLayerGetContext(frontLayer);
		
		char *fontInit = "font TimesNewRomanPSMT 18";
		[self processDrawing: [NSData dataWithBytes: fontInit length: strlen(fontInit)]];
	}

	@synchronized(drawTimer) {
		CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointMake(0.0f, 0.0f), frontLayer);
	}
}

- (void)dealloc {
	CGLayerRelease(drawLayer);
	CGLayerRelease(frontLayer);
	[drawTimer release];
	[touchObjects release];
    [super dealloc];
}

@end
