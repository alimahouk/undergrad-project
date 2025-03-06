//
//  PMPPModelManager.m
//  pmppd
//
//  Created by Ali.cpp on 12/10/15.
//
//

#import "PMPPModelManager.h"

#import "AppDelegate.h"
#import "PMPPConnection.h"
#import "PMPPFusion.h"
#import "PMPPHistory.h"
#import "PMPPIdentifier.h"
#import "PMPPMessage.h"
#import "PMPPServer.h"
#import "PMPPService.h"
#import "PMPPUtil.h"

@implementation PMPPModelManager

+ (void)dump:(id)entity
{
    if ( entity )
    {
        if ( [entity isKindOfClass:[PMPPFusion class]] )
        {
            [PMPPModelManager dumpFusion:entity];
        }
        else if ( [entity isKindOfClass:[PMPPServer class]] )
        {
            [PMPPModelManager dumpServer:entity];
        }
        else if ( [entity isKindOfClass:[PMPPService class]] )
        {
            [PMPPModelManager dumpService:entity];
        }
    }
}

+ (void)dumpFusion:(PMPPFusion *)fusion
{
    if ( fusion )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, fusion.identifier];
        
        if ( ![PMPPUtil createFile:filepath] )
        {
            NSLog(@"Failed to create file for fusion: %@", fusion.identifier);
        }
        
        [PMPPUtil clearFile:filepath];
        [PMPPUtil append:[fusion dump] toFile:filepath];
    }
}

+ (void)dumpServerList:(NSArray *)list
{
    /*
     *  This method works with lists of either PMPPServer objects
     *  or identifier strings.
     */
    if ( list && list.count > 0 )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        BOOL isServerObject = NO;
        id sample = list[0];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, MASTER_LIST_SERVERS];
        
        if ( [sample isKindOfClass:[PMPPServer class]] )
        {
            isServerObject = YES;
        }
        
        [PMPPUtil clearFile:filepath];
        
        if ( isServerObject)
        {
            for ( PMPPServer *server in list )
            {
                [PMPPUtil append:server.identifier.string toFile:filepath];
            }
        }
        else
        {
            for ( NSString *identifier in list )
            {
                [PMPPUtil append:identifier toFile:filepath];
            }
        }
    }
}

+ (void)dumpServer:(PMPPServer *)server
{
    if ( server )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, server.identifier];
        
        if ( ![PMPPUtil createFile:filepath] )
        {
            NSLog(@"Failed to create file for server: %@", server.identifier);
        }
        
        [PMPPUtil clearFile:filepath];
        [PMPPUtil append:[server dump] toFile:filepath];
    }
}

+ (void)dumpService:(PMPPService *)service
{
    if ( service )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, service.identifier];
        
        if ( ![PMPPUtil createFile:filepath] )
        {
            NSLog(@"Failed to create file for service: %@", service.identifier);
        }
        
        [PMPPUtil clearFile:filepath];
        [PMPPUtil append:[service dump] toFile:filepath];
    }
}

+ (void)remove:(id)entity
{
    if ( entity )
    {
        if ( [entity isKindOfClass:[PMPPFusion class]] )
        {
            [PMPPModelManager removeFusion:entity];
        }
        else if ( [entity isKindOfClass:[PMPPServer class]] )
        {
            [PMPPModelManager removeServer:entity];
        }
    }
}

+ (void)removeFusion:(PMPPFusion *)fusion
{
    if ( fusion )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, fusion.identifier];
        
        if ( ![fileManager removeItemAtPath:filepath error:&error] )
        {
            NSLog(@"Could not delete server at path %@, error: %@", filepath, error);
        }
    }
}

+ (void)removeServer:(PMPPServer *)server
{
    if ( server )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, server.identifier];
        
        // Delete any fusions involving this server.
        for ( NSString *context in server.contexts )
        {
            PMPPFusion *fusion = [self entityForContext:context];
            
            if ( fusion )
            {
                [self remove:fusion];
            }
        }
        
        if ( ![fileManager removeItemAtPath:filepath error:&error] )
        {
            NSLog(@"Could not delete server at path %@, error: %@", filepath, error);
        }
    }
}

#pragma mark -

+ (id)entityForContext:(NSString *)context
{
    if ( context )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, context];
        NSString *contents = [PMPPUtil getInput:filepath];
        
        if ( contents )
        {
            NSArray *fileLines = [contents componentsSeparatedByString:@"\f"];
            
            for ( int i = 0; i < fileLines.count; i++ )
            {
                NSString *line = fileLines[i];
                NSArray *lineComponents = [line componentsSeparatedByString:@"\t"];
                
                if ( lineComponents.count > 1 )
                {
                    NSString *prefix = lineComponents[0];
                    NSString *value = lineComponents[1];
                    
                    if ( [prefix isEqualToString:PMPP_DATA_ENTITY] )
                    {
                        if ( value.intValue == PMPPEntityServer )
                        {
                            return [PMPPModelManager serverFromFile:contents];
                        }
                        else if ( value.intValue == PMPPEntityService )
                        {
                            return [PMPPModelManager serviceFromFile:contents];
                        }
                        else if ( value.intValue == PMPPEntityFusion )
                        {
                            return [PMPPModelManager fusionFromFile:contents];
                        }
                    }
                }
            }
        }
    }
    
    return nil;
}

+ (PMPPFusion *)fusionFromFile:(NSString *)contents
{
    if ( contents )
    {
        PMPPFusion *fusion = [PMPPFusion fusion];
        NSArray *fileLines = [contents componentsSeparatedByString:@"\f"];
        NSMutableArray *fusionItems = [NSMutableArray array];
        
        for ( int i = 0; i < fileLines.count; i++ )
        {
            NSString *line = fileLines[i];
            NSArray *lineComponents = [line componentsSeparatedByString:@"\t"];
            
            if ( lineComponents.count > 1 )
            {
                NSString *prefix = lineComponents[0];
                NSString *value = lineComponents[1];
                
                if ( [prefix isEqualToString:PMPP_DATA_CONTEXT] )
                {
                    fusion.identifier.string = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_CONTEXT_ITEM] )
                {
                    [fusionItems addObject:value];
                }
                else if ( [prefix isEqualToString:PMPP_DATA_MESSAGE_COUNT] )
                {
                    fusion.messageCount = value.intValue;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_PENDING_ITEM] )
                {
                    NSDictionary *pending = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding]
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:nil];
                    PMPPMessage *message = [PMPPMessage messageWithDictionary:pending];
                    
                    [fusion.pending addObject:message];
                }
                else if ( [prefix isEqualToString:PMPP_DATA_RECEIVED_HISTORY] )
                {
                    fusion.receivedHistory.value = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_RECEIVED_HISTORY_TIME] )
                {
                    fusion.receivedHistory.timestamp = [PMPPUtil stringAsDate:value];;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_SENT_HISTORY] )
                {
                    fusion.sentHistory.value = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_SENT_HISTORY_TIME] )
                {
                    fusion.sentHistory.timestamp = [PMPPUtil stringAsDate:value];;
                }
            }
        }
        
        fusion.items = fusionItems;
        
        return fusion;
    }
    
    return nil;
}

+ (NSMutableArray *)masterServerList
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSMutableArray *list = [NSMutableArray array];
    NSString *filepath = [NSString stringWithFormat:@"%@/%@", appDelegate.dataDirectory, MASTER_LIST_SERVERS];
    NSString *contents = [PMPPUtil getInput:filepath];
    
    if ( contents )
    {
        NSArray *fileLines = [contents componentsSeparatedByString:@"\f"];
        
        for ( int i = 0; i < fileLines.count; i++ )
        {
            [list addObject:fileLines[i]];
        }
    }
    
    return list;
}

+ (PMPPServer *)serverFromFile:(NSString *)contents
{
    if ( contents )
    {
        PMPPServer *server = [PMPPServer server];
        NSArray *fileLines = [contents componentsSeparatedByString:@"\f"];
        
        for ( int i = 0; i < fileLines.count; i++ )
        {
            NSString *line = fileLines[i];
            NSArray *lineComponents = [line componentsSeparatedByString:@"\t"];
            
            if ( lineComponents.count > 1 )
            {
                NSString *prefix = lineComponents[0];
                NSString *value = lineComponents[1];
                
                if ( [prefix isEqualToString:PMPP_DATA_CONTEXT] )
                {
                    server.identifier.string = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_CONTEXT_ITEM] )
                {
                    [server.contexts addObject:value];
                }
                else if ( [prefix isEqualToString:PMPP_DATA_ADDRESS_PRIVATE] )
                {
                    server.TCPConnection.privateAddress = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_ADDRESS_PUBLIC] )
                {
                    server.TCPConnection.publicAddress = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_LAST_CONNECTION] )
                {
                    if ( ![value isEqualToString:@" "])
                    {
                        server.TCPConnection.timestamp = [PMPPUtil stringAsDate:value];
                    }
                }
                else if ( [prefix isEqualToString:PMPP_DATA_BACKWARD_MEETING_POINT] )
                {
                    [server.backwardMeetingPoints addObject:value];
                }
                else if ( [prefix isEqualToString:PMPP_DATA_FORWARD_MEETING_POINT] )
                {
                    [server.forwardMeetingPoints addObject:value];
                }
                else if ( [prefix isEqualToString:PMPP_DATA_PORT_PRIVATE] )
                {
                    server.TCPConnection.privatePort = value.intValue;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_PORT_PUBLIC_TCP] )
                {
                    server.TCPConnection.publicPort = value.intValue;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_PORT_PUBLIC_UDP] )
                {
                    server.UDPConnection.publicPort = value.intValue;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_WATCHER] )
                {
                    [server.watchers addObject:value];
                }
            }
        }
        
        return server;
    }
    
    return nil;
}

+ (PMPPService *)serviceFromFile:(NSString *)contents
{
    if ( contents )
    {
        PMPPService *service = [PMPPService service];
        NSArray *fileLines = [contents componentsSeparatedByString:@"\f"];
        
        for ( int i = 0; i < fileLines.count; i++ )
        {
            NSString *line = fileLines[i];
            NSArray *lineComponents = [line componentsSeparatedByString:@"\t"];
            
            if ( lineComponents.count > 1 )
            {
                NSString *prefix = lineComponents[0];
                NSString *value = lineComponents[1];
                
                if ( [prefix isEqualToString:PMPP_DATA_CONTEXT] )
                {
                    service.identifier.string = value;
                }
                else if ( [prefix isEqualToString:PMPP_DATA_LAST_CONNECTION] )
                {
                    if ( ![value isEqualToString:@" "])
                    {
                        service.connection.timestamp = [PMPPUtil stringAsDate:value];
                    }
                }
            }
        }
        
        return service;
    }
    
    return nil;
}

@end
