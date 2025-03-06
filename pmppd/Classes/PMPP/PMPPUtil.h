//
//  PMPPUtil.h
//  pmppd
//
//  Created by Ali.cpp on 12/8/15.
//
//


#ifndef PMPPUTIL_H
#define PMPPUTIL_H

#import <Foundation/Foundation.h>

@interface PMPPUtil : NSObject

+ (NSString *)MD5:(NSString *)str;
+ (NSString *)SHA1:(NSString *)str;
//-----------------------------------------------------
+ (NSString *)uniqueIdentifier;
//-----------------------------------------------------
+ (NSString *)addString:(NSString *)str1 to:(NSString *)str2;
+ (NSString *)addStrings:(NSArray *)strings;
//-----------------------------------------------------
+ (BOOL)isValidIPAddress:(NSString *)address;
//-----------------------------------------------------
+ (NSString *)dateAsString:(NSDate *)date;
+ (NSDate *)stringAsDate:(NSString *)str;
+ (NSString *)timeNowString;
//-----------------------------------------------------
+ (BOOL)append:(NSString *)text toFile:(NSString *)path;
+ (BOOL)clearFile:(NSString *)path;
+ (BOOL)createFile:(NSString *)path;
+ (NSString *)getInput:(NSString *)filename;

@end

#endif