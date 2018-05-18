//
//  RecordingManager.h
//  ZSMRecordManager
//
//  Created by Simon on 2018/5/16.
//  Copyright © 2018年 Simon. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RecordState) {
    RecordStateReady,      // 准备录音
    RecordStatePlaying,    // 录音中
    RecordStatePause,      // 录音暂停
    RecordStateStopped,    // 停止录音
    RecordStateDeleted,    // 录音删除
    RecordStateError       // 录音出错
};

/** 麦克风授权回调 */
typedef void(^AuthorizationCompletionBlock)(BOOL);

/** 录音时间和录音音波强度回调 */
typedef void(^RecordCallBackBlock)(NSTimeInterval,CGFloat,int);

@interface RecordingManager : NSObject


#pragma mark - 录音状态

/** 录音状态 */
@property (nonatomic, assign, readonly) RecordState recordState;



#pragma mark -- 录音前配置录音相关属性

/** 录音相关设置 默认值请查看初始化说明 */
@property (nonatomic, strong, readonly) NSMutableDictionary *audioSettion;

/** 增加或修改录音设置 */
- (void)setaudioSettionWithKey:(NSString *)key andValue:(NSString *)value;



#pragma mark -- 单次录音

/** 录音文件路径(字符串) */
@property (nonatomic, strong, readonly) NSString *filePath;

/** 录音文件路径(链接) */
@property (nonatomic, strong, readonly) NSURL *filePathURL;

/** 录音总时间 */
@property (nonatomic, assign, readonly) CGFloat totalTime;

/** 录音时长 */
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;

/** 录音声波状态 */
@property (nonatomic, assign, readonly) CGFloat audioPowerProgress;

/** 录音的分贝 */
@property (nonatomic, assign, readonly) int audioDB;

/** 录音时长和声波状态block */
@property (nonatomic, copy) RecordCallBackBlock recordingBlock;

#pragma mark - 指定文件名或文件路径生成AVAudioRecorder对象,若不通过此方式生成，将会自动生成唯一文件名

/**
 指定音频URL地址创建AVAudioRecorder对象，传入的error来传递准备录制过程中出现的异常
 
 @param url 录制音频的保存的位置
 @param error 录制过程出现的错误信息
 @return 返回YES，准备工作顺利完成，NO，准备工作失败，使用error查看具体错误原因
 */
- (BOOL)prepareWithAudioURL:(NSURL *)url error:(NSError **)error;

/**
 指定音频名称创建AVAudioRecorder对象，传入的error来传递准备录制过程中出现的异常
 
 @param name 录制音频的名称（包括音频文件类型 如user.acc）
 @param error 录制过程出现的错误信息
 @return 返回YES，准备工作顺利完成，NO，准备工作失败，使用error查看具体错误原因
 */
- (BOOL)prepareWithAudioName:(NSString *)name error:(NSError **)error;



#pragma mark - 录音方法

/**
 开始录音
 */
- (void)startReocrd;

/**
 继续录音
 */
- (void)continueRecord;

/**
 暂停录音
 */
- (void)pauseRecord;

/**
 停止录音
 
 @return 音频地址
 */
- (NSString *)stopRecord;

/**
 删除当前正在录制的音频文件
 
 @return 返回YES，删除成功；返回NO，删除失败
 */
- (BOOL)delegateRecord;

/**
 重置录音
 */
- (void)retRecord;



#pragma mark - 其他

/**
 权限判断
 */
+ (BOOL)checkPermission;

/**
 提示去授权麦克风

 @param completionBlock 授权成功或失败后的回调
 */
+ (void)promptAuthorizationCallBack:(AuthorizationCompletionBlock)completionBlock;

/**
 生成唯一音频文件名，UUID + 时间戳 + 音频后缀

 @param fileType 音频类型 默认类型为.acc
 @return 音频文件名
 */
+ (NSString *)generateAudioNameWithFileType:(NSString *)fileType;

/**
 声波强度转分贝

 @param power 声波强度
 @return 分贝
 */
+ (int)dbAudioPowerConversion:(CGFloat)power;

@end
