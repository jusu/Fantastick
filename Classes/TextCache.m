//
//  TextCache.m
//  FantaStick
//
//  Created by Jusu Vehviläinen on 7/20/11.
//  Copyright 2011 Pink Twins. All rights reserved.
//

#import "TextCache.h"

@implementation TextCache

static NSMutableDictionary *textures = NULL;

+ (Texture2D*) get: (NSString*) text
{
	if (!textures) {
		return NULL;
	}

	return [textures objectForKey: text];
}

+ (void) put: (NSString*) text texture: (Texture2D*) t2d
{
	if (!textures) {
		textures = [[NSMutableDictionary alloc] init];
	}

	[textures setObject: t2d forKey: text];
}

+ (void) clear
{
	if (!textures) {
		return;
	}

	NSArray *t2ds = [textures allValues];
	for (Texture2D *t in t2ds) {
		[t deleteTexture];
	}

	[textures removeAllObjects];
}

@end
