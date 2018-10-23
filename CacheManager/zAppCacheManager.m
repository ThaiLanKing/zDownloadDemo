//
//  zAppCacheManager.m
//  JamBoHealth
//
//  Created by zyh on 16/6/1.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import "zAppCacheManager.h"
#import "YTKKeyValueStore.h"

#if bUseRealServer

NSString * const CacheDBName = @"JBCache.db";

#else

NSString * const CacheDBName = @"JBTestCache.db";

#endif

@interface zAppCacheManager ()

@property (nonatomic, strong) YTKKeyValueStore *cacheStore;

/**
 *  当前操作的表名
 *  表名以登录用户的id命名
 *  采用懒加载方式命名
 */
@property (nonatomic, copy) NSString *curTableName;

@end

@implementation zAppCacheManager

+ (instancetype)sharedInstance
{
    static zAppCacheManager *sharedInstance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        _cacheStore = [[YTKKeyValueStore alloc] initDBWithName:CacheDBName];
    
    }
    return self;
}

- (id)cacheForKey:(NSString *)askKey
{
    return [self cacheForKey:askKey inTable:self.curTableName];
}

- (void)updateForKey:(NSString *)askKey withData:(NSDictionary *)dataDic
{
    [self updateForKey:askKey withData:dataDic inTable:self.curTableName];
}

- (void)deleteForKey:(NSString *)askKey
{
    [self deleteForKey:askKey inTable:self.curTableName];
}

- (void)clearCache
{
    [self clearCacheInTable:self.curTableName];
}

#pragma mark -

- (NSString *)curTableName
{
    if (!_curTableName) {
#warning 需要根据项目实际需求设置缓存表名(比如用户userID)
        NSInteger userID = 10086;
        _curTableName = [NSString stringWithFormat:@"Cache%d", (int)userID];
        [_cacheStore createTableWithName:_curTableName];
    }
    return _curTableName;
}


#pragma mark -

- (void)createTableNamed:(NSString *)tableName
{
    [_cacheStore createTableWithName:tableName];
}

- (id)cacheForKey:(NSString *)askKey inTable:(NSString *)tableName
{
    if (askKey.length == 0 || tableName.length == 0) {
        return nil;
    }
    return [_cacheStore getObjectById:askKey fromTable:tableName];
}

- (void)updateForKey:(NSString *)askKey withData:(NSDictionary *)dataDic inTable:(NSString *)tableName
{
    if (tableName.length > 0) {
        if (dataDic) {
            [_cacheStore putObject:dataDic withId:askKey intoTable:tableName];
        
        }else {
            NSLog(@"update data failed : dataDic is nil");
        
        }
        
        
    }else {
        NSLog(@"update data failed : tableName is nil");
        
    }
}

- (void)deleteForKey:(NSString *)askKey inTable:(NSString *)tableName
{
    if (tableName.length > 0) {
        [_cacheStore deleteObjectById:askKey fromTable:tableName];
    }
}

- (void)clearCacheInTable:(NSString *)tableName
{
    if (tableName.length > 0) {
        [_cacheStore clearTable:tableName];
    }
}

#pragma mark -

- (NSNumber *)numberForKey:(NSString *)askKey inTable:(NSString *)tableName
{
    if (askKey.length == 0 || tableName.length == 0) {
        return nil;
    }
    return [_cacheStore getNumberById:askKey fromTable:tableName];
}

- (NSString *)stringForKey:(NSString *)askKey inTable:(NSString *)tableName
{
    if (askKey.length == 0 || tableName.length == 0) {
        return nil;
    }
    return [_cacheStore getStringById:askKey fromTable:tableName];
}

- (void)updateForKey:(NSString *)askKey withNumber:(NSNumber *)number inTable:(NSString *)tableName
{
    if (tableName.length > 0) {
        if (number) {
            [_cacheStore putNumber:number withId:askKey intoTable:tableName];
            
        }else {
            NSLog(@"update data failed : data is nil");
            
        }
        
        
    }else {
        NSLog(@"update data failed : tableName is nil");
        
    }
}

- (void)updateForKey:(NSString *)askKey withString:(NSString *)string inTable:(NSString *)tableName
{
    if (tableName.length > 0) {
        if (string.length > 0) {
            [_cacheStore putString:string withId:askKey intoTable:tableName];
            
        }else {
            NSLog(@"update data failed : data is nil");
            
        }
        
        
    }else {
        NSLog(@"update data failed : tableName is nil");
        
    }
}

@end
