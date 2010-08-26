//
//  Transport.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncUdpSocket.h"

@interface Transport : NSObject {
	AsyncUdpSocket *sendsocket;
	AsyncUdpSocket *recvsocket;

	NSString *myip;
	BOOL isInitOK;
	BOOL isPureDataMessageTermination;
}

@property (retain) NSString* myip;
@property BOOL isInitOK;

+ (Transport*) sharedTransport;

// init and connect to host defined in settings bundle, prepare to receive
- initAndConnect;
- (void)runLoop;
- (NSString *)getIPAddress;

- (void)send: (NSString*)msg;
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port;

@end
