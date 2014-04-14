//
//  DataManager.m
//  FMDBExample
//
//  Created by Naoyuki Takura on 2014/04/13.
//  Copyright (c) 2014年 Naoyuki Takura. All rights reserved.
//

#import "DataManager.h"

static NSString * const DEFAULT_DB_PATH = @"my.db";

@interface DataManager()
@property (strong, nonatomic) FMDatabase *database;
@property (strong, nonatomic) FMDatabaseQueue *dbQueue;
@property (copy, nonatomic) NSString *dbFilePath;

-(void)p_initSchema;

@end

@implementation DataManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _database = nil;
        
        NSArray *domains = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *fullPath = domains[0];
        _dbFilePath = [[fullPath stringByAppendingPathComponent:DEFAULT_DB_PATH] copy];
        _database = [[FMDatabase alloc]initWithPath:_dbFilePath];
        //database queue
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbFilePath];

        [self p_initSchema];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _database = nil;
        NSArray *domains = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *fullPath = domains[0];
        _dbFilePath = [[fullPath stringByAppendingPathComponent:path] copy];
        _database = [[FMDatabase alloc]initWithPath:_dbFilePath];
        //database queue
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbFilePath];

        [self p_initSchema];
    }
    return self;
}

- (void)p_initSchema {
    //check db file is exist
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:_dbFilePath]) {
        //create schema
        if ([_database open]) {
            [_database executeUpdate:@"create table memo(id integer primary key autoincrement, contents text, 'update' integer)"];
            [_database close];
            
            NSLog(@"initialize database schema successfully.");
        }
    }
}

- (BOOL)open {
    //check database file exist
    NSLog(@"database file : %@", _dbFilePath);
    return [_database open];
}

- (void)close {
    [_database close];
}

- (BOOL)createNewContent:(NSString *)content {
    if ([_database goodConnection]) {
        [_database beginTransaction];
        [_database executeUpdate:@"insert into memo (contents, 'update') values (?, ?)", content, [NSDate date]];
        [_database commit];
        return YES;
    }
    return NO;
}

- (void)createNewContent:(NSString *)content completeHandler:(void (^)(BOOL))handler {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //
        __block BOOL ret = NO;
        [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            //dummy
            [NSThread sleepForTimeInterval:2.0f];
            //
            ret = [db executeUpdate:@"insert into memo (contents, 'update') values (?, ?)", content, [NSDate date]];
            if (!ret) {
                //error
                *rollback = YES;
            } else {
                *rollback = NO;
            }
            
        }];
        //callback on main queue
        dispatch_sync(dispatch_get_main_queue(), ^{
            //perform update UI on main thread.
            handler(ret);
        });

    });
}

- (NSArray *)allContents {
    if (![_database goodConnection]) {
        return nil;
    }
    NSMutableArray *contentsArray = [[NSMutableArray alloc]init];
    FMResultSet *rset = [_database executeQuery:@"select * from memo order by 'update'"];
    while ([rset next]) {
        NSInteger idValue = [[rset stringForColumnIndex:0] integerValue];
        NSString *contents = [rset stringForColumnIndex:1];
        NSDate *date = [rset dateForColumnIndex:2];
        NSDictionary *contentDic = @{@"id": @(idValue), @"contents": contents, @"update": date};
        
        [contentsArray addObject:contentDic];
    }
    [rset close];
    return [contentsArray copy];
}

- (BOOL)deleteRecordAtRowid:(NSInteger)rowid {
    if (![_database goodConnection]) {
        return NO;
    }
    
    [_database beginTransaction];
    [_database executeUpdate:@"delete from memo where id = ?", @(rowid)];
    [_database commit];
    return YES;
}


- (void) cleanDatabase {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_dbFilePath]) {
        //NOTICE!
        //delete db file
        [manager removeItemAtPath:_dbFilePath error:nil];
    }
}

@end
