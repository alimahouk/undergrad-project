//
//  PMPPHistory.h
//  pmppd
//
//  Created by Ali.cpp on 12/29/15.
//
//

#ifndef PMPPHISTORY_H
#define PMPPHISTORY_H

#import <Foundation/Foundation.h>

@class PMPPIdentifier;

@interface PMPPHistory : NSObject

@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *value;

- (NSString *)progressTo:(NSDate *)time;
//-----------------------------------------------------
+ (PMPPHistory *)freshHistory:(PMPPIdentifier *)identifier;
+ (PMPPHistory *)history;

@end

#endif