//
//  PMPPUtil.m
//  pmppd
//
//  Created by Ali.cpp on 12/8/15.
//
//

#import "PMPPUtil.h"

#import <arpa/inet.h>
#import <CommonCrypto/CommonDigest.h>
#import "constants.h"

@implementation PMPPUtil

+ (NSString *)MD5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (int)strlen(cStr), result);
    NSString *s = [NSString  stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15]];
    return s;
}

+ (NSString *)SHA1:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (int)strlen(cStr), result);
    NSString *s = [NSString  stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15],
                   result[16], result[17], result[18], result[19]];
    return s;
}

#pragma mark -

+ (NSString *)uniqueIdentifier
{
    char concatenator = arc4random_uniform(ASCII_RANGE);
    int rand = arc4random_uniform(2);
    NSString *identifier;
    
    if ( rand == 0 )
    {
        identifier = [NSString stringWithFormat:@"%@%c%f", [self timeNowString], concatenator, [[NSProcessInfo processInfo] systemUptime]];
    }
    else
    {
        identifier = [NSString stringWithFormat:@"%f%c%@", [[NSProcessInfo processInfo] systemUptime], concatenator, [self timeNowString]];
    }
    
    return [self SHA1:identifier];
}

#pragma mark -

+ (NSString *)addString:(NSString *)str1 to:(NSString *)str2
{
    /*
     *  This is NOT a concat method!
     */
    NSString *temp = @"";
    
    if ( str1 && str2 && str1.length == str2.length )
    {
        for ( int i = 0; i < str1.length; i++ )
        {
            unichar currentChar_1 = [str1 characterAtIndex:i];
            unichar currentChar_2 = [str2 characterAtIndex:i];
            unichar final = currentChar_1 + currentChar_2;
            temp = [temp stringByAppendingFormat:@"%c", final];
        }
    }
    
    return temp;
}

+ (NSString *)addStrings:(NSArray *)strings
{
    NSString *temp = @"";
    
    if ( strings.count > 0 )
    {
        temp = strings[0];
        
        if ( strings.count > 1 )
        {
            for ( int i = 1; i < strings.count; i++ )
            {
                temp = [self addString:temp to:strings[i]];
            }
        }
    }
    
    return temp;
}

#pragma mark -

+ (BOOL)isValidIPAddress:(NSString *)address
{
    const char *utf8 = [address UTF8String];
    int success;
    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst); // Check if IPv4.
    
    if ( success != 1 ) // Check if IPv6.
    {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    
    return success == 1;
}

#pragma mark -
#pragma mark Time

+ (NSString *)dateAsString:(NSDate *)date
{
    if ( date )
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        return [dateFormatter stringFromDate:date];
    }
    
    return nil;
}

+ (NSDate *)stringAsDate:(NSString *)str
{
    if ( str )
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        return [dateFormatter dateFromString:str];
    }
    
    return nil;
}

+ (NSString *)timeNowString
{
    // This returns a SQLite-friendly timestamp.
    NSDate *today = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    return [dateFormatter stringFromDate:today];
}

#pragma mark -

+ (BOOL)append:(NSString *)text toFile:(NSString *)path
{
    BOOL result = YES;
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    
    if ( !fh )
    {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    
    if ( !fh )
    {
        return NO;
    }
    
    @try
    {
        [fh seekToEndOfFile];
        [fh writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch (NSException * e)
    {
        result = NO;
    }
    
    [fh closeFile];
    
    return result;
}

+ (BOOL)clearFile:(NSString *)path
{
    BOOL result = YES;
    NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:path];
    
    if ( !fh )
    {
        return NO;
    }
    
    @try
    {
        [fh truncateFileAtOffset:0];
    }
    @catch (NSException * e)
    {
        result = NO;
    }
    
    [fh closeFile];
    
    return result;
}

+ (BOOL)createFile:(NSString *)path
{
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    
    if ( !fh )
    {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForReadingAtPath:path];
    }
    
    if ( !fh )
    {
        return NO;
    }
    
    return YES;
}

+ (NSString *)getInput:(NSString *)filename
{
    if ( filename ) // Get contents of file.
    {
        NSError *error;
        NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
        
        if ( error && error.code != 260 )
        {
            NSLog(@"FILE READ ERROR: %@", error);
            
            if ( error.code == 261 )
            {
                contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF32StringEncoding error:&error];
            }
            else
            {
                return nil;
            }
        }
        
        return contents;
    }
    
    return nil;
}

@end
