//
//  PMPPService.h
//  pmppd
//
//  Created by Ali.cpp on 12/11/15.
//
//

#ifndef PMPPSERVICE_H
#define PMPPSERVICE_H

#import <Foundation/Foundation.h>

@class PMPPConnection;
@class PMPPIdentifier;

@interface PMPPService : NSObject

@property (nonatomic) PMPPConnection *connection;
@property (nonatomic) PMPPIdentifier *identifier;

- (NSString *)dump;
//-----------------------------------------------------
+ (PMPPService *)service;

@end

#endif