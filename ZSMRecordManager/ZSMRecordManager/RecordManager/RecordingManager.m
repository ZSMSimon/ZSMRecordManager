//
//  RecordingManager.m
//  ZSMRecordManager
//
//  Created by Simon on 2018/5/16.
//  Copyright © 2018年 Simon. All rights reserved.
//

#import "RecordingManager.h"

@interface RecordingManager ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioSession *audioSession;

/** 音频录音机 */
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;

#pragma mark -- 录音前配置录音相关属性

/** 录音相关设置 */
@property (nonatomic, strong, readwrite) NSMutableDictionary *audioSettion;

#pragma mark -- 录音完成后

/** 录音文件路径(字符串) */
@property (nonatomic, strong, readwrite) NSString *filePath;

/** 录音文件路径(链接) */
@property (nonatomic, strong, readwrite) NSURL *filePathURL;

/** 录音总时间 */
@property (nonatomic, assign, readwrite) CGFloat totalTime;

/** 录音时长 */
@property (nonatomic, assign, readwrite) NSTimeInterval currentTime;

/** 录音声波状态 */
@property (nonatomic, assign, readwrite) CGFloat powerProgress;

/** 录音的分贝 */
@property (nonatomic, assign, readwrite) int audioDB;

/** 录音状态 */
@property (nonatomic, assign, readwrite) RecordState recordState;

/** 录音定时器 */
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation RecordingManager

#pragma mark - 初始化

- (instancetype)init {
    
    if ([super init]) {
        [self audioSession];
    }
    
    return self;
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (void)dealloc {
    if (self.timer) {
        
        //计时器停止
        [self.timer invalidate];
        
        //释放定时器
        self.timer = nil;
    }
}

#pragma mark - 录音

- (AVAudioRecorder *)audioRecorder {
    
    if (_audioRecorder == nil) {
        
        NSError * error = nil;
        _filePath = [self getSavePath];
        _filePathURL = [NSURL fileURLWithPath:_filePath];
        
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:_filePathURL settings:self.audioSettion error:&error];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES; //如果要控制声波则必须设置为YES
        
        if(error) {
            NSLog(@"创建录音机对象发生错误，错误信息是：%@",error.localizedDescription);
            return nil;
        }
    }
    
    return _audioRecorder;
}

//录音设置
- (NSMutableDictionary *)audioSettion {
    if (_audioSettion == nil) {
        
        NSMutableDictionary *audioSettionM = [NSMutableDictionary dictionary];
        
        //设置录音格式
        [audioSettionM setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
        
        //设置录音采样率，8000是电话采样率，对于一般的录音已经够了
        [audioSettionM setObject:@(8000) forKey:AVSampleRateKey];
        
        //设置通道
        [audioSettionM setObject:@(1) forKey:AVNumberOfChannelsKey];
        
        //每个采样点位数，分为8，16，24，32
        [audioSettionM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
        
        //是否使用浮点数采样
        [audioSettionM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
        
        //录音质量
        [audioSettionM setObject:@(AVAudioQualityHigh) forKey:AVEncoderAudioQualityKey];
        
        _audioSettion = audioSettionM;
    }
    return _audioSettion;
}

//增加或修改录音设置
- (void)setaudioSettionWithKey:(NSString *)key andValue:(NSString *)value {
    
    [self.audioSettion setObject:key forKey:value];
}

- (NSString *)filePath {
    if (_filePath == nil || [_filePath isEqual:[NSNull null]]) {
        _filePath = [self getSavePath];
    }
    return _filePath;
}

- (NSURL *)filePathURL {
    
    _filePathURL = [NSURL URLWithString:self.filePath];
    
    return _filePathURL;
}

- (AVAudioSession *)audioSession {
    
    if (_audioSession == nil) {
        
        _audioSession = [AVAudioSession sharedInstance];
        
        //设置为播放和录制状态，以便在录制完成之后播放录音
        NSError *sessionError;
        [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        if (_audioSession == nil) {
            NSLog(@"Error creating session: %@",[sessionError description]);
        }else {
            [_audioSession setActive:YES error:nil];
        }
    }
    
    return _audioSession;
}

#pragma mark - 指定文件名或文件路径生成AVAudioRecorder对象,若不通过此方式生成，将会自动生成唯一文件名

//指定音频URL地址创建AVAudioRecorder对象，传入的error来传递准备录制过程中出现的异常
- (BOOL)prepareWithAudioURL:(NSURL *)url error:(NSError **)error {
    
    [_audioRecorder stop];
    
    _filePath = url.absoluteString;
    _filePathURL = url;
    
    if (!self.audioSession) {
        
        self.recordState = RecordStateError;
        return NO;
    }
    
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:self.audioSettion error:error];
    
    if (_audioRecorder && [_audioRecorder prepareToRecord]) {
        
        self.recordState = RecordStateReady;
        return YES;
    }
    
    self.recordState = RecordStateError;
    return NO;
}

/**
 指定音频名称创建AVAudioRecorder对象，传入的error来传递准备录制过程中出现的异常
 */
- (BOOL)prepareWithAudioName:(NSString *)name error:(NSError **)error {
    
    [_audioRecorder stop];
    
    if (!self.audioSession) {
        
        self.recordState = RecordStateError;
        return NO;
    }
    
    NSString * urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _filePath = [urlStr stringByAppendingPathComponent:name];
    
    _filePathURL = [NSURL fileURLWithPath:_filePath];
    
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:_filePathURL settings:self.audioSettion error:error];
    
    if (_audioRecorder && [_audioRecorder prepareToRecord]) {
        
        self.recordState = RecordStateReady;
        return YES;
    }
    
    self.recordState = RecordStateError;
    return NO;
}

#pragma mark - 录音方法

//验证权限
+ (BOOL)checkPermission {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined: {
            
            return NO;//没有询问是否开启麦克风
        }
            break;
        case AVAuthorizationStatusRestricted: {
            
            return NO;//未授权，家长限制
        }
            break;
        case AVAuthorizationStatusDenied: {
            
            return NO;//用户未授权
        }
            break;
        case AVAuthorizationStatusAuthorized:{
            
            return YES;//用户已经授权
        }
            break;
        default:{
            return NO;
        }
    }
}

//提示去授权麦克风
+ (void)promptAuthorizationCallBack:(AuthorizationCompletionBlock)completionBlock {
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        
        completionBlock(granted);
    }];
}

//开始录音
- (void)startReocrd {
    
    if ([RecordingManager checkPermission] == NO) {
        
        NSLog(@"还未开启麦克风权限");
        return;
    }
    
    if (![self.audioRecorder isRecording]) {
        
        [self.audioRecorder record];
        self.recordState = RecordStatePlaying;
        self.timer.fireDate = [NSDate distantPast];
    }
}

//暂停录音
- (void)pauseRecord {
    
    if ([self.audioRecorder isRecording]) {
        
        [self.audioRecorder pause];
        self.recordState = RecordStatePause;
        self.timer.fireDate = [NSDate distantFuture];
    }
}

//继续录音
- (void)continueRecord {
    
    if (![self.audioRecorder isRecording]) {
        
        [self startReocrd];
        self.recordState = RecordStatePlaying;
        self.timer.fireDate = [NSDate distantPast];
    }
}

//结束录音
- (NSString *)stopRecord {
    
    [self.audioRecorder stop];
    self.recordState = RecordStateStopped;
    self.timer.fireDate = [NSDate distantFuture];
    
    return self.filePath;
}

/**
 删除当前正在录制的音频文件
 
 @return 返回YES，删除成功；返回NO，删除失败
 */
- (BOOL)delegateRecord {
    
    [self stopRecord];
    
    if([self.audioRecorder deleteRecording]){
        self.recordState = RecordStateDeleted;
        return YES;
    };
    return NO;
}

//重置录音
- (void)retRecord {
    
    if (![self.audioRecorder isRecording]) {
        
        BOOL status = [self delegateRecord];
        if (status == YES) {
            
            self.recordState = RecordStateReady;
            return;
        }
    }
    
    [self stopRecord];
    self.recordState = RecordStateReady;
}

//定时器方法
- (void)audioPowerChange {
    
    [self.audioRecorder updateMeters];  //更新测量值
    
    float power = [self.audioRecorder averagePowerForChannel:0]; //取得第一个通道的音频，注意音频强度范围时-160到0
    
    self.audioDB = [RecordingManager dbAudioPowerConversion:power];
    
    self.powerProgress = (1.0/160)*(power+160);
    
    self.currentTime = self.audioRecorder.currentTime;
    
    if (self.recordingBlock) {
        self.recordingBlock(self.currentTime, self.powerProgress,self.audioDB);
    }
}

#pragma mark - 录音代理

//录音结束
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    self.timer.fireDate = [NSDate distantFuture];
    self.recordState = RecordStateReady;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *filePath = self.filePath;
    
    if ([manager fileExistsAtPath:filePath]) {
        NSLog(@"%0.2fKB",[[manager attributesOfItemAtPath:filePath error:nil] fileSize]/1024.0);
    }
    
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:self.filePathURL options:nil];
    CMTime audioDuration = audioAsset.duration;
    
    self.totalTime = CMTimeGetSeconds(audioDuration);
}

//录音编码错误
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    
    self.timer.fireDate = [NSDate distantFuture];
    self.recordState = RecordStateError;
    
    self.filePath = nil;
    self.filePathURL = nil;
    self.totalTime = 0;
    
    NSLog(@"录音编码错误：%@",error);
}

#pragma mark - 其他

/**
 创建唯一字符串，UUID + 时间戳
 @return 唯一字符串
 */
+ (NSString *)generateUniqueID {
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSMutableString *uniqueID = [[NSMutableString alloc] initWithString:UUID];
    
    UInt64 milliseconds = [[NSDate date] timeIntervalSince1970] * 1000;
    
    [uniqueID appendString:[NSString stringWithFormat:@"%llu", milliseconds]];
    
    return uniqueID.copy;
}

/**
 生成音频文件名，UUID + 时间戳 + 音频后缀
 
 @param fileType 音频类型
 @return 音频文件名
 */
+ (NSString *)generateAudioNameWithFileType:(nullable NSString *)fileType {
    
    if (fileType == nil) {
        fileType = @".acc";
    }
    
    return [[self generateUniqueID] stringByAppendingString:fileType];
}

//取得录音文件的保存路径
- (NSString *)getSavePath {
    
    NSString * urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [urlStr stringByAppendingPathComponent:[RecordingManager generateAudioNameWithFileType:nil]];
    
    return filePath;
}

//声波强度转分贝
+ (int)dbAudioPowerConversion:(CGFloat)power {
    
    // 关键代码
    power = power + 160 - 50;
    
    int dB = 0;
    if (power < 0.f) {
        dB = 0;
    }
    else if (power < 40.f) {
        dB = (int)(power * 0.875);
    }
    else if (power < 100.f) {
        dB = (int)(power - 15);
    }
    else if (power < 110.f) {
        dB = (int)(power * 2.5 - 165);
    }
    else {
        dB = 110;
    }
    
    return dB;
}

@end
