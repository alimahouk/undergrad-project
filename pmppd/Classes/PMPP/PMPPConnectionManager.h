//
//  PMPPConnectionManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPCONNECTIONMANAGER_H
#define PMPPCONNECTIONMANAGER_H

#import <Foundation/Foundation.h>

#import "Constants.h"
#import "GCDAsyncUdpSocket.h"

@class GCDAsyncSocket;
@class PMPPConnection;
@class PMPPIdentifier;
@class PMPPMessage;
@class PMPPServer;

@protocol PMPPConnectionManagerDelegate<NSObject>
@optional

- (void)connectionManagerDidObtainPublicTCPAddress:(PMPPConnection *)TCPAddress
                                        UDPAddress:(PMPPConnection *)UDPAddress
                                               for:(PMPPIdentifier *)identifier;

@end

@interface PMPPConnectionManager : NSObject <GCDAsyncUdpSocketDelegate>
{
    BOOL isListening;
    dispatch_queue_t networkThread;
    GCDAsyncSocket *LANSocketTCP;
    GCDAsyncSocket *serverSocketTCP;
    GCDAsyncSocket *serviceSocket;
    GCDAsyncUdpSocket *LANSocketUDP;
    GCDAsyncUdpSocket *serverSocketUDP;
    NSMutableArray *portMappers;
    NSMutableSet *MQ;
}

@property (nonatomic, weak) id <PMPPConnectionManagerDelegate> delegate;
@property (nonatomic) NSString *subnetMask;
@property (nonatomic) PMPPIdentifier *sharedServerIdentifier;
@property (nonatomic) PMPPConnectionInterface networkState;
@property (nonatomic) PMPPConnectionInterface previousNetworkState;

- (void)received:(PMPPMessage *)message from:(PMPPConnection *)connection;
- (void)sendServerMessage:(PMPPMessage *)message;
- (void)sendServiceMessage:(PMPPMessage *)message;
- (void)startListening;
- (void)stopListening;
- (void)updateSharedTCPAddress:(PMPPConnection *)TCPInfo
                    UDPAddress:(PMPPConnection *)UDPInfo
                          with:(PMPPServer *)server;
//-----------------------------------------------------
- (GCDAsyncSocket *)freshTCPSocket;
- (NSString *)privateIPAddress;
- (PMPPIdentifier *)identifierForPort:(uint16_t)port;
//-----------------------------------------------------
- (void)requestPortForServer:(PMPPServer *)server;

@end

#endif