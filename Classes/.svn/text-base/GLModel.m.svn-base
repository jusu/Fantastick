//
//  GLModel.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 2/19/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import "GLModel.h"
#import "FSCache.h"

GLfloat squareTextures[] = {
	-0.0f, 0.0f,
	1.0f, 0.0f,
	0.0f, 1.0f,
	1.0f, 1.0f,
	-0.0f, 0.0f,
	1.0f, 0.0f,
	0.0f, 1.0f,
	1.0f, 1.0f
};

@interface GLModel (private)

- (void) updateTextString;
- (void) uploadBlockTexture;

@end

@implementation GLModel

- (id)initWithBytes: (char*)a
{
	[super init];

	color[0] = 1.0f;
	color[1] = 1.0f;
	color[2] = 1.0f;
	color[3] = 1.0f;
	rotate[0] = 0.0f;
	rotate[1] = 0.0f;
	rotate[2] = 0.0f;
	rotate[3] = 0.0f;
	scale[0] = 1.0f;
	scale[1] = 1.0f;
	scale[2] = 1.0f;
	position[0] = 0.0f;
	position[1] = 0.0f;
	position[2] = 0.0f;
	lineWidth = 1.0f;

	isPositionSet = NO;
	
	rendermode = GL_LINES;

	vertexCount = 0;
	vertexArray = NULL;
	
	timage = NULL;
	imageTexture = 0;
	imageCGImage = NULL;
	imageContext = NULL;
	imageData = NULL;
	imagewidth = imageheight = 0;
	isTextured = NO;
	shouldUploadTexture = NO;
	
	text2d = NULL;
	textString = NULL;
	fontName =[[NSString alloc] initWithString: @"Helvetica"];
	fontSize = 11;

	[self updateWithBytes: a];

	return self;
}

- (void)updateWithBytes: (char*)a
{
	if(!a || !a[0])
		return;

	if(strncmp(a, "xyz ", 4) == 0) {
		a += 4;
		if(!a)
			return;

		if(isTextured)
			return;

		// Allocate memory for points..
		free(vertexArray);
		long points = 0;
		char *b = a;
		for(b = strchr(b, ' '); b; b = strchr(b+1, ' '), points++)
			;
		points++;
		vertexArray = (float*)malloc(points * sizeof(float));

		// .. update coordinate data.
		points = 0;
		for(a = strtok(a, " "); a; a = strtok(NULL, " "), points++) {
			vertexArray[points] = atof(a);
		}
		vertexCount = points / 3;
	} else
	if(strncmp(a, "render ", 7) == 0) {
		a += 7;
		if(strcmp(a, "points") == 0)
			rendermode = GL_POINTS;
		else if(strcmp(a, "lines") == 0)
			rendermode = GL_LINES;
		else if(strcmp(a, "line_loop") == 0)
			rendermode = GL_LINE_LOOP;
		else if(strcmp(a, "line_strip") == 0)
			rendermode = GL_LINE_STRIP;
		else if(strcmp(a, "triangles") == 0)
			rendermode = GL_TRIANGLES;
		else if(strcmp(a, "triangle_strip") == 0)
			rendermode = GL_TRIANGLE_STRIP;
		else if(strcmp(a, "triangle_fan") == 0)
			rendermode = GL_TRIANGLE_FAN;
	} else
	if(strncmp(a, "color ", 6) == 0) {
		a += 6;
		if(!a)
			return;
		int i=0;
		for(a = strtok(a, " "); i<4 && a; i++, a = strtok(NULL, " ")) {
			color[i] = atof(a);
		}
	} else
	if(strncmp(a, "rotate ", 7) == 0) {
		a += 7;
		if(!a)
			return;
		int i=0;
		for(a = strtok(a, " "); i<4 && a; i++, a = strtok(NULL, " ")) {
			rotate[i] = atof(a);
		}
	} else
	if(strncmp(a, "scale ", 6) == 0) {
		a += 6;
		if(!a)
			return;
		int i=0;
		for(a = strtok(a, " "); i<3 && a; i++, a = strtok(NULL, " ")) {
			scale[i] = atof(a);
		}
	} else
	if(strncmp(a, "position ", 9) == 0) {
		a += 9;
		if(!a)
			return;
		int i=0;
		for(a = strtok(a, " "); i<3 && a; i++, a = strtok(NULL, " ")) {
			position[i] = atof(a);
		}
		isPositionSet = YES;
	} else
	if(strncmp(a, "width ", 6) == 0) {
		a += 6;
		if(!a)
			return;
		lineWidth = atof(a);
		if(lineWidth < 1.0f)
			lineWidth = 1.0f;
	} else
	if(strncmp(a, "image ", 6) == 0) {
		a += 6;
		if(!a)
			return;

		[timage release];

		// We need this
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		timage = [[TouchImage alloc] initWithURLString: [NSString stringWithCString: a] context: nil];

		imageCGImage = timage.image_autoreleased.CGImage;
		imagewidth = CGImageGetWidth(imageCGImage);
		imageheight = CGImageGetHeight(imageCGImage);

		// width, height, must be power of twos! resize if they are not?

		if(imageCGImage) {
			imageData = (GLubyte *)malloc(imagewidth * imageheight * 4);
			imageContext = CGBitmapContextCreate(imageData, imagewidth, imageheight, 8, imagewidth * 4,
												 CGImageGetColorSpace(imageCGImage), kCGImageAlphaPremultipliedLast);
			CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, (CGFloat)imagewidth, (CGFloat)imageheight), imageCGImage);
			CGContextRelease(imageContext);
			imageContext = NULL;
			
			glDeleteTextures(1, &imageTexture);
			glGenTextures(1, &imageTexture);
			glBindTexture(GL_TEXTURE_2D, imageTexture);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imagewidth, imageheight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);		
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			free(imageData);
			imageData = NULL;
			
			vertexArray = (float*)malloc(8 * sizeof(float));
			long halfwidth = imagewidth / 2, halfheight = imageheight / 2;
			vertexArray[0] = -halfwidth;
			vertexArray[1] = -halfheight;
			vertexArray[2] = halfwidth;
			vertexArray[3] = -halfheight;
			vertexArray[4] = -halfwidth;
			vertexArray[5] = halfheight;
			vertexArray[6] = halfwidth;
			vertexArray[7] = halfheight;
			vertexCount = 4;

			if(!isPositionSet) {
				// screen resolution magic numbers: 320 480 ...
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					// Running on iPad
					position[0] = 384.0f;
					position[1] = 512.0f;
					position[2] = 0.0f;
				} else {
					// Running on iPhone/iPod
					position[0] = 160.0f;
					position[1] = 240.0f;
					position[2] = 0.0f;
				}
#else
				// Running on iPhone/iPod
				position[0] = 160.0f;
				position[1] = 240.0f;
				position[2] = 0.0f;
#endif
				
				isPositionSet = YES;
			}

			// Set alpha just below 1.0 to draw as not-opaque
			color[3] = 0.999999f;

			isTextured = YES;
		}
		[pool release];
	} else
	if(strncmp(a, "text ", 5)==0) {
		a += 5;
		if(!a)
			return;
		
		// first time, set alpha to non-opaque
		if(!textString)
			color[3] = 0.999999f;

		[textString release];
		textString = [[NSString alloc] initWithCString: a length: strlen(a)];

		[self updateTextString];
	} else
	if(strncmp(a, "font ", 5)==0) {
		a += 5;
		if(!a)
			return;
		[fontName release];
		fontName = [[NSString alloc] initWithCString: a length: strlen(a)];

		[self updateTextString];
	} else
	if(strncmp(a, "fontsize ", 9)==0) {
		a += 9;
		if(!a)
			return;
		fontSize = atoi(a);
		if(fontSize <= 1)
			fontSize = 2;

		[self updateTextString];
	}
}

- (void) uploadBlockTexture
{
	if(!imageData) {
		shouldUploadTexture = NO;
		return;
	}

	glDeleteTextures(1, &imageTexture);
	glGenTextures(1, &imageTexture);
	glBindTexture(GL_TEXTURE_2D, imageTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imagewidth, imageheight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);		
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	position[0] = 256;
	position[1] = 256;
//swap	position[1] = bi->imageheight - bi->blocktop - (bi->blockheight / 2);
	isPositionSet = YES;

	// Set alpha just below 1.0 to draw as not-opaque
	color[3] = 0.999999f;

	isTextured = YES;
	shouldUploadTexture = NO;
}

- (void) updateTextString
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(text2d) {
		[text2d deleteTexture];
		[text2d release];
	}
	
	if([textString length] * fontSize >= 1000) {
		fontSize = 1000 / [textString length];
	}

	text2d = [[Texture2D alloc] initWithString: textString
									dimensions: CGSizeMake([textString length] * fontSize, fontSize*1.2)
									 alignment: UITextAlignmentLeft
									  fontName: fontName
									  fontSize: fontSize];
	
	[pool release];
}

- (BOOL) isOpaque
{
	return color[3] >= 1.0f;
}

- (void)draw
{
	if(!text2d && (!vertexCount || !vertexArray))
		return;

	if(shouldUploadTexture && imageData) {
		[self uploadBlockTexture];
	}

	glLoadIdentity();

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// Running on iPad, get to 768x1024
		glTranslatef(-384.0f, 512.0f, -747.1f); // magic number
		glRotatef(0.0, 0.0, 0.0, 1.0);
		glScalef(1.0f, -1.001f, 1.0f);
	} else {
		// Running on iPhone/iPod, get to 320x480
		glTranslatef(-160.0f, 240.0f, -312.0f); // magic number
		glRotatef(0.0, 0.0, 0.0, 1.0);
		glScalef(1.0f, -1.001f, 1.0f);
	}
#else
	// Running on iPhone/iPod, get to 320x480
	glTranslatef(-160.0f, 240.0f, -312.0f); // magic number
	glRotatef(0.0, 0.0, 0.0, 1.0);
	glScalef(1.0f, -1.001f, 1.0f);
#endif
		
	glLineWidth(lineWidth);
	
	glColor4f(color[0], color[1], color[2], color[3]);
	glTranslatef(position[0], position[1], position[2]);
	glRotatef(rotate[0], rotate[1], rotate[2], rotate[3]);
	glScalef(scale[0], scale[1], scale[2]);

	if(isTextured) {
		glEnable(GL_TEXTURE_2D);
		glDisableClientState(GL_NORMAL_ARRAY);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		
		glBindTexture(GL_TEXTURE_2D, imageTexture);
		glVertexPointer(2, GL_FLOAT, 0, vertexArray);
		glTexCoordPointer(2, GL_FLOAT, 0, squareTextures);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		return;
	}

	if(text2d) {
		glEnable(GL_TEXTURE_2D);
		glDisableClientState(GL_NORMAL_ARRAY);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);

		// texture is upside down
		glScalef(scale[0], -scale[1], scale[2]);
		
		[text2d drawAtPoint: CGPointMake(0, 0)];

		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	}

	if(vertexArray && vertexCount) {
		// Our simplistic xyz-created model
		glEnableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_NORMAL_ARRAY);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glVertexPointer(3, GL_FLOAT, 0, vertexArray);
		glDrawArrays(rendermode, 0, vertexCount);
	}
}

- (void)clear
{
	if(isTextured) {
		glDeleteTextures(1, &imageTexture);
	}
	if(text2d) {
		[text2d deleteTexture];
	}
}

- (void) dealloc
{
	free(vertexArray);
	[timage release];
	[text2d release];
	[textString release];
	[fontName release];

	[super dealloc];
}

@end
