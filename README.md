# lyricsAnalysis
iOS音乐播放器之锁屏效果（仿网易云音乐和QQ音乐）+歌词解析
简书地址：http://www.jianshu.com/p/35ce7e1076d2
功能描述：锁屏歌曲信息、控制台远程控制音乐播放：暂停/播放、上一首/下一首、快进/快退、列表菜单弹框和拖拽控制台的进度条调节进度（结合了QQ音乐和网易云音乐在锁屏状态下的效果）、歌词解析并随音乐滚动显示。

![总效果预览图.gif](http://upload-images.jianshu.io/upload_images/1708447-a83f7e40b01e4f50.gif?imageMogr2/auto-orient/strip)

****
第一部分：锁屏效果包括：锁屏歌曲信息和远程控制音乐播放
① 锁屏歌曲信息显示
![锁屏信息预览](http://upload-images.jianshu.io/upload_images/1708447-72e0bb36ac035300.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
//展示锁屏歌曲信息：图片、歌词、进度、歌曲名、演唱者、专辑、（歌词是绘制在图片上的）
- (void)showLockScreenTotaltime:(float)totalTime andCurrentTime:(float)currentTime andLyricsPoster:(BOOL)isShow{
    
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
   //加入正在播放媒体的信息中心
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
    
}

```
****
② 远程控制音乐播放
![左侧列表菜单弹出框.PNG](http://upload-images.jianshu.io/upload_images/1708447-afcb25273e2ea214.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在此之前需先满足后台播放音乐的条件:
```
    //后台播放音频设置,需要在Capabilities->Background Modes中勾选Audio,Airplay,and Picture in Picture ，如下图1、2
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
```
![1.png](http://upload-images.jianshu.io/upload_images/1708447-db2d2d4cc57e27d0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![2.png](http://upload-images.jianshu.io/upload_images/1708447-7b19e1725fff23e0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在iOS7.1之前, App如果需要在锁屏界面开启和监控远程控制事件,可以通过重写- (void)remoteControlReceivedWithEvent:(UIEvent *)event这个方法来捕获远程控制事件，并根据event.subtype来判别指令意图并作出反应。具体用法如下：

```
//在具体的控制器或其它类中捕获处理远程控制事件,当远程控制事件发生时触发该方法, 该方法属于UIResponder类，iOS 7.1 之前经常用
- (void)remoteControlReceivedWithEvent:(UIEvent *)event{
    NSLog(@"%ld",event.type);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"songRemoteControlNotification" object:self userInfo:@{@"eventSubtype":@(event.subtype)}];
}

 /* iOS 7.1之前*/
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

```
  在iOS7.1之后，出现了MPRemoteCommandCenter、MPRemoteCommand 及其相关的一些类 ，锁屏界面开启和监控远程控制事件就更方便了，而且还扩展了一些新功能：网易云音乐的列表菜单弹框功能和QQ音乐的拖拽控制台的进度条调节进度功能等等.....
官方文档：https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter
```
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
    
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self.player play];
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
        CMTime totlaTime = self.player.currentItem.duration;
        MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
        [self.player seekToTime:CMTimeMake(totlaTime.value*playbackPositionEvent.positionTime/CMTimeGetSeconds(totlaTime), totlaTime.timescale) completionHandler:^(BOOL finished) {
        }];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    
}

-(void)skipBackwardEvent: (MPSkipIntervalCommandEvent *)skipEvent
{
    NSLog(@"快进了 %f秒", skipEvent.interval);
}

```
第二部分：歌词解析

![歌词样式.png](http://upload-images.jianshu.io/upload_images/1708447-285ef497840bff48.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

根据上图的歌词样式，思路就是：先根据换行符“\n“分割字符串，获得包含每一行歌词字符串的数组，然后解析每一行歌词字符，获得时间点和对应的歌词，再用创建的歌词对象wslLrcEach来存储时间点和歌词，最后得到一个存储wslLrcEach对象的数组。
 ```
//每句歌词对象
@interface wslLrcEach : NSObject
@property(nonatomic, assign) NSUInteger time ;
@property(nonatomic, copy) NSString * lrc ;
@end
```
接下来就是要让歌词随歌曲的进度来滚动显示,主要代码如下：
```
        self.tableView  显示歌词的
        currentTime  当前播放时间点
        self.currentRow  当前时间点歌词的位置

         //歌词滚动显示
            for ( int i = (int)(self.lrcArray.count - 1); i >= 0 ;i--) {
                wslLrcEach * lrc = self.lrcArray[i];
                if (lrc.time < currentTime) {
                    self.currentRow = i;
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: self.currentRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    [self.tableView reloadData];
                    break;
                }
            }
```

>* 更新于2017/9/13  iOS11系统正式发布后 ， iOS11上不能像iOS11以下那样锁屏歌词和海报，iOS11把海报显示位置放到了左上方，而且大小变成了头像大小，可能是苹果为了锁屏界面的简洁，只保留了如下图的界面。

![iOS11网易云音乐锁屏界面.PNG](http://upload-images.jianshu.io/upload_images/1708447-b928a71e1d44addb.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

>* 更新于2018/3/7 上面提到 iOS11系统上 ，不能像以往那样显示锁屏歌词了，那锁屏歌词该怎么显示呢，网易云音乐给出了如下图的设计：她是把当前唱到的歌词放到了锁屏的副标题处，随着播放的进度而改变。
```
    [songDict setObject:@"当前歌词" forKey:MPMediaItemPropertyAlbumTitle];
```

![网易云音乐锁屏歌词.PNG](http://upload-images.jianshu.io/upload_images/1708447-3da0ee93b6b68b8e.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

>* 更新于2018/8/2 
> 最近有小猿反应了一个Bug：锁屏下暂停播放,过几秒再继续播放,进度条会跳一下,暂停越久跳越猛?
> 查阅资料后发现：我们知道 player 有个 rate 属性，表示播放速率，为 0 的时候表示暂停，为 1.0 的时候表示播放，而MPNowPlayingInfoCenter的nowPlayingInfo也有一个键值MPNowPlayingInfoPropertyPlaybackRate表示速率rate，但是它 与 self.player.rate 是不同步的，也就是说[self.player pause]暂停播放后的速率rate是0，但MPNowPlayingInfoPropertyPlaybackRate还是1，就会造成 在锁屏界面点击了暂停按钮，这个时候进度条表面看起来停止了走动，但是其实还是在计时，所以再点击播放的时候，锁屏界面进度条的光标会发生位置闪动， 所以我们需要在监听播放状态时同步播放速率给MPNowPlayingInfoPropertyPlaybackRate。

```
 [songDict setObject:[NSNumber numberWithInteger:rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
```

## Welcome To Follow Me

>  您的follow和start，是我前进的动力，Thanks♪(･ω･)ﾉ
> * [简书](https://www.jianshu.com/u/e15d1f644bea)
> * [微博](https://weibo.com/5732733120/profile?rightmod=1&wvr=6&mod=personinfo&is_all=1)
> * [掘金](https://juejin.im/user/5c00d97b6fb9a049fb436288)
> * [CSDN](https://blog.csdn.net/wsl2ls)
> * QQ交流群：835303405

欢迎扫描下方二维码关注——iOS开发进阶之路——微信公众号：iOS2679114653
本公众号是一个iOS开发者们的分享，交流，学习平台，会不定时的发送技术干货，源码,也欢迎大家积极踊跃投稿，(择优上头条) ^_^分享自己开发攻城的过程，心得，相互学习，共同进步，成为攻城狮中的翘楚！

![iOS开发进阶之路.jpg](http://upload-images.jianshu.io/upload_images/1708447-c2471528cadd7c86.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![亲，赞一下，给个star.jpg](http://upload-images.jianshu.io/upload_images/1708447-60ad604d2d12e1da.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
