//
//  TouchView.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import "TouchView.h"
#import "TouchImage.h"

@implementation TouchView

@synthesize resolvingView;
@synthesize startupLabel;
@synthesize animationIndicator;

@synthesize controller;

- (id)initWithCoder:(NSCoder*)coder 
{
	if (self = [super initWithCoder:coder]) {
		// Initialization code
		self.clearsContextBeforeDrawing = NO;
		
		cmdArray = [[NSMutableArray alloc] init];
		drawTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / 50.0f) target:self selector:@selector(draw) userInfo:nil repeats:YES];
		drawLayer = frontLayer = 0;
		width = [self bounds].size.width;
		height = [self bounds].size.height;
		touchObjects = [[NSMutableDictionary alloc] init];
		
		strokeRed = strokeGreen = strokeBlue = 1.0f;

		// Thread for processing cmdArray
		[NSThread detachNewThreadSelector: @selector(processingThread) toTarget: self withObject: nil];
		
		[cmdArray addObject: @"font TimesNewRomanPSMT 18"];
		bNeedsDisplay = YES;
	}
    return self;
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
			return ti;
		}
	}
	return NULL;
}

- (void)handleMessage: (id)msg
{
	NSString *s = [[NSString alloc] initWithData: msg encoding: NSISOLatin1StringEncoding];
	@synchronized(cmdArray) {
		[cmdArray addObject: s];
	}
	bNeedsDisplay = YES;
}

- (void)handleMessageString: (NSString*)msg;
{
	@synchronized(cmdArray) {
		[cmdArray addObject: msg];
	}
	bNeedsDisplay = YES;
}

- (void)draw
{
	if(bNeedsDisplay) {
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect {

	bNeedsDisplay = NO;

	if(!drawLayer) {
		drawLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(width, height), NULL);
		frontLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), CGSizeMake(width, height), NULL);
		drawContext = CGLayerGetContext(drawLayer);
		frontContext = CGLayerGetContext(frontLayer);
	}

	CGContextDrawLayerAtPoint(UIGraphicsGetCurrentContext(), CGPointMake(0.0f, 0.0f), frontLayer);
}

- (void)processingThread
{
	NSAutoreleasePool *threadpool = [[NSAutoreleasePool alloc] init];

	NSRunLoop* loop = [NSRunLoop currentRunLoop];
	[NSTimer scheduledTimerWithTimeInterval: 1.0f / 10.0f target: self selector: @selector(processCmdArray)
								   userInfo: nil repeats: YES];

	[loop run];

	[threadpool release];
}

- (void)processCmdArray
{
	if(!drawLayer) // not yet inited?
		return;

	// Nothing to draw?
	if(![cmdArray count]) {
		return;
	}

	// Create a working copy of cmdArray, and clear cmdArray to keep duration of synchronization
	// as small as possible. This allows the socket reading thread to keep putting commands to it.
	NSArray *drawArray;
	@synchronized(cmdArray) {
		drawArray = [cmdArray copy];
		[cmdArray removeAllObjects];
	}

	CGContextRef c = drawContext;
	
	NSEnumerator *e = [drawArray objectEnumerator];
	NSString *s = 0;
	while((s = [e nextObject])) {
		NSArray *i = [s componentsSeparatedByString: @" "];

		// SWAPBUFFERS
		if([i count] == 2 && [[i objectAtIndex: 0] isEqual: @"@"]) {
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

		// BASIC DRAWING
		if([i count] == 4 && [[i objectAtIndex: 0] isEqual: @"color"]) {
			strokeRed = [[i objectAtIndex: 1] floatValue];
			strokeGreen = [[i objectAtIndex: 2] floatValue];
			strokeBlue = [[i objectAtIndex: 3] floatValue];
		}

		if([i count] == 5 && [[i objectAtIndex: 0] isEqual: @"line"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];
		
			CGContextSetLineWidth(c, 2.0);
			CGContextSetRGBStrokeColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextMoveToPoint(c, x1, y1);
			CGContextAddLineToPoint(c, x2, y2);
			CGContextStrokePath(c);
		}

		if([i count] == 5 && [[i objectAtIndex: 0] isEqual: @"rect"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];
			
			CGContextSetRGBFillColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextFillRect(c, CGRectMake(x1, y1, fabsf(x2-x1), fabsf(y2-y1)));
		}

		// CLEARING
		if([i count] == 2 && [[i objectAtIndex: 0] isEqual: @"clear"]) {
/*
			CGContextSetRGBFillColor(c, 0.0, 0.0, 0.0, 1.0);
			CGContextFillRect(c, CGRectMake(0, 0, width, height));
*/
			CGContextClearRect(c, CGRectMake(0, 0, width, height));
		}
	
		if([i count] == 5 && [[i objectAtIndex: 0] isEqual: @"clear"]) {
			float x1 = [[i objectAtIndex: 1] floatValue];
			float y1 = [[i objectAtIndex: 2] floatValue];
			float x2 = [[i objectAtIndex: 3] floatValue];
			float y2 = [[i objectAtIndex: 4] floatValue];
/*
			CGContextSetRGBFillColor(c, 0.0, 0.0, 0.0, 1.0);
			CGContextFillRect(c, CGRectMake(x1, y1, fabsf(x2-x1), fabsf(y2-y1)));
*/
			CGContextClearRect(c, CGRectMake(x1, y1, fabsf(x2-x1), fabsf(y2-y1)));
		}

		// IMAGE related
		if([i count] == 2 && [[i objectAtIndex: 0] isEqual: @"image"]) {
			NSString *url = [i objectAtIndex: 1];
			TouchImage *ti = [[TouchImage alloc] initWithURLString: url];

			// Same image already loaded? Remove previous
			id previous = [touchObjects objectForKey: [ti name]];
			if(previous != nil) {
				[touchObjects removeObjectForKey: [ti name]];
				[previous release];
			}

			[touchObjects setObject: ti forKey: [ti name]];
		}
		
		if([i count] > 2 && [[i objectAtIndex: 0] isEqual: @"set"]) {
			// See if object with name on index 1 exists, and forward message
			NSString *name = [i objectAtIndex: 1];
			id o = [touchObjects objectForKey: name];
			if(o != nil) {
				[o handle: s];
			}
		}

		if([i count] == 2 && [[i objectAtIndex: 0] isEqual: @"clearimages"]) {
			[touchObjects removeAllObjects];
		}

		if([i count] == 2 && [[i objectAtIndex: 0] isEqual: @"clearimagecache"]) {
			[TouchImage clearImageCache];
		}
		
		// TEXT related
		if([i count] == 3 && [[i objectAtIndex: 0] isEqual: @"font"]) {
			float size = [[i objectAtIndex: 2] floatValue];
			CGContextSelectFont(c, [[i objectAtIndex: 1] cStringUsingEncoding: NSUTF8StringEncoding], size, kCGEncodingMacRoman);
			CGContextSetTextDrawingMode(c, kCGTextFill);
			CGAffineTransform t;
			t = CGAffineTransformMakeScale(1.0, -1.0);
			CGContextSetTextMatrix(c, t);
		}

		if([i count] >= 4 && [[i objectAtIndex: 0] isEqual: @"text"]) {
			float x = [[i objectAtIndex: 1] floatValue];
			float y = [[i objectAtIndex: 2] floatValue];
			NSRange range = NSMakeRange(3, [i count] - 3);
			NSArray *text_arr = [i subarrayWithRange: range];
			NSString *text_str = [text_arr componentsJoinedByString: @" "];

			CGContextSetRGBFillColor(c, strokeRed, strokeGreen, strokeBlue, 1.0);
			CGContextShowTextAtPoint(c, x, y, [text_str cStringUsingEncoding: NSUTF8StringEncoding], [text_str length]);
		}

		[s release];
	}

	[drawArray release];

	bNeedsDisplay = YES;
}

- (void)dealloc {
	CGLayerRelease(drawLayer);
	CGLayerRelease(frontLayer);
	[cmdArray release];
	[drawTimer release];
	[touchObjects release];
    [super dealloc];
}

@end
