//
//  wslAnalyzer.h
//  歌词解析1
//
//  Created by 王双龙 on 2017/6/5.
//  Copyright © 2017年 https://github.com/wslcmk All rights reserved.
//

#import <Foundation/Foundation.h>

@interface wslAnalyzer : NSObject

@property(nonatomic,strong)NSMutableArray * lrcArray;

//返回包含每一句歌词信息的数组
-(NSMutableArray *)analyzerLrcByPath:(NSString *)path;

-(NSMutableArray *)analyzerLrcBylrcString:(NSString *)string;

@end
