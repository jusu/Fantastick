//
//  FSCache.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FSCache.h"

@implementation FSCache

+ (NSString*) getCacheDirectory: (NSString*) subdir
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docs = [paths objectAtIndex:0];
	NSString *docs_subdir = [docs stringByAppendingPathComponent: subdir];
	return docs_subdir;
}

+ (NSString*) getModelCacheDirectory
{
	return [FSCache getCacheDirectory: @"models"];
}

+ (void) clearCache: (NSString*) path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *files = [fileManager directoryContentsAtPath: path];

	NSEnumerator *e = [files objectEnumerator];
	NSString *file = 0;
	while((file = [e nextObject])) {
		NSError *err;
		if(![fileManager removeItemAtPath: [path stringByAppendingPathComponent: file] error: &err]) {
			NSLog(@"Cache file not deleted: %@", err);
		}
	}
}

+ (void) clearModelCache
{
	NSString *models = [FSCache getModelCacheDirectory];
	[FSCache clearCache: models];
}

+ (NSString*) stringWithCacheDirectory: (NSString*) file subdir: (NSString*) sub;
{
	NSString *docs_subdir = [FSCache getCacheDirectory: sub];

	// Create subdirectory if doesn't exist
	NSFileManager *fm = [NSFileManager defaultManager];
	if(![fm fileExistsAtPath: docs_subdir]) {
		[fm createDirectoryAtPath: docs_subdir attributes: nil];
	}

	NSString *final = [docs_subdir stringByAppendingPathComponent: file];
	return final;
}

+ (NSString*) stringWithModelDirectory: (NSString*) modelFile
{
	NSString *modelsdir = [FSCache getCacheDirectory: @"models"];
	NSString *final = [modelsdir stringByAppendingPathComponent: modelFile];
	return final;
}

+ (BOOL) isCached: (NSString*) fullPath
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL b = [fm fileExistsAtPath: fullPath];
	return b;
}

+ (NSString*) getModel: (NSString*) urlString
{
	NSArray *nameparts = [urlString componentsSeparatedByString: @"/"];
	if(![nameparts count]) {
		NSLog(@"Empty urlString to getModel()!");
		return @"";
	}

	// Host part
	NSString *hostUrl;
	if([nameparts count] > 1)
		hostUrl = [[nameparts subarrayWithRange: NSMakeRange(0, [nameparts count]-1)] componentsJoinedByString: @"/"];
	else
		hostUrl = urlString;

	// Name part of URL
	NSString *name = [nameparts lastObject];

	// Fetch all files separated with semicolons
	NSArray *files = [name componentsSeparatedByString: @":"];
	for(NSString *s in files) {
		// Cached?
		NSString* fullPath = [FSCache stringWithCacheDirectory: s subdir: @"models"];
		BOOL isCached = [FSCache isCached: fullPath];
		if(isCached)
			continue;

		// Not cached, fetch with urlString
		NSString *urlFile = [NSString stringWithFormat: @"%@/%@", hostUrl, s];
		NSData *data = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlFile]];
		if(![data length]) {
			NSLog(@"Could not fetch '%@'", urlString);
			return @"";
		}

		// Fetched, write to cache
		[data writeToFile: fullPath atomically: YES];
	}

	NSString *objFile = [FSCache stringWithCacheDirectory: [files objectAtIndex: 0] subdir: @"models"];
	return objFile;
}

@end

