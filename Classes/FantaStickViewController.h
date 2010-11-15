//
//  FantaStickViewController.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright Pink Twins 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Transport.h"

#define kFingersMax 11

@interface FantaStickViewController : UIViewController <UIAlertViewDelegate, UIAccelerometerDelegate> {
	id glview;

	Transport *transport;		// udp sender/receiver
	NSTimer *ipTimer;
	MPVolumeView *volumeEventView;

	UInt32 fingers[kFingersMax];			// fingertracking
	NSString *appleLove1;
}

- (void)hostnameNotSet;
- (void)hostNotFound;

- (void) volumeChanged: (NSNotification *)notify;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event; 
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event; 
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;

- (void)sendTouches:(NSSet*)touches mode: (int)m;

- (void)hideStartupAnimation;

+ (void) setTouchOffset: (int)x Y: (int)y;

@property (nonatomic, retain) id glview;

@end

