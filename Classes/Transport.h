//
//  Transport.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDPEcho.h"

@interface Transport : NSObject <UDPEchoDelegate> {
	UDPEcho *sender;
	UDPEcho *receiver;

	NSString *myip;
	BOOL isInitOK;
	BOOL isInitDone;
	BOOL isPureDataMessageTermination;
}

@property (retain) NSString* myip;
@property BOOL isInitOK, isInitDone;

+ (Transport*) sharedTransport;

// init and connect to host defined in settings bundle, prepare to receive
- initAndConnect;
- (void) runLoop;
- (NSString *) getIPAddress;

- (void) send: (NSString*)msg;
- (void) echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr;
- (void) echo:(UDPEcho *)echo didStartWithAddress:(NSData *)address;
- (void) echo:(UDPEcho *)echo didStopWithError:(NSError *)error;

@end
