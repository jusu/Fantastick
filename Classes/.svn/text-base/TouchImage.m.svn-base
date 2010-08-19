//
//  TouchImage.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/10/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import "TouchImage.h"


@implementation TouchImage

@synthesize name;
@synthesize isMovable;
@synthesize isBeingMoved;
@synthesize isHidden;
@synthesize imageLayer;
@synthesize bounds;
@synthesize image_autoreleased;

+ (void) clearImageCache
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docs = [paths objectAtIndex:0];
	NSString *docs_images = [docs stringByAppendingPathComponent: @"images"];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *imagefiles = [fileManager directoryContentsAtPath: docs_images];

	NSEnumerator *e = [imagefiles objectEnumerator];
	NSString *file = 0;
	while((file = [e nextObject])) {
		NSError *err;
		if(![fileManager removeItemAtPath: [docs_images stringByAppendingPathComponent: file] error: &err]) {
			NSLog(@"Image file not deleted: %@", err);
		}
	}
}

+ (NSString*) stringWithCacheDirectory: (NSString*) imagefile;
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docs = [paths objectAtIndex:0];
	NSString *docs_images = [docs stringByAppendingPathComponent: @"images"];
	
	// Create images-directory if doesn't exist
	NSFileManager *fm = [NSFileManager defaultManager];
	if(![fm fileExistsAtPath: docs_images]) {
		[fm createDirectoryAtPath: docs_images attributes: nil];
	}
	
	NSString *final = [docs_images stringByAppendingPathComponent: imagefile];
	return final;
}

- (void) dealloc
{
	CGLayerRelease(imageLayer);
	[super dealloc];
}

- initWithURLString: (NSString*) urlString context: (CGContextRef) cont
{
	[super init];
	
	imageLayer = NULL;
	imageContext = NULL;

	NSArray *nameparts = [urlString componentsSeparatedByString: @"/"];
	if(![nameparts count]) {
		NSLog(@"Empty urlString to TouchImage!");
		return self;
	}
	
	// Name part of URL
	name = [nameparts lastObject];

	// Check if image already exists as file
	NSString *imageCache = [TouchImage stringWithCacheDirectory: name];
	UIImage *imageData = [UIImage imageWithContentsOfFile: imageCache];

	// Not cached
	if(imageData == nil) {
		// Fetch?
		NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlString]];
		imageData = [[[UIImage alloc] initWithData: data] autorelease];
		if(imageData == nil) {
			imageData = [UIImage imageNamed: @"nodata.png"]; // revert to placeholder
		} else {
			// Got image. Save to cache.
			[data writeToFile: imageCache atomically: YES];
		}
	}
	
	// Image is guaranteed to exist, but also autoreleased
	image_autoreleased = imageData;

	bounds = CGRectMake(0, 0, imageData.size.width, imageData.size.height);

	// No context? This is enough.
	if(cont == nil)
		return self;

	// Create layer from image, draw image there
	imageLayer = CGLayerCreateWithContext(cont, CGSizeMake(bounds.size.width, bounds.size.height), NULL);
	imageContext = CGLayerGetContext(imageLayer);
	
	// Flip y
	// Save the context state  
	CGContextSaveGState(imageContext);
	CGContextTranslateCTM(imageContext, 0, bounds.size.height);  
	CGContextScaleCTM(imageContext, 1.0, -1.0);  
	
	// Draw
	CGContextDrawImage(imageContext, bounds, imageData.CGImage);
	
	// Restore the context  
	CGContextRestoreGState(imageContext);
	
	return self;
}

- (void) handle: (NSString*) message
{
	NSArray *i = [message componentsSeparatedByString: @" "];
	// point
	if([i count] == 5 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"point"]) {
		bounds.origin = CGPointMake([[i objectAtIndex: 3] floatValue], [[i objectAtIndex: 4] floatValue]);
	}

	// size
	if([i count] == 5 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"size"]) {
		bounds.size = CGSizeMake([[i objectAtIndex: 3] floatValue], [[i objectAtIndex: 4] floatValue]);
	}

	if([i count] == 3 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"hide"]) {
		isHidden = YES;
	}

	if([i count] == 3 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"show"]) {
		isHidden = NO;
	}

	if([i count] == 3 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"movable"]) {
		isMovable = YES;
	}
	
	if([i count] == 3 && [[i objectAtIndex: 0] isEqual: @"set"] && [[i objectAtIndex: 2] isEqual: @"immovable"]) {
		isMovable = NO;
	}
	
}

- (void) touch: (CGPoint)p mode: (int)m;
{
	if(m == touchModeBegin) {
		// touchOrigin - point of contact WITHIN bounds
		touchOrigin = CGPointMake(p.x - bounds.origin.x, p.y - bounds.origin.y);
		isBeingMoved = YES;
		return;
	}
	if(m == touchModeMove) {
		if(isBeingMoved) {
			bounds.origin = CGPointMake(p.x - touchOrigin.x, p.y - touchOrigin.y);
		}
		return;
	}
	if(m == touchModeEnd) {
		isBeingMoved = NO;
		return;
	}
}

@end
