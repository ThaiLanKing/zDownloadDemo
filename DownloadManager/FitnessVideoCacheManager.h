//
//  FitnessVideoCacheManager.h
//  JamBoHealth
//
//  Created by zyh on 16/11/22.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SourceUrlKey;
extern NSString * const FileNameKey;
extern NSString * const SystemDownloadCahceFileNameKey;
extern NSString * const TotalFileSizeKey;

@interface FitnessVideoCacheManager : NSObject

+ (instancetype)sharedInstance;

+ (NSString *)fileNameFromURLStr:(NSString *)fileUrlStr;

+ (NSString *)videoStoredDir;
+ (NSString *)videoDownloadTempCacheDir;

/** key是文件URL（内部存储会对key进行md5处理）*/
- (id)cacheForKey:(NSString *)key;
- (void)updateForKey:(NSString *)key withData:(NSDictionary *)dataDic;
- (void)clearCache;

#pragma mark -

+ (BOOL)isFileOrDirectoryExist:(NSString *)path isFile:(BOOL)isFile;
+ (BOOL)isNullString:(NSString *)sourceStr;
+ (NSString *)md5HexDigest:(NSString *)input;

@end
