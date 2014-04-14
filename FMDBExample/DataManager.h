//
//  DataManager.h
//  FMDBExample
//
//  Created by Naoyuki Takura on 2014/04/13.
//  Copyright (c) 2014年 Naoyuki Takura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface DataManager : NSObject

- (instancetype)init;
- (instancetype)initWithPath:(NSString*)path;
- (BOOL)open;
- (void)close;
- (BOOL)createNewContent:(NSString*)content;
- (void)createNewContent:(NSString*)content completeHandler:(void (^)(BOOL result))handler;
- (BOOL)deleteRecordAtRowid:(NSInteger)rowid;
- (NSArray*)allContents;
- (void)cleanDatabase;

@end
