//
//  PMPPMessage.h
//  pmppd
//
//  Created by Ali.cpp on 12/9/15.
//
//

#ifndef PMPPMESSAGE_H
#define PMPPMESSAGE_H

#import <Foundation/Foundation.h>

#import "Constants.h"

@class PMPPHistory;
@class PMPPIdentifier;
@class PMPPServer;
@class PMPPService;

@interface PMPPMessage : NSObject

@property (nonatomic) BOOL encrypted;
@property (nonatomic) float version;
@property (nonatomic) id contents;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *ackIdentifier;
@property (nonatomic) NSString *session;
@property (nonatomic) PMPPEvent type;
@property (nonatomic) PMPPHistory *receivedHistory;
@property (nonatomic) PMPPHistory *sentHistory;
@property (nonatomic) PMPPIdentifier *identifier;
@property (nonatomic) PMPPServer *recipientServer;
@property (nonatomic) PMPPServer *sendingServer;
@property (nonatomic) PMPPService *recipientService;
@property (nonatomic) PMPPService *sendingService;
@property (nonatomic) TransportType transport;

- (NSDictionary *)asDictionary;
- (NSDictionary *)contentsAsDictionary;
//-----------------------------------------------------
+ (PMPPMessage *)messageOfType:(PMPPEvent)type;
+ (PMPPMessage *)messageWithDictionary:(NSDictionary *)dict;
+ (PMPPMessage *)messageWithMessage:(PMPPMessage *)message;

@end

#endif