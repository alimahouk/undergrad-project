//
//  PMPPServerManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPSERVERMANAGER_H
#define PMPPSERVERMANAGER_H

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@class PMPPConnection;
@class PMPPIdentifier;
@class PMPPServer;

@protocol PMPPServerManagerDelegate<NSObject>
@optional

- (void)serverManagerDidConnectWithServer:(PMPPServer *)server;
- (void)serverManagerDidDisconnectFromServer:(PMPPServer *)server;
- (void)serverManagerDidLoadStoredServers:(NSArray *)servers;

@end

@interface PMPPServerManager : NSObject
{
    NSTimer *peerConnectionTimer;
}

@property (nonatomic, weak) id <PMPPServerManagerDelegate> delegate;
@property (nonatomic) NSMutableSet *peers;

- (void)loadServers;
- (NSArray *)meetingPoints;
- (void)resetPendingPeers;
- (void)startPeerTimer;
- (void)stopPeerTimer;
//-----------------------------------------------------
- (void)addServer:(PMPPServer *)server;
- (void)connect:(PMPPServer *)server;
- (void)disconnect;
- (void)disconnect:(PMPPServer *)server;
- (void)exchangeMeetingPointsWith:(PMPPServer *)server response:(BOOL)isResponse;
- (void)ping:(PMPPServer *)server;
- (void)reconnect;
- (void)removeServer:(PMPPServer *)server;
- (void)requestPublicAddressFrom:(PMPPServer *)server;
- (void)updateInfoForServer:(PMPPServer *)server with:(PMPPServer *)update;
//-----------------------------------------------------
- (PMPPServer *)acceptedConnection:(PMPPConnection *)connection;
- (PMPPServer *)connectedTo:(PMPPConnection *)connection;
//-----------------------------------------------------
- (void)didConnectWithServer:(PMPPServer *)server;
- (void)didDisconnectFromServer:(PMPPServer *)server;
- (void)didShakeHandsWithServer:(PMPPServer *)server;
//-----------------------------------------------------
- (PMPPServer *)serverForTCPConnection:(PMPPConnection *)TCPConnection
                         UDPConnection:(PMPPConnection *)UDPConnection;
- (PMPPServer *)serverForIdentifier:(PMPPIdentifier *)identifier;
- (PMPPServer *)serverForSocket:(GCDAsyncSocket *)socket;
//-----------------------------------------------------
+ (NSArray *)meetingPointsForServer:(PMPPServer *)server;

@end

#endif