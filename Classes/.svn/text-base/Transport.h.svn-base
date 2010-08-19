//
//  Transport.h
//  FantaStick
//
//  Created by Juha Vehviläinen on 1/6/09.
//  Copyright 2009 Pink Twins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sys/socket.h"
#import "netinet/in.h"
#import "arpa/inet.h"

@interface Transport : NSObject {
	int					sender_sockfd;
	struct sockaddr_in	sender_addr;
	
	CFSocketRef			recvSocket;
	CFRunLoopSourceRef	recvRunLoop;
	struct sockaddr_in	recv_addr;
	
	NSString *myip;
	BOOL isInitOK;
	BOOL isPureDataMessageTermination;
}

@property (retain) NSString* myip;
@property BOOL isInitOK;

// init and connect to host defined in settings bundle, prepare to receive
- initAndConnect;
- (void)runLoop;

- (void)send: (NSString*)msg;

@end
