//
//  PMPPServer.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//


#ifndef PMPPSERVER_H
#define PMPPSERVER_H

#import <Foundation/Foundation.h>

#import "constants.h"

@class PMPPConnection;
@class PMPPIdentifier;

@interface PMPPServer : NSObject
{
    NSTimer *TCPIdleTimer;
}

@property (nonatomic) BOOL didConnect;
@property (nonatomic) BOOL identified;
@property (nonatomic) BOOL isBeingProbed;
@property (nonatomic) BOOL isContact;
@property (nonatomic) int pings;
@property (nonatomic) NSMutableArray *contexts;
@property (nonatomic) NSMutableSet *backwardMeetingPoints;
@property (nonatomic) NSMutableSet *forwardMeetingPoints;
@property (nonatomic) NSMutableSet *watchers;
@property (nonatomic) PMPPConnection *TCPConnection;
@property (nonatomic) PMPPConnection *UDPConnection;
@property (nonatomic) PMPPIdentifier *identifier;
@property (nonatomic) PMPPPresenceType presence;

- (NSString *)dump;
//-----------------------------------------------------
- (void)killSocket;
- (void)resetTCPIdleTimer;
//-----------------------------------------------------
+ (PMPPServer *)server;
+ (PMPPServer *)serverWithDictionary:(NSDictionary *)dict;
+ (PMPPServer *)serverWithIdentifier:(PMPPIdentifier *)identifier;
+ (PMPPServer *)serverWithServer:(PMPPServer *)server;

@end

#endif