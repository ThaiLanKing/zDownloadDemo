//
//  zDownloadManager.m
//  JamBoHealth
//
//  Created by zyh on 16/11/22.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import "zDownloadManager.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "FitnessVideoCacheManager.h"
#import <AFNetworking.h>
#import <objc/runtime.h>
#import <SVProgressHUD.h>

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

NSString * const VideoIsReadyNotification = @"videoIsReadyNotification";
NSString * const VideoDownloadProgressNotification = @"videoDownloadProgressNotification";
NSString * const VideoLocalPathKey = @"videoLocalPath";
NSString * const VideoDownloadProgressKey = @"videoDownloadProgress";
NSString * const VideoDownloadStateKey = @"videoDownloadStateKey";

NSString * const DownloadFileProperty = @"downloadFile";
NSString * const DownloadPathProperty = @"path";
NSString * const DownloadResumeDataLength = @"bytes=%ld-";
NSString * const DownloadHttpFieldRange = @"Range";
NSString * const DownloadKeyDownloadURL = @"NSURLSessionDownloadURL";
NSString * const DownloadTempFilePath = @"NSURLSessionResumeInfoLocalPath";
NSString * const DownloadKeyBytesReceived = @"NSURLSessionResumeBytesReceived";
NSString * const DownloadKeyCurrentRequest = @"NSURLSessionResumeCurrentRequest";
NSString * const DownloadKeyTempFileName = @"NSURLSessionResumeInfoTempFileName";

@interface zDownloadManager ()

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *resumeData;

@property (nonatomic, strong) AFHTTPSessionManager *sessionMgr;

@property (nonatomic, strong) FitnessVideoCacheManager *fitnessCacheMgr;

@property (nonatomic, strong) NSMutableDictionary *cacheDic;

@end

@implementation zDownloadManager

+ (instancetype)sharedInstance
{
    static zDownloadManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[zDownloadManager alloc] init];
        _sharedInstance.sessionMgr = [AFHTTPSessionManager manager];
        _sharedInstance.fitnessCacheMgr = [FitnessVideoCacheManager sharedInstance];
    });
    return _sharedInstance;
}

+ (long long)freeDiskSpace
{
    /// 剩余大小
    long long freesize = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {
        NSNumber *_free = [dictionary objectForKey:NSFileSystemFreeSize];
        freesize = [_free unsignedLongLongValue];
        
    }else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return freesize;
}

+ (long long)totalDiskSpace
{
    /// 总大小
    long long totalsize = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {
        NSNumber *_total = [dictionary objectForKey:NSFileSystemSize];
        totalsize = [_total unsignedLongLongValue];
        
    }else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
        
    }
    return totalsize;
}

#pragma mark - Method

- (void)startDownloadFromUrl:(NSString *)downloadURLString
{
    if (downloadURLString.length == 0) {
        return;
    }
    
    if (self.downloadTask) {
        [self stopDownload];
    }

    _cacheDic = [[self cacheForUrl:downloadURLString] mutableCopy];
    
    if ([self isFileDownloaded:downloadURLString]) {
        NSString *videoLocalPath = [[FitnessVideoCacheManager videoStoredDir] stringByAppendingPathComponent:_cacheDic[FileNameKey]];
        NSDictionary *videoInfo = @{VideoLocalPathKey : videoLocalPath};
        [[NSNotificationCenter defaultCenter] postNotificationName:VideoIsReadyNotification object:videoInfo];
        return;
    }
    
    self.resumeData = [self downloadedCacheDataForUrl:downloadURLString];
    
    if (self.resumeData) {
        self.downloadTask = [self.sessionMgr downloadTaskWithResumeData:self.resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            [self processDownloadProgress:downloadProgress];
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [self fileStoreUrlWithFileName:response.suggestedFilename];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                NSLog(@"download error info : %@", [error description]);
                
                if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
                    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
                    self.resumeData = resumeData;
                }
            
            }else {
                NSLog(@"download %@ success", self.cacheDic[FileNameKey]);
                
                NSString *videoLocalPath = [[FitnessVideoCacheManager videoStoredDir] stringByAppendingPathComponent:_cacheDic[FileNameKey]];
                NSDictionary *videoInfo = @{VideoLocalPathKey : videoLocalPath};
                [[NSNotificationCenter defaultCenter] postNotificationName:VideoIsReadyNotification object:videoInfo];
            
            }
        }];
        
    }else {
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        
        self.downloadTask = [self.sessionMgr downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            [self processDownloadProgress:downloadProgress];
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            NSString *fileName = response.suggestedFilename;
            [_cacheDic setValue:@(response.expectedContentLength) forKey:TotalFileSizeKey];
            [_cacheDic setValue:fileName forKey:FileNameKey];
            [self.fitnessCacheMgr updateForKey:_cacheDic[SourceUrlKey] withData:[_cacheDic copy]];
            return [self fileStoreUrlWithFileName:fileName];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error) {
                if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
                    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                    //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
                    self.resumeData = resumeData;
                }
                
            }else {
                NSLog(@"download %@ success", self.cacheDic[FileNameKey]);
                
                NSString *videoLocalPath = [[FitnessVideoCacheManager videoStoredDir] stringByAppendingPathComponent:_cacheDic[FileNameKey]];
                NSDictionary *videoInfo = @{VideoLocalPathKey : videoLocalPath};
                [[NSNotificationCenter defaultCenter] postNotificationName:VideoIsReadyNotification object:videoInfo];
                
            }
            
        }];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *tempCachePath = [self tempCacheFileNameForTask:self.downloadTask];
            if (tempCachePath.length > 0) {
                [_cacheDic setValue:[tempCachePath lastPathComponent] forKey:SystemDownloadCahceFileNameKey];
            }
        });
    
    }
    [self.downloadTask resume];
    self.resumeData = nil;
}

- (void)processDownloadProgress:(NSProgress *)downloadProgress
{
    NSLog(@"download progress : %.2f%%", 1.0f * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount * 100);
    _downloadProgress = downloadProgress;
    NSString *downloadProgressStr = [NSString stringWithFormat:@"%d", (int)(1.0f * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount * 100)];
    
    NSMutableDictionary *downloadInfo = [@{VideoDownloadProgressKey : downloadProgressStr} mutableCopy];
    if (downloadProgress.completedUnitCount == downloadProgress.totalUnitCount) {
        //下载完成
        [downloadInfo setValue:@(1) forKey:VideoDownloadStateKey];
    
    }else {
        if (downloadProgress.totalUnitCount - downloadProgress.completedUnitCount >= [zDownloadManager freeDiskSpace]) {
            [self pauseDownload];
            [SVProgressHUD showInfoWithStatus:@"存储空间不足，下载失败！"];
            
            //下载失败
            [downloadInfo setValue:@(2) forKey:VideoDownloadStateKey];
        
        }else {
            //下载中
            [downloadInfo setValue:@(0) forKey:VideoDownloadStateKey];
        
        }
    
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VideoDownloadProgressNotification object:[downloadInfo copy]];
    
}

- (NSURL *)fileStoreUrlWithFileName:(NSString *)fileName
{
    NSString *path = [[FitnessVideoCacheManager videoStoredDir] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

- (void)pauseDownload
{
    [self.downloadTask suspend];
}

- (void)continueDownload
{
    [self.downloadTask resume];
}

- (void)stopDownload
{
    if (self.downloadTask) {
        [self.downloadTask suspend];
    }
    if (_cacheDic) {
        [_cacheDic removeAllObjects];
    }
    self.downloadTask = nil;
    self.resumeData = nil;
    _cacheDic = nil;
    _downloadProgress = nil;
}

#pragma mark - 

- (BOOL)isFileDownloaded:(NSString *)url
{
    BOOL bDownloaded = NO;
    if (![FitnessVideoCacheManager isNullString:url]) {
        NSDictionary *cacheDic = [self.fitnessCacheMgr cacheForKey:url];
        if (cacheDic) {
            NSString *downloadFilePath = [[FitnessVideoCacheManager videoStoredDir] stringByAppendingPathComponent:cacheDic[FileNameKey]];
            if ([FitnessVideoCacheManager isFileOrDirectoryExist:downloadFilePath isFile:YES]) {
                bDownloaded = YES;
            }
        }
    }
    return bDownloaded;
}

- (NSArray *)downloadedUrlsInUrls:(NSArray *)urls
{
    NSMutableArray *resultUrls = [NSMutableArray arrayWithCapacity:0];
    for (NSString *url in urls) {
        if ([self isFileDownloaded:url]) {
            [resultUrls addObject:url];
        }
    }
    return [resultUrls copy];
}

- (NSDictionary *)cacheForUrl:(NSString *)url
{
    NSDictionary *cacheDic = [self.fitnessCacheMgr cacheForKey:url];
    if (!cacheDic) {
        NSMutableDictionary *tempMDic = [NSMutableDictionary dictionaryWithCapacity:0];
        [tempMDic setValue:url forKey:SourceUrlKey];
        [tempMDic setValue:[FitnessVideoCacheManager fileNameFromURLStr:url] forKey:FileNameKey];
        return tempMDic;
    }
    return cacheDic;
}

#pragma mark - 获取本地缓存

- (NSData *)downloadedCacheDataForUrl:(NSString *)downloadUrl
{
    NSData *resultData = nil;
    NSString *tempCacheFileName = _cacheDic[SystemDownloadCahceFileNameKey];
    if (tempCacheFileName.length > 0) {
        NSString *tempCacheFilePath = [[FitnessVideoCacheManager videoDownloadTempCacheDir] stringByAppendingPathComponent:tempCacheFileName];
        NSData *tempCacheData = [NSData dataWithContentsOfFile:tempCacheFilePath];
        
        if (tempCacheData && tempCacheData.length > 0) {
            NSMutableDictionary *resumeDataDict = [NSMutableDictionary dictionaryWithCapacity:0];
            NSMutableURLRequest *newResumeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
            [newResumeRequest addValue:[NSString stringWithFormat:DownloadResumeDataLength,(long)(tempCacheData.length)] forHTTPHeaderField:DownloadHttpFieldRange];
            NSData *newResumeRequestData = [NSKeyedArchiver archivedDataWithRootObject:newResumeRequest];
            [resumeDataDict setObject:@(tempCacheData.length) forKey:DownloadKeyBytesReceived];
            [resumeDataDict setObject:newResumeRequestData forKey:DownloadKeyCurrentRequest];
            [resumeDataDict setObject:tempCacheFileName forKey:DownloadKeyTempFileName];
            [resumeDataDict setObject:downloadUrl forKey:DownloadKeyDownloadURL];
            [resumeDataDict setObject:tempCacheFilePath forKey:DownloadTempFilePath];
            resultData = [NSPropertyListSerialization dataWithPropertyList:resumeDataDict format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListImmutable error:nil];
        }
    }
    
    if (![self isValidResumeData:resultData]) {
        resultData = nil;
    }
    
    return resultData;
}

//获取未下载完成的文件在本地的缓存文件名
- (NSString *)tempCacheFileNameForTask:(NSURLSessionDownloadTask *)downloadTask
{
    NSString *resultFileName = nil;
    //拉取属性
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([downloadTask class], &outCount);
    for (i = 0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* char_f = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        
        NSLog(@"proertyName : %@", propertyName);
        
        if ([DownloadFileProperty isEqualToString:propertyName]) {
            id propertyValue = [downloadTask valueForKey:(NSString *)propertyName];
            unsigned int downloadFileoutCount, downloadFileIndex;
            objc_property_t *downloadFileproperties = class_copyPropertyList([propertyValue class], &downloadFileoutCount);
            for (downloadFileIndex = 0; downloadFileIndex < downloadFileoutCount; downloadFileIndex++) {
                objc_property_t downloadFileproperty = downloadFileproperties[downloadFileIndex];
                const char* downloadFilechar_f = property_getName(downloadFileproperty);
                NSString *downloadFilepropertyName = [NSString stringWithUTF8String:downloadFilechar_f];
                
                NSLog(@"downloadFilepropertyName : %@", downloadFilepropertyName);
                
                if([DownloadPathProperty isEqualToString:downloadFilepropertyName]){
                    id downloadFilepropertyValue = [propertyValue valueForKey:(NSString *)downloadFilepropertyName];
                    if(downloadFilepropertyValue){
                        resultFileName = [downloadFilepropertyValue lastPathComponent];
                        [_cacheDic setValue:resultFileName forKey:SystemDownloadCahceFileNameKey];
                        [self.fitnessCacheMgr updateForKey:_cacheDic[SourceUrlKey] withData:[_cacheDic copy]];
                        NSLog(@"broken down temp cache path : %@", resultFileName);
                    }
                    break;
                }
            }
            free(downloadFileproperties);
        }else {
            continue;
        }
    }
    free(properties);
    
    return resultFileName;
}

- (BOOL)isValidResumeData:(NSData *)data{
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    NSString *localFilePath = [resumeDictionary objectForKey:DownloadTempFilePath];
    if ([localFilePath length] < 1) return NO;
    
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
}

#pragma mark -

@end
