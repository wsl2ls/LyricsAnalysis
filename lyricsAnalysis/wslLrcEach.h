//
//  wslLrcEach.h
//
//  Created by 王双龙 on 2017/6/5.
//  Copyright © 2017年 https://github.com/wslcmk All rights reserved.
//

#import <Foundation/Foundation.h>

//每句歌词对象
@interface wslLrcEach : NSObject
@property(nonatomic,assign) NSUInteger time;
@property(nonatomic,copy)NSString * lrc;

@end
