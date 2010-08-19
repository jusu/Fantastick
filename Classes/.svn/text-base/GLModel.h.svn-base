//
//  GLModel.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 2/19/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <UIKit/UIDevice.h>
#import "TouchImage.h"
#import "Texture2D.h"
#import "FSBlockInfo.h"

@interface GLModel : NSObject {
	GLfloat color[4];
	GLfloat rotate[4];
	GLfloat scale[3];
	GLfloat position[3];
	GLfloat lineWidth;

	BOOL isPositionSet;

	// texture
	TouchImage *timage;
	GLuint			imageTexture;
	CGImageRef		imageCGImage;
	CGContextRef	imageContext;
	GLubyte			*imageData;
	size_t			imagewidth, imageheight;
	BOOL			isTextured;
	BOOL			shouldUploadTexture; // should upload tx on next draw

	// Text object
	Texture2D		*text2d;
	NSString		*textString;
	NSString		*fontName;
	int				fontSize;

	GLenum rendermode;

	long vertexCount;
	float *vertexArray;
}

@property (nonatomic, readonly) BOOL isOpaque;

- (id)initWithBytes: (char*)a;
- (void)updateWithBytes: (char*)a;
- (void)draw;
- (void)clear;

@end
