//
//  FSCache.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSCache : NSObject {
}

+ (NSString*) stringWithModelDirectory: (NSString*) modelFile;
+ (BOOL) isCached: (NSString*) fullPath;
+ (NSString*) getModel: (NSString*) urlString;
+ (void) clearModelCache;

@end
