//
//  zAppCacheManager.h
//  JamBoHealth
//
//  Created by zyh on 16/6/1.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface zAppCacheManager : NSObject

+ (instancetype)sharedInstance;

- (id)cacheForKey:(NSString *)askKey;

- (void)updateForKey:(NSString *)askKey withData:(NSDictionary *)dataDic;

- (void)deleteForKey:(NSString *)askKey;

- (void)clearCache;

//存储与用户无关缓存时需要下面接口
- (void)createTableNamed:(NSString *)tableName;

- (id)cacheForKey:(NSString *)askKey inTable:(NSString *)tableName;

- (void)updateForKey:(NSString *)askKey withData:(NSDictionary *)dataDic inTable:(NSString *)tableName;

- (void)deleteForKey:(NSString *)askKey inTable:(NSString *)tableName;

- (void)clearCacheInTable:(NSString *)tableName;

//简单数据类型

- (NSNumber *)numberForKey:(NSString *)askKey inTable:(NSString *)tableName;

- (NSString *)stringForKey:(NSString *)askKey inTable:(NSString *)tableName;

- (void)updateForKey:(NSString *)askKey withNumber:(NSNumber *)number inTable:(NSString *)tableName;

- (void)updateForKey:(NSString *)askKey withString:(NSString *)string inTable:(NSString *)tableName;

@end
