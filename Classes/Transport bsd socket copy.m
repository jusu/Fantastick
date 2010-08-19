//
//  Transport.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import "Transport.h"
#import <CoreFoundation/CoreFoundation.h>
#import "UIKit/UIApplication.h"

BOOL isReceivingFromPureData = NO;

static id tw_w = NULL;
void UdpCallBack(CFSocketRef s,
				 CFSocketCallBackType callbackType,
				 CFDataRef address,
				 const void *data,
				 void *info)
{
	if(!tw_w) {
		tw_w = [[[UIApplication sharedApplication] keyWindow] viewWithTag: 666];
	}

	// Remove puredata termination
	if(isReceivingFromPureData) {
		NSData *d = (NSData*)data;
		char *s = (char*)[d bytes];
		int len = strlen(s);
		if(len > 2) {
			s[len-2] = 0;
			s[len-1] = 0;
		}
	}

	[tw_w handleMessage: data];
}

@implementation Transport

@synthesize myip;
@synthesize isInitOK;

- initAndConnect;
{
	[super init];

	isInitOK = NO;

	// Settings
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *sHostname = [defaults stringForKey: @"hostname"];
	NSString *sOutport = [defaults stringForKey: @"outport"];
	NSString *sInport = [defaults stringForKey: @"inport"];
	isPureDataMessageTermination = [defaults boolForKey: @"puredata"];
	isReceivingFromPureData = isPureDataMessageTermination;
	
	// SENDER
	NSHost* host = [NSHost hostWithName: sHostname];
	if(!host) { // Host not found?
		return self;
	}

	// Find my ip
	NSEnumerator *ip_e = [[host addresses] objectEnumerator];
	NSString *ip = 0;
	while((ip = [ip_e nextObject])) {
		NSArray *i = [ip componentsSeparatedByString: @"."];
		if([i count] == 4) {
			break;
		}
	}
	
	// Create a socket
	sender_sockfd = socket( AF_INET, SOCK_DGRAM, 0 );

	// Address it
	sender_addr.sin_family = AF_INET;
	sender_addr.sin_addr.s_addr = inet_addr([ip UTF8String]);
	sender_addr.sin_port = htons([sOutport intValue]);
	
	// RECEIVER
	recvSocket = CFSocketCreate(NULL, 0, SOCK_DGRAM, 0, kCFSocketDataCallBack, UdpCallBack, NULL);
//	CFSocketSetSocketFlags(recvSocket, kCFSocketCloseOnInvalidate);

	recv_addr.sin_family = AF_INET;
	recv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	recv_addr.sin_port = htons([sInport intValue]);

	CFDataRef data = CFDataCreate(NULL, (unsigned char *)&recv_addr, sizeof(recv_addr));
	CFSocketSetAddress(recvSocket, data);
	CFRelease(data);

	recvRunLoop = CFSocketCreateRunLoopSource(NULL, recvSocket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), recvRunLoop, kCFRunLoopDefaultMode);

	// Set my ip
	NSHost* me = [NSHost currentHost];
	NSEnumerator *e = [[me addresses] objectEnumerator];
	NSString *s = 0;
	while((s = [e nextObject])) {
		NSArray *i = [s componentsSeparatedByString: @"."];
		if([i count] == 4 && [i objectAtIndex: 0] != @"127") {
			self.myip = s;
			break;
		}
	}

	isInitOK = YES;
	return self;
}

- (void)runLoop
{
	CFRunLoopRun();
}

- (void)send: (NSString*)msg
{
	if(isPureDataMessageTermination) {
		msg = [msg stringByAppendingString: @";\n"];
	}

	NSData* d = [msg dataUsingEncoding:NSISOLatin1StringEncoding];
	sendto(sender_sockfd, [d bytes], [d length], 0, (struct sockaddr*)&sender_addr, sizeof(sender_addr));
}

- (void) dealloc
{
	CFRelease(recvSocket);
	CFRelease(recvRunLoop);
	[super dealloc];
}

@end
