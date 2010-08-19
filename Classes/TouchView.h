//
//  TouchView.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CFData.h>
#import "TouchImage.h"

@interface TouchView : UIView {
	id controller;
	id GLView;

	// Drawing
	NSTimer* drawTimer;

	float width, height;
	bool bNeedsDisplay;

	CGFloat strokeRed, strokeGreen, strokeBlue;
	CGFloat textAngle;
	CGFloat lineWidth;
	CGAffineTransform textMatrix;
	
	CGLayerRef drawLayer;
	CGContextRef drawContext;
	CGLayerRef frontLayer;
	CGContextRef frontContext;
	
	// touchObjects needs an interface class, now adding touchImages directly
	NSMutableDictionary *touchObjects;

	BOOL bHaveSomething;
	BOOL isOpenGLEnabled;

	IBOutlet UIView *resolvingView;
	IBOutlet UILabel *startupLabel;
	IBOutlet UIActivityIndicatorView *animationIndicator;
}

- (void)activate;
- (TouchImage*)touchPoint: (CGPoint)p mode: (int)m;
- (void)handleMessage: (id)msg;
- (void)draw;

@property (nonatomic, retain) UIView *resolvingView;
@property (nonatomic, retain) UILabel *startupLabel;
@property (nonatomic, retain) UIActivityIndicatorView *animationIndicator;

@property (nonatomic, retain) id controller;
@property (nonatomic, retain) id GLView;
@property (readwrite) BOOL bHaveSomething;

@end
