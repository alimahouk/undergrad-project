//
//  PMPPModelManager.h
//  pmppd
//
//  Created by Ali.cpp on 12/10/15.
//
//

#ifndef PMPPMODELMANAGER_H
#define PMPPMODELMANAGER_H

#import <Foundation/Foundation.h>

@interface PMPPModelManager : NSObject

+ (void)dump:(id)entity;
+ (void)dumpServerList:(NSArray *)list;
+ (void)remove:(id)entity;
//-----------------------------------------------------
+ (id)entityForContext:(NSString *)context;
+ (NSMutableArray *)masterServerList;

@end

#endif