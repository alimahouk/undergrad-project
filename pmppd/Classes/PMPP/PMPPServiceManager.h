//
//  PMPPServiceManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/13/15.
//
//

#ifndef PMPPSERVICEMANAGER_H
#define PMPPSERVICEMANAGER_H

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;
@class PMPPConnection;
@class PMPPIdentifier;
@class PMPPMessage;
@class PMPPService;

@protocol PMPPServiceManagerDelegate<NSObject>
@optional

- (void)serviceManagerDidRegisterService:(PMPPService *)service;
- (void)serviceManagerFailedToRegisterService:(PMPPService *)service;

@end

@interface PMPPServiceManager : NSObject

@property (nonatomic, weak) id <PMPPServiceManagerDelegate> delegate;
@property (nonatomic) NSMutableSet *services;

- (void)didRegisterService:(PMPPService *)service;
- (PMPPService *)acceptedConnection:(PMPPConnection *)connection;
//-----------------------------------------------------
- (void)send:(PMPPMessage *)message to:(PMPPService *)service;
//-----------------------------------------------------
- (PMPPService *)serviceForIdentifier:(PMPPIdentifier *)identifier;
- (PMPPService *)serviceForSocket:(GCDAsyncSocket *)socket;
//-----------------------------------------------------
+ (BOOL)socketIsService:(GCDAsyncSocket *)socket;

@end

#endif