//
//  wslAnalyzer.m
//  歌词解析1
//
//  Created by 王双龙 on 2017/6/5.
//  Copyright © 2017年 https://github.com/wslcmk All rights reserved.//

#import "wslAnalyzer.h"
#import "wslLrcEach.h"

@implementation wslAnalyzer

-(NSMutableArray *)lrcArray
{
    if (_lrcArray == nil) {
        _lrcArray = [[NSMutableArray alloc] init];
    }return _lrcArray;
}

-(NSMutableArray *)analyzerLrcByPath:(NSString *)path
{
    
    [self  analyzerLrc:[NSString   stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
    
    return self.lrcArray;
}

-(NSMutableArray *)analyzerLrcBylrcString:(NSString *)string{
    
    [self  analyzerLrc:string];
    
    return self.lrcArray;
}

//根据换行符\n分割字符串，获得包含每一句歌词的数组
-(void)analyzerLrc:(NSString *)lrcConnect
{
    
    NSArray *  lrcConnectArray = [lrcConnect   componentsSeparatedByString:@"\n"];
    
    NSMutableArray    *  lrcConnectArray1 =[[NSMutableArray  alloc] initWithArray: lrcConnectArray ];
    
    for (NSUInteger i = 0;  i < [lrcConnectArray1  count]  ;i++ ) {
        if ([lrcConnectArray1[i]   length] == 0 ) {
            [lrcConnectArray1  removeObjectAtIndex:i];
            i--;
        }
    }
    
    //    NSMutableArray * realLrcArray = [self  deleteNoUseInfo:lrcConnectArray1];
    [self    analyzerEachLrc:lrcConnectArray1];
    
}
//删除没有用的字符
-(NSMutableArray *)deleteNoUseInfo:(NSMutableArray *)lrcmArray
{
    for (NSUInteger i = 0; i < [lrcmArray count] ; i++)
    {
        unichar  ch = [lrcmArray[i] characterAtIndex:1];
        if(!isnumber(ch)){
            [lrcmArray removeObjectAtIndex:i];
            i--;
        }
    }
    return lrcmArray;
}

//解析每一行歌词字符，获得时间点和对应的歌词
-(void)analyzerEachLrc:(NSMutableArray *)lrcConnectArray
{
    for (NSUInteger i = 0;  i < [lrcConnectArray  count] ;  i++) {
        
        NSArray * eachLrcArray = [lrcConnectArray[i]   componentsSeparatedByString:@"]"];
        
        NSString * lrc = [eachLrcArray  lastObject];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df  setDateFormat:@"[mm:ss.SS"];
        
        NSDate * date1 = [df  dateFromString:eachLrcArray[0] ];
        NSDate *date2 = [df dateFromString:@"[00:00.00"];
        NSTimeInterval  interval1 = [date1  timeIntervalSince1970];
        NSTimeInterval  interval2 = [date2  timeIntervalSince1970];
        interval1 -= interval2;
        if (interval1 < 0) {
            interval1 *= -1;
        }
        
        //如果时间点对应的歌词为空就不加入歌词数组
        //        if (lrc.length == 0 || [lrc isEqualToString:@"\r"] || [lrc isEqualToString:@"\n"]) {
        //            continue;
        //        }
        wslLrcEach   * eachLrc = [[wslLrcEach alloc] init];
        eachLrc.lrc = lrc;
        eachLrc.time =  interval1;
        [self.lrcArray addObject:eachLrc];
        
    }
}



@end
