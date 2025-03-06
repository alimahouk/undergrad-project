//
//  PMPPIdentifier.h
//  pmppd
//
//  Created by Ali.cpp on 2/2/16.
//
//

#ifndef PMPPIDENTIFIER_H
#define PMPPIDENTIFIER_H

#import <Foundation/Foundation.h>

#import "constants.h"

@interface PMPPIdentifier : NSObject

@property (nonatomic) NSString *string;
@property (nonatomic) PMPPEntityType entityType;

+ (PMPPIdentifier *)identifier:(NSString *)identifier forEntityType:(PMPPEntityType)type;
+ (PMPPIdentifier *)identifierForEntityType:(PMPPEntityType)type;

@end

#endif