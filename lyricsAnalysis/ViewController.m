//
//  ViewController.m
//  lyricsAnalysis
//
//  Created by 王双龙 on 2017/6/5.
//  Copyright © 2017年 https://github.com/wslcmk  All rights reserved.
//

#import "ViewController.h"
#import "wslAnalyzer.h"
#import "wslLrcEach.h"
#import <MediaPlayer/MediaPlayer.h>
#import <notify.h>

#define SONGNAME @"多幸运"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    id _playerTimeObserver;
    BOOL _isDragging;
    UIImage * _lastImage;//最后一次锁屏之后的歌词海报
    
}
//歌词数组
@property (nonatomic , strong) NSMutableArray * lrcArray;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) AVPlayer * player;

//当前歌词所在位置
@property (nonatomic,assign)  NSInteger currentRow;

//用来显示锁屏歌词
@property (nonatomic, strong) UITableView * lockScreenTableView;
//锁屏图片视图,用来绘制带歌词的image
@property (nonatomic, strong) UIImageView * lrcImageView;;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getLrcArray];
    
    [self.player play];
    
    [self playControl];
    
    [self.view addSubview:self.tableView];
    //添加远程锁屏控制
    [self createRemoteCommandCenter];
    
}

//锁屏界面开启和监控远程控制事件
- (void)createRemoteCommandCenter{
    /**/
    //远程控制命令中心 iOS 7.1 之后  详情看官方文档：https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    //   MPFeedbackCommand对象反映了当前App所播放的反馈状态. MPRemoteCommandCenter对象提供feedback对象用于对媒体文件进行喜欢, 不喜欢, 标记的操作. 效果类似于网易云音乐锁屏时的效果
    
    //添加喜欢按钮
    MPFeedbackCommand *likeCommand = commandCenter.likeCommand;
    likeCommand.enabled = YES;
    likeCommand.localizedTitle = @"喜欢";
    [likeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"喜欢");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //添加不喜欢按钮，假装是“上一首”
    MPFeedbackCommand *dislikeCommand = commandCenter.dislikeCommand;
    dislikeCommand.enabled = YES;
    dislikeCommand.localizedTitle = @"上一首";
    [dislikeCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"上一首");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //标记
    MPFeedbackCommand *bookmarkCommand = commandCenter.bookmarkCommand;
    bookmarkCommand.enabled = YES;
    bookmarkCommand.localizedTitle = @"标记";
    [bookmarkCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"标记");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    //    commandCenter.togglePlayPauseCommand 耳机线控的暂停/播放
    __weak typeof(self) weakSelf = self;
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf.player play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    //    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //        NSLog(@"上一首");
    //        return MPRemoteCommandHandlerStatusSuccess;
    //    }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        NSLog(@"下一首");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    //快进
    //    MPSkipIntervalCommand *skipBackwardIntervalCommand = commandCenter.skipForwardCommand;
    //    skipBackwardIntervalCommand.preferredIntervals = @[@(54)];
    //    skipBackwardIntervalCommand.enabled = YES;
    //    [skipBackwardIntervalCommand addTarget:self action:@selector(skipBackwardEvent:)];
    
    //在控制台拖动进度条调节进度（仿QQ音乐的效果）
    [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        CMTime totlaTime = weakSelf.player.currentItem.duration;
        MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
        [weakSelf.player seekToTime:CMTimeMake(totlaTime.value*playbackPositionEvent.positionTime/CMTimeGetSeconds(totlaTime), totlaTime.timescale) completionHandler:^(BOOL finished) {
        }];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
}

-(void)skipBackwardEvent: (MPSkipIntervalCommandEvent *)skipEvent
{
    NSLog(@"快进了 %f秒", skipEvent.interval);
}

//移除观察者
- (void)removeObserver{
    
    [self.player removeTimeObserver:_playerTimeObserver];
    _playerTimeObserver = nil;
    //    self.player = nil;
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.likeCommand removeTarget:self];
    [commandCenter.dislikeCommand removeTarget:self];
    [commandCenter.bookmarkCommand removeTarget:self];
    [commandCenter.nextTrackCommand removeTarget:self];
    [commandCenter.skipForwardCommand removeTarget:self];
    [commandCenter.changePlaybackPositionCommand removeTarget:self];
    commandCenter = nil;
}
#pragma mark -- Help Methods

//获得歌词数组
- (void)getLrcArray{
    wslAnalyzer *  analyzer = [[wslAnalyzer alloc] init];
    NSString * path = [[NSBundle mainBundle] pathForResource:SONGNAME ofType:@"txt"];
    self.lrcArray =  [analyzer analyzerLrcBylrcString:[NSString  stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
}
//在具体的控制器或其它类中捕获处理远程控制事件,当远程控制事件发生时触发该方法, 该方法属于UIResponder类，iOS 7.1 之前经常用
- (void)remoteControlReceivedWithEvent:(UIEvent *)event{
    NSLog(@"%ld",event.type);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"songRemoteControlNotification" object:self userInfo:@{@"eventSubtype":@(event.subtype)}];
}

//播放控制和监测
- (void)playControl{
    
    //后台播放音频设置,需要在Capabilities->Background Modes中勾选Audio,Airplay,and Picture in Picture
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    
    __weak ViewController * weakSelf = self;
    _playerTimeObserver = [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMake(0.1*30, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        CGFloat currentTime = CMTimeGetSeconds(time);
        
        CMTime total = weakSelf.player.currentItem.duration;
        CGFloat totalTime = CMTimeGetSeconds(total);
        
        if (!_isDragging) {
            
            //歌词滚动显示
            for ( int i = (int)(self.lrcArray.count - 1); i >= 0 ;i--) {
                wslLrcEach * lrc = self.lrcArray[i];
                if (lrc.time < currentTime) {
                    self.currentRow = i;
                    NSIndexPath * currentIndexPath = [NSIndexPath indexPathForRow: self.currentRow inSection:0];
                    [self.tableView scrollToRowAtIndexPath:currentIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    [self.tableView reloadData];
                    [self.lockScreenTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self. currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    [self.lockScreenTableView reloadData];
                    break;
                }
            }
        }
        
        //监听锁屏状态 lock=1则为锁屏状态
        uint64_t locked;
        __block int token = 0;
        notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){
        });
        notify_get_state(token, &locked);
        
        //监听屏幕点亮状态 screenLight = 1则为变暗关闭状态
        uint64_t screenLight;
        __block int lightToken = 0;
        notify_register_dispatch("com.apple.springboard.hasBlankedScreen",&lightToken,dispatch_get_main_queue(),^(int t){
        });
        notify_get_state(lightToken, &screenLight);
        
        BOOL isShowLyricsPoster = NO;
        // NSLog(@"screenLight=%llu locked=%llu",screenLight,locked);
        if (screenLight == 0 && locked == 1) {
            //点亮且锁屏时
            isShowLyricsPoster = YES;
        }else if(screenLight){
            return;
        }
        
        //展示锁屏歌曲信息，上面监听屏幕锁屏和点亮状态的目的是为了提高效率
        [self showLockScreenTotaltime:totalTime andCurrentTime:currentTime andRate:weakSelf.player.rate andLyricsPoster:isShowLyricsPoster];
        
    }];
    
    /* iOS 7.1之前
     //让App开始接收远程控制事件, 该方法属于UIApplication类
     [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
     //结束远程控制,需要的时候关闭
     //     [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
     //处理控制台的暂停/播放、上/下一首事件
     [[NSNotificationCenter defaultCenter] addObserverForName:@"songRemoteControlNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
     
     NSInteger  eventSubtype = [notification.userInfo[@"eventSubtype"] integerValue];
     switch (eventSubtype) {
     case UIEventSubtypeRemoteControlNextTrack:
     NSLog(@"下一首");
     break;
     case UIEventSubtypeRemoteControlPreviousTrack:
     NSLog(@"上一首");
     break;
     case  UIEventSubtypeRemoteControlPause:
     [self.player pause];
     break;
     case  UIEventSubtypeRemoteControlPlay:
     [self.player play];
     break;
     //耳机上的播放暂停
     case  UIEventSubtypeRemoteControlTogglePlayPause:
     NSLog(@"播放或暂停");
     break;
     //后退
     case UIEventSubtypeRemoteControlBeginSeekingBackward:
     break;
     case UIEventSubtypeRemoteControlEndSeekingBackward:
     NSLog(@"后退");
     break;
     //快进
     case UIEventSubtypeRemoteControlBeginSeekingForward:
     break;
     case UIEventSubtypeRemoteControlEndSeekingForward:
     NSLog(@"前进");
     break;
     default:
     break;
     }
     
     }];
     */
    
}

//展示锁屏歌曲信息：图片、歌词、进度、演唱者 播放速率
- (void)showLockScreenTotaltime:(float)totalTime andCurrentTime:(float)currentTime andRate:(NSInteger)rate andLyricsPoster:(BOOL)isShow{
    
    NSMutableDictionary * songDict = [[NSMutableDictionary alloc] init];
    //设置歌曲题目
    [songDict setObject:@"多幸运" forKey:MPMediaItemPropertyTitle];
    //设置歌手名
    [songDict setObject:@"韩安旭" forKey:MPMediaItemPropertyArtist];
    //设置专辑名
    [songDict setObject:@"专辑名" forKey:MPMediaItemPropertyAlbumTitle];
    //设置歌曲时长
    [songDict setObject:[NSNumber numberWithDouble:totalTime]  forKey:MPMediaItemPropertyPlaybackDuration];
    //设置已经播放时长
    [songDict setObject:[NSNumber numberWithDouble:currentTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    //设置播放速率
    //注意：MPNowPlayingInfoCenter的rate 与 self.player.rate 是不同步的，也就是说[self.player pause]暂停播放后的速率rate是0，但MPNowPlayingInfoCenter的rate还是1，就会造成 在锁屏界面点击了暂停按钮，这个时候进度条表面看起来停止了走动，但是其实还是在计时，所以再点击播放的时候，锁屏界面进度条的光标会发生位置闪动， 所以我们需要在暂停或播放时保持播放速率一致
    [songDict setObject:[NSNumber numberWithInteger:rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    UIImage * lrcImage = [UIImage imageNamed:@"backgroundImage5.jpg"];
    if (isShow) {
        
        //制作带歌词的海报
        if (!_lrcImageView) {
            _lrcImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 480,800)];
        }
        if (!_lockScreenTableView) {
            _lockScreenTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 800 - 44 * 7 + 20, 480, 44 * 3) style:UITableViewStyleGrouped];
            _lockScreenTableView.dataSource = self;
            _lockScreenTableView.delegate = self;
            _lockScreenTableView.separatorStyle = NO;
            _lockScreenTableView.backgroundColor = [UIColor clearColor];
            [_lockScreenTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
        }
        //主要为了把歌词绘制到图片上，已达到更新歌词的目的
        [_lrcImageView addSubview:self.lockScreenTableView];
        _lrcImageView.image = lrcImage;
        _lrcImageView.backgroundColor = [UIColor blackColor];
        
        //获取添加了歌词数据的海报图片
        UIGraphicsBeginImageContextWithOptions(_lrcImageView.frame.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [_lrcImageView.layer renderInContext:context];
        lrcImage = UIGraphicsGetImageFromCurrentImageContext();
        _lastImage = lrcImage;
        UIGraphicsEndImageContext();
        
    }else{
        if (_lastImage) {
            lrcImage = _lastImage;
        }
    }
    //设置显示的海报图片
    [songDict setObject:[[MPMediaItemArtwork alloc] initWithImage:lrcImage]
                 forKey:MPMediaItemPropertyArtwork];
    
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
    
}

#pragma mark -- Getter

- (UITableView *)tableView{
    
    if (_tableView == nil) {
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height ) style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        imageView.image = [UIImage imageNamed:@"backgroundImage5.jpg"];
        _tableView.backgroundView = imageView;
        _tableView.separatorStyle = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellID"];
        
    }
    
    return _tableView;
}

- (AVPlayer *)player{
    
    if (_player == nil) {
        NSString * path = [[NSBundle mainBundle] pathForResource:SONGNAME ofType:@"mp3"];
        _player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:path]];
    }
    return _player;
}



#pragma mark -- UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return _lrcArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    wslLrcEach * lrcEach = _lrcArray[indexPath.row];
    cell.textLabel.text = lrcEach.lrc;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    if (self.currentRow == indexPath.row) {
        cell.textLabel.textColor = [UIColor greenColor];
    }else{
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isDragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        _isDragging = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    _isDragging = NO;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    
}

- (void)dealloc{
    [self removeObserver];
}


- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait; //只支持这一个方向(正常的方向)
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
