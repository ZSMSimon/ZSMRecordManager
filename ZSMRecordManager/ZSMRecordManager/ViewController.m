//
//  ViewController.m
//  ZSMRecordManager
//
//  Created by Simon on 2018/5/17.
//  Copyright © 2018年 Simon. All rights reserved.
//

#import "ViewController.h"
#import "RecordingManager.h"

#define mScreenWidth        ([UIScreen mainScreen].bounds.size.width)
#define mScreenHeight       ([UIScreen mainScreen].bounds.size.height)

@interface ViewController ()

@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UILabel *powerLabel;
@property (strong, nonatomic) UIButton *againButton;
@property (strong, nonatomic) UIButton *recordButton;
@property (strong, nonatomic) UIButton *stopButton;

@property (nonatomic, strong) RecordingManager *recordManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
}

- (void)dealloc {
    NSLog(@"这个界面释放了");
}


/** 私有方法 */
#pragma mark - Private Methods

- (void)setUI {
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(mScreenWidth/2-150, 170, 100, 50)];
    self.timeLabel.textColor = [UIColor redColor];
    self.timeLabel.backgroundColor = [UIColor whiteColor];
    self.timeLabel.text = @"00:00";
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.timeLabel];
    
    self.powerLabel = [[UILabel alloc] initWithFrame:CGRectMake(mScreenWidth/2+50, 170, 100, 50)];
    self.powerLabel.textColor = [UIColor redColor];
    self.powerLabel.backgroundColor = [UIColor whiteColor];
    self.powerLabel.text = @"0";
    self.powerLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.powerLabel];
    
    self.againButton = [[UIButton alloc] initWithFrame:CGRectMake(mScreenWidth/2-150, 300, 50, 50)];
    [self.againButton setTitle:@"重录" forState:UIControlStateNormal];
    [self.againButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.againButton.backgroundColor = [UIColor whiteColor];
    [self.againButton addTarget:self action:@selector(again:) forControlEvents:UIControlEventTouchUpInside];
    self.againButton.hidden = YES;
    [self.view addSubview:self.againButton];
    
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(mScreenWidth/2-25, 300, 50, 50)];
    [self.recordButton setTitle:@"录音" forState:UIControlStateNormal];
    [self.recordButton setTitle:@"暂停" forState:UIControlStateSelected];
    [self.recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.recordButton.backgroundColor = [UIColor whiteColor];
    [self.recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.recordButton];
    
    self.stopButton = [[UIButton alloc] initWithFrame:CGRectMake(mScreenWidth/2+100, 300, 50, 50)];
    [self.stopButton setTitle:@"停止" forState:UIControlStateNormal];
    [self.stopButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.stopButton.backgroundColor = [UIColor whiteColor];
    [self.stopButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    self.stopButton.hidden = YES;
    [self.view addSubview:self.stopButton];
}

/** 按钮和手势的响应 */
#pragma mark - Event Response

- (void)again:(UIButton *)sender {
    
    [self.recordManager retRecord];
}

- (void)record:(UIButton *)sender {
    
    if (![RecordingManager checkPermission]) {
        
        __weak __typeof__(self) weakSelf = self;
        [RecordingManager promptAuthorizationCallBack:^(BOOL status) {
            
            if (status == YES) {
                
                [weakSelf canRecord:sender];
            }
        }];
        
    } else {
        
        [self canRecord:sender];
    }
}

- (void)canRecord:(UIButton *)sender {
    
    if (self.againButton.hidden == YES) {
        
        [self.recordManager startReocrd];
        
        sender.selected = YES;
        
        self.againButton.hidden = NO;
        self.stopButton.hidden = NO;
        
    } else {
        
        if (sender.selected == YES) {
            
            [self.recordManager pauseRecord];
            
            sender.selected = NO;
            
        } else {
            
            [self.recordManager continueRecord];
            
            sender.selected = YES;
        }
    }
}

- (void)stop:(UIButton *)sender {
    
    [self.recordManager stopRecord];
}


/** 初始化 */
#pragma mark - Getter and Setter

- (RecordingManager *)recordManager {
    if (_recordManager == nil || [_recordManager isEqual:[NSNull null]]) {
        _recordManager = [[RecordingManager alloc] init];
        
        __weak __typeof__(self) weakSelf = self;
        _recordManager.recordingBlock = ^(NSTimeInterval currentTime, CGFloat progress, int audioDB) {
            
             NSString *time = [NSString stringWithFormat:@"%02d:%02d",(int)currentTime / 60,(int)currentTime % 60];
            weakSelf.timeLabel.text = time;
            
            weakSelf.powerLabel.text = [NSString stringWithFormat:@"%f",progress];
        };
    }
    return _recordManager;
}

@end
