//
//  TableViewController.m
//  FMDBExample
//
//  Created by Naoyuki Takura on 2014/04/13.
//  Copyright (c) 2014年 Naoyuki Takura. All rights reserved.
//

#import "TableViewController.h"
#import "DataManager.h"

@interface TableViewController ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createNewRecordItem;
@property (strong, nonatomic) DataManager *dataManager;
@property (strong, nonatomic) NSArray *allContents; //cached.

- (IBAction)createNewRecordAction:(id)sender;
@end

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _dataManager = [[DataManager alloc]init];
    //open database. database opened until diappear view controller.
    [_dataManager open];
    
    //all contents that will be cached.
    self.allContents = [_dataManager allContents];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (_dataManager) {
        [_dataManager close];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *allContents = [_dataManager allContents];
    
    // Return the number of rows in the section.
    return [allContents count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *dict = [_allContents objectAtIndex:indexPath.row];
    cell.textLabel.text = dict[@"contents"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    cell.detailTextLabel.text = [formatter stringFromDate:dict[@"update"]];
    cell.tag = [dict[@"id"] integerValue];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        //delete database
        [_dataManager deleteRecordAtRowid:cell.tag];
        //update cache
        self.allContents = [_dataManager allContents];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (IBAction)createNewRecordAction:(id)sender {
    //show alertview
    UIAlertView *alertView =
        [[UIAlertView alloc]initWithTitle:@"new record"
                                  message:@"input new contents."
                                 delegate:self
                        cancelButtonTitle:@"cancel"
                        otherButtonTitles:@"ok", @"ok(background)", nil
         ];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    UITextField *field = [alertView textFieldAtIndex:0];
    
    switch (buttonIndex) {
        case 0:
            //cancel
            break;

        case 1:
            //ok
            //new record
            [_dataManager createNewContent:field.text];
            //update cache
            self.allContents = [_dataManager allContents];
            //reload tableview
            [self.tableView reloadData];
            
            break;
            
        case 2:
            //ok(background)
            {
                self.title = @"now update...";
                [_dataManager createNewContent:field.text completeHandler:^(BOOL result) {
                    //
                    NSLog(@"result: %d", result);
                    //update cache
                    self.allContents = [_dataManager allContents];
                    //reload tableview
                    [self.tableView reloadData];
                    
                    self.title = @"FMDB Example";
                }];
            }
            break;

        default:
            break;
    }
}
@end
