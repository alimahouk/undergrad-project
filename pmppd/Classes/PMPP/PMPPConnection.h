//
//  PMPPConnection.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPCONNECTION_H
#define PMPPCONNECTION_H

#import <Foundation/Foundation.h>

#import "Constants.h"

@class GCDAsyncSocket;

@interface PMPPConnection : NSObject

@property (nonatomic) BOOL keepAlive;
@property (nonatomic) int connectionAttempts;
@property (nonatomic) GCDAsyncSocket *socket;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *privateAddress;
@property (nonatomic) NSString *publicAddress;
@property (nonatomic) PMPPConnectionInterface interface;
@property (nonatomic) TransportType type;
@property (nonatomic) uint16_t privatePort;
@property (nonatomic) uint16_t publicPort;

- (void)connected;
//-----------------------------------------------------
+ (PMPPConnection *)connection;

@end

#endif