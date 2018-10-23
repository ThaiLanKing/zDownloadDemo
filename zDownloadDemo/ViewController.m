//
//  ViewController.m
//  zDownloadDemo
//
//  Created by zyh on 2018/10/23.
//  Copyright © 2018年 zyh. All rights reserved.
//

#import "ViewController.h"
#import "zDownloadManager.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    [downloadBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    downloadBtn.frame = CGRectMake(100, 100, 80, 60);
    [downloadBtn addTarget:self action:@selector(downloadFile) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadBtn];
}

- (void)downloadFile
{
    NSString *fileUrl = @"";
    [[zDownloadManager sharedInstance] startDownloadFromUrl:fileUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
