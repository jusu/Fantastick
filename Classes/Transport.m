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
@synthesize isInitDone;

+ (Transport*) sharedTransport
{
	return sharedTransport;
}

- initAndConnect;
{
	[super init];

	sharedTransport = self;

	isInitDone = isInitOK = NO;

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
	sender = [[UDPEcho alloc] init];
	sender.delegate = self;
	[sender startConnectedToHostName: sHostname port: outport];

	receiver = [[UDPEcho alloc] init];
	receiver.delegate = self;
	[receiver startServerOnPort: inport];
	
	self.myip = [self getIPAddress];

	return self;
}

- (void)runLoop
{
	CFRunLoopRun();
}

- (void) echo:(UDPEcho *)echo didStartWithAddress:(NSData *)address
{
	if(echo == sender) {
		isInitOK = YES;
		isInitDone = YES;
	}
}

- (void) echo:(UDPEcho *)echo didStopWithError:(NSError *)error
{
	if(echo == sender) {
		isInitOK = NO;
		isInitDone = YES;
	}
}

- (void) echo: (UDPEcho *)echo didReceiveData: (NSData *)data fromAddress: (NSData *)addr
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
}

- (void)send: (NSString*)msg
{
	if(isPureDataMessageTermination) {
		msg = [msg stringByAppendingString: @";\n"];
	}

	NSData* d = [msg dataUsingEncoding:NSISOLatin1StringEncoding];

	[sender sendData: d];
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
	[sender release];
	[receiver release];
	[super dealloc];
}

@end
