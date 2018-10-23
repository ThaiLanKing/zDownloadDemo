//
//  zDownloadManager.h
//  JamBoHealth
//
//  Created by zyh on 16/11/22.
//  Copyright © 2016年 zyh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const VideoIsReadyNotification;
extern NSString * const VideoDownloadProgressNotification;
extern NSString * const VideoLocalPathKey;
extern NSString * const VideoDownloadProgressKey;
extern NSString * const VideoDownloadStateKey;

@interface zDownloadManager : NSObject

@property (nonatomic, readonly) NSProgress *downloadProgress;

+ (instancetype)sharedInstance;

+ (long long)freeDiskSpace;
+ (long long)totalDiskSpace;

- (void)startDownloadFromUrl:(NSString *)downloadURLString;

- (void)pauseDownload;
- (void)continueDownload;

- (void)stopDownload;

- (BOOL)isFileDownloaded:(NSString *)url;
//返回已经下载的url数组，若返回空数组则表示未下载
- (NSArray *)downloadedUrlsInUrls:(NSArray *)urls;

@end
