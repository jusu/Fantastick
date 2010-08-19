//
//  TouchImage.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/10/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>

#define touchModeBegin 0
#define touchModeMove  1
#define touchModeEnd   2

@interface TouchImage : NSObject {
	CGRect bounds;
	
	CGLayerRef imageLayer;
	CGContextRef imageContext;
	
	NSString *name;
	
	CGPoint touchOrigin;
	
	UIImage *image_autoreleased;

	BOOL isMovable;
	BOOL isBeingMoved;
	BOOL isHidden;
}

@property (nonatomic, retain) NSString *name;
@property (readwrite) BOOL isMovable;
@property (readwrite) BOOL isBeingMoved;
@property (readwrite) BOOL isHidden;
@property (readwrite) CGLayerRef imageLayer;
@property (readwrite) CGRect bounds;
@property (readonly) UIImage *image_autoreleased;

- initWithURLString: (NSString*) urlString context: (CGContextRef) cont;

- (void) handle: (NSString*) message;
- (void) touch: (CGPoint)p mode: (int)m;

+ (void) clearImageCache;
+ (NSString*) stringWithCacheDirectory: (NSString*) imagefile;

@end
