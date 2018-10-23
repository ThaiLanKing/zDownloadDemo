//
//  FitnessVideoCacheManager.m
//  JamBoHealth
//
//  Created by zyh on 16/11/22.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import "FitnessVideoCacheManager.h"
#import "zAppCacheManager.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const FitnessVideoCacheTableName = @"FitnessVideoCacheTable";

NSString * const SourceUrlKey = @"sourceUrl";
NSString * const FileNameKey = @"fileName";
//系统下载未完成生成的临时文件名（因为每次启动app目录路径都会变，故只存储文件名，路径利用系统接口动态拼接）
NSString * const SystemDownloadCahceFileNameKey = @"systemDownloadCacheFileName";
NSString * const TotalFileSizeKey = @"totalFileSize";

/** 缓存以视频url为Key，记录文件下载后的本地存储路径、文件大小等相关信息*/
@interface FitnessVideoCacheManager ()

@property (nonatomic, strong) zAppCacheManager *cacheMgr;

/** 对URL进行MD5处理*/
+ (NSString *)keyWithUrl:(NSString *)url;

@end

@implementation FitnessVideoCacheManager

+ (instancetype)sharedInstance
{
    static FitnessVideoCacheManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[FitnessVideoCacheManager alloc] init];
        _sharedInstance.cacheMgr = [zAppCacheManager sharedInstance];
        [_sharedInstance.cacheMgr createTableNamed:FitnessVideoCacheTableName];
    });
    return _sharedInstance;
}

+ (NSString *)fileNameFromURLStr:(NSString *)fileUrlStr
{
    NSString *fileName = nil;
    if (fileUrlStr.length > 0) {
        NSArray *tempArr = [fileUrlStr componentsSeparatedByString:@"/"];
        fileName = [tempArr lastObject];
    }
    return fileName;
}

+ (NSString *)videoStoredDir
{
    NSString *documentDir = [[self class] documentDirectory];
    NSString *fileDir = [documentDir stringByAppendingPathComponent:@"fitnessVideo"];
    [[self class] createDir:fileDir];
    return fileDir;
}

+ (NSString *)videoDownloadTempCacheDir
{
    NSString *tempCacheDir = NSTemporaryDirectory();
    return tempCacheDir;
}

+ (NSString *)keyWithUrl:(NSString *)url
{
    if ([[self class] isNullString:url]) {
        return nil;
    }
    return [[self class] md5HexDigest:url];
}

- (id)cacheForKey:(NSString *)key
{
    if ([[self class] isNullString:key]) {
        return nil;
    }
    return [self.cacheMgr cacheForKey:[FitnessVideoCacheManager keyWithUrl:key] inTable:FitnessVideoCacheTableName];
}

- (void)updateForKey:(NSString *)key withData:(NSDictionary *)dataDic
{
    [self.cacheMgr updateForKey:[FitnessVideoCacheManager keyWithUrl:key] withData:dataDic inTable:FitnessVideoCacheTableName];
}

- (void)clearCache
{
    [self.cacheMgr clearCacheInTable:FitnessVideoCacheTableName];
}

#pragma mark -

+ (NSString *)documentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+ (BOOL)createDir:(NSString *)dir
{
    BOOL bResult = YES;
    if (![self isFileOrDirectoryExist:dir isFile:NO]){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        bResult = [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
        if (!bResult) {
            NSString *errMsg = [NSString stringWithFormat:@"create Dir : %@ faild, error : %@", dir, [error description]];
            NSAssert(bResult, errMsg);
        }
    }
    return bResult;
}

+ (BOOL)isFileOrDirectoryExist:(NSString *)path isFile:(BOOL)isFile
{
    BOOL exist = NO;
    BOOL isDir = NO;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            if (!isFile) {
                exist = YES;
                
            }else {
                NSLog(@"this file :%@ is not exist", path);
                
            }
            
        }else {
            if (isFile) {
                exist = YES;
                
            }else {
                NSLog(@"this Directory :%@ is not exist", path);
                
            }
            
        }
    }
    return exist;
}

+ (BOOL)isNullString:(NSString *)sourceStr
{
    BOOL bResult = YES;
    if (![sourceStr isEqual:[NSNull null]] && sourceStr.length > 0) {
        bResult = NO;
    }
    return bResult;
}

+ (NSString *)md5HexDigest:(NSString *)input
{
    NSMutableString *ret = [NSMutableString stringWithCapacity:0];
    if (input) {
        const char* str = [input UTF8String];
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5(str, (CC_LONG)strlen(str), result);
        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [ret appendFormat:@"%02x",result[i]];
        }
    }
    return ret;
}

@end
