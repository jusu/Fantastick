//
//  Transport.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncUdpSocket.h"
#import "UDPEcho.h"

@interface Transport : NSObject <UDPEchoDelegate> {
	AsyncUdpSocket *sendsocket;
	UDPEcho *receiver;

	NSString *myip;
	BOOL isInitOK;
	BOOL isPureDataMessageTermination;
}

@property (retain) NSString* myip;
@property BOOL isInitOK;

+ (Transport*) sharedTransport;

// init and connect to host defined in settings bundle, prepare to receive
- initAndConnect;
- (void) runLoop;
- (NSString *) getIPAddress;

- (void) send: (NSString*)msg;
- (void) echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr;

@end
