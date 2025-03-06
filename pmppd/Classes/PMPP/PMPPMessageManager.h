//
//  PMPPMessageManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPMESSAGEMANAGER_H
#define PMPPMESSAGEMANAGER_H

#import <Foundation/Foundation.h>

#import "Constants.h"

@class PMPPConnection;
@class PMPPMessage;
@class PMPPServer;

@protocol PMPPMessageManagerDelegate<NSObject>
@optional

- (void)messageManagerDidDeliverMessage:(PMPPMessage *)message;
- (void)messageManagerDidReceiveMessage:(PMPPMessage *)message;
- (void)messageManagerDidSendMessage:(PMPPMessage *)message;

@end

@interface PMPPMessageManager : NSObject
{
    NSMutableSet *MQ;
}

@property (nonatomic, weak) id <PMPPMessageManagerDelegate> delegate;

- (void)flush:(PMPPServer *)server;
//-----------------------------------------------------
- (void)acknowledgeDelivery:(PMPPMessage *)message;
- (void)sendServerMessage:(PMPPMessage *)message;
- (void)sendServiceMessage:(PMPPMessage *)message;
//-----------------------------------------------------
- (void)didDeliverServerMessage:(PMPPMessage *)message;
- (void)didDeliverServiceMessage:(PMPPMessage *)message;
- (void)didReceiveServerMessage:(PMPPMessage *)message from:(PMPPConnection *)connection;
- (void)didReceiveServiceMessage:(PMPPMessage *)message;
- (void)didSendServerMessage:(PMPPMessage *)message;
- (void)didSendServiceMessage:(PMPPMessage *)message;

@end

#endif