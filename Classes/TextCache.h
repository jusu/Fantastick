//
//  TextCache.h
//  FantaStick
//
//  Created by Jusu Vehviläinen on 7/20/11.
//  Copyright 2011 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Texture2D.h"

@interface TextCache : NSObject {
}

+ (Texture2D*) get: (NSString*) text;
+ (void) put: (NSString*) text texture: (Texture2D*) t2d;
+ (void) clear;

@end
