//
//  FantaStickViewController.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright Pink Twins 2009. All rights reserved.
//

#import "FantaStickViewController.h"
#import "TouchView.h"
#import "TouchImage.h"

@implementation FantaStickViewController

int touchOffsetX = 0;
int touchOffsetY = 0;

@synthesize glview;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

void rot13(char *str)
{
	int len = strlen(str);
	char byte, cap;
	for (int i=0; i<len; i++) {
		byte = str[i];
		cap = byte & 32;
		byte &= ~cap;
		byte = ((byte >= 'A') && (byte <= 'Z') ? ((byte - 'A' + 13) % 26 + 'A') : byte) | cap;
		str[i] = byte;
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	for(int n=0; n<kFingersMax; n++)
		fingers[n] = 0;

	// Initialize transport in background thread - looking up hostname might take a while.
	// Also keep reading socket in another threads runloop.
	[NSThread detachNewThreadSelector: @selector(initTransport) toTarget: self withObject: nil];
	//[self performSelector: @selector(initTransport)];

	// Get notification of volumechange.
	volumeEventView = [[[MPVolumeView alloc] initWithFrame:self.view.bounds] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];

	char *appleLoveStr = "cnguZnwbeEnqvhf";
	char str[strlen(appleLoveStr)+1];
	strcpy(str, appleLoveStr);
	rot13(str);
	appleLove1 = [[NSString alloc] initWithFormat: @"%s", str];
}

- (void) volumeChanged: (NSNotification *)notify
{
	[transport send: @"V"];
}

- (void)alertView: (UIAlertView *)actionSheet clickedButtonAtIndex: (NSInteger)buttonIndex
{
//	[[UIApplication sharedApplication] performSelector: @selector(terminate)];
	exit(0);
}

- (void)hostnameNotSet
{
	[[[self view] startupLabel] setText: @"Please set hostname in Settings."];
	[[[self view] animationIndicator] setHidden: YES];
}

- (void)hostNotFound
{
	[self hideStartupAnimation];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Host not found.\nPlease check hostname in Settings.\nDevice must be on same network."
												   delegate:self cancelButtonTitle:@"Quit" otherButtonTitles:nil, nil];
	[alert show];
	[alert release];
}

- (void)initTransport
{
	NSAutoreleasePool *initpool = [[NSAutoreleasePool alloc] init];

	transport = [[Transport alloc] initAndConnect];
	while(!transport.isInitDone) {
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
	}

	if(transport.isInitOK) {
		[self performSelectorOnMainThread: @selector(transportDone) withObject: nil waitUntilDone: NO];

		// This thread will run the receiving socket runloop indefinitely.
		[transport runLoop];
	} else {
		[self performSelectorOnMainThread: @selector(hostNotFound) withObject: nil waitUntilDone: NO];
	}

	[initpool release];
}

- (void)hideStartupAnimation
{
	[[[self view] resolvingView] setHidden: YES];
}

- (void)transportDone
{
	[self hideStartupAnimation];
	[transport send:@"FantaStick init 2.3"];
	// Send our IP over every second until we receive something.
	NSString *sIP = @"IP ";
	NSString *sMsg = [sIP stringByAppendingString: transport.myip];
	[transport send: sMsg];
	ipTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f target: self selector: @selector(transportSendIP)
											 userInfo: nil repeats: YES];
}

- (void)transportSendIP
{
	TouchView *tw = (TouchView*)self.view;
	if(!tw.bHaveSomething) {
		NSString *sIP = @"IP ";
		NSString *sMsg = [sIP stringByAppendingString: transport.myip];
		[transport send: sMsg];
	} else {
		[ipTimer invalidate];
	}
}

// FIX: Optimize speed here. Called often.

- (void)sendTouches:(NSSet*)touches mode: (int) m
{
	int a, b;
	BOOL allEnded = YES;
	for(UITouch *touch in touches) {
		// UITouch* is persistent thru touch, transform pointer to unique number
		UInt32 touchid = (UInt32)touch;

		// If id already touching, get id
		int nID = -1;
		for(int n=0; n<kFingersMax; n++) {
			if(fingers[n] == touchid) {
				nID = n;
				break;
			}
		}

		// Not touching, assign next free finger
		if(nID == -1) {
			for(int n=0; n<kFingersMax; n++) {
				if(fingers[n] == 0) {
					fingers[n] = touchid;
					nID = n;
					break;
				}
			}
		}

		CGPoint loc = [touch locationInView: (UIView*)[self view]];

		[[self view] touchPoint: loc mode: m];

//		if(ti) {
//			[transport send: [NSString stringWithFormat: @"I %ld %ld %@", lrintf(loc.x), lrintf(loc.y), ti.name]];
//		}
		char prefix = 'M';
		if(touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
			prefix = 'E';
			fingers[nID] = 0;
		} else {
			allEnded = NO;
			if(touch.phase == UITouchPhaseBegan)
				prefix = 'B';
			else
			if(touch.phase == UITouchPhaseMoved)
				prefix = 'M';
			else
			if(touch.phase == UITouchPhaseStationary)
				prefix = 'S';
		}

		id fv = [touch valueForKey: appleLove1];
		CGFloat radius = fv ? [fv floatValue] : 0.0f;

		NSString *str = [[NSString alloc] initWithFormat: @"%c %ld %ld %ld %f", prefix,
						 a = touchOffsetX + lrintf(loc.x),
						 b = touchOffsetY + lrintf(loc.y),
						 nID + 1,
						 radius];
		[transport send: str];
		[str release];
		
		if([glview jsActive]) {
			[glview touch: prefix x: a y: b num: nID + 1 radius: radius];
		}
	}

	NSString *str = [[NSString alloc] initWithFormat: @"X %d", [touches count]];
	[transport send: str];
	[str release];
	
	if(allEnded) {
		[transport send: @"X 0"];
		for(int n=0; n<kFingersMax; n++)
			fingers[n] = 0;
	}
}

+ (void) setTouchOffset: (int)x Y: (int)y
{
	touchOffsetX = x;
	touchOffsetY = y;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self sendTouches: [event allTouches] mode: 0];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self sendTouches: [event allTouches] mode: 1];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self sendTouches: [event allTouches] mode: 2];
}

// Accelerometer
- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	UIAccelerationValue x, y, z; 
	x = acceleration.x; 
	y = acceleration.y; 
	z = acceleration.z;

	[transport send: [NSString stringWithFormat: @"A %f %f %f", x, y, z]];
	
	if([glview jsActive]) {
		[glview accelxacc: x yacc: y zacc: z];
	}
	
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[transport release];
	[ipTimer release];
	[appleLove1 release];

    [super dealloc];
}

@end
