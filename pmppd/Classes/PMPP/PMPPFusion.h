//
//  PMPPFusion.h
//  pmppd
//
//  Created by Ali.cpp on 12/11/15.
//
//

#ifndef PMPPFUSION_H
#define PMPPFUSION_H

#import <Foundation/Foundation.h>

@class PMPPHistory;
@class PMPPIdentifier;

@interface PMPPFusion : NSObject
{
    NSArray *itemList;
}

@property (nonatomic) NSArray *items;
@property (nonatomic) NSMutableArray *pending;
@property (nonatomic) PMPPHistory *receivedHistory;
@property (nonatomic) PMPPHistory *sentHistory;
@property (nonatomic) PMPPIdentifier *identifier;
@property (nonatomic) uint16_t messageCount;

- (NSString *)dump;
//-----------------------------------------------------
+ (PMPPFusion *)fusion;
+ (PMPPFusion *)fusionWithItems:(NSArray *)items;

@end

#endif