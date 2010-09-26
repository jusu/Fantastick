//
//  Transport.m
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#include <ifaddrs.h>
#include <arpa/inet.h>

#import "Transport.h"
#import <CoreFoundation/CoreFoundation.h>
#import "UIKit/UIApplication.h"

BOOL isReceivingFromPureData = NO;
static id tw_w = NULL;
static Transport* sharedTransport = NULL;

@implementation Transport

@synthesize myip;
@synthesize isInitOK;

+ (Transport*) sharedTransport
{
	return sharedTransport;
}

- initAndConnect;
{
	[super init];

	sharedTransport = self;

	isInitOK = NO;

	// Settings
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *sHostname = [defaults stringForKey: @"hostname"];
	NSString *sOutport = [defaults stringForKey: @"outport"];
	NSString *sInport = [defaults stringForKey: @"inport"];

	int outport = 6661, inport = 6662;
	if(sOutport) {
		outport = [sOutport intValue];
	}
	if(sInport) {
		inport = [sInport intValue];
	}

	isPureDataMessageTermination = [defaults boolForKey: @"puredata"];
	isReceivingFromPureData = isPureDataMessageTermination;
	
	// init
	sendsocket = [[AsyncUdpSocket alloc] init];
	recvsocket = [[AsyncUdpSocket alloc] initIPv4];
	[recvsocket setDelegate: self];

	if(![recvsocket bindToPort: inport error: nil]) {
		// FIXME: report binding error
		return self;
	}

	if(![sendsocket connectToHost: sHostname onPort: outport error: nil]) {
		return self;
	}

	[recvsocket receiveWithTimeout: -1 tag: 0];

	self.myip = [self getIPAddress];

	isInitOK = YES;
	return self;
}

- (void)runLoop
{
	CFRunLoopRun();
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	if(!tw_w) {
		tw_w = [[[UIApplication sharedApplication] keyWindow] viewWithTag: 666];
	}
	
	// Remove puredata termination
	if(isReceivingFromPureData) {
		int len = [data length];
		if(len > 2) {
			NSData *d = [data subdataWithRange: NSMakeRange(0, len-2)];
			[tw_w handleMessage: d];
		}
	} else {
		[tw_w handleMessage: data];
	}

	[recvsocket receiveWithTimeout: -1 tag: 0];
	return YES;
}

- (void)send: (NSString*)msg
{
	if(isPureDataMessageTermination) {
		msg = [msg stringByAppendingString: @";\n"];
	}

	NSData* d = [msg dataUsingEncoding:NSISOLatin1StringEncoding];

	[sendsocket sendData: d withTimeout: -1 tag: 0];
}

- (NSString *)getIPAddress
{
	NSString *address = @"127.0.0.1";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	return address;
}

- (void) dealloc
{
	[sendsocket release];
	[recvsocket release];
	[super dealloc];
}

@end
