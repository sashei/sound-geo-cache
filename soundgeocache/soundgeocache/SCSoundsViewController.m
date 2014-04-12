//
//  SCSoundsViewController.m
//  soundgeocache
//
//  Created by Rupert Deese on 4/12/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import "SCSoundsViewController.h"

@interface SCSoundsViewController ()

@end

@implementation SCSoundsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated {
    NSError *trash;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&trash];
    NSLog(@"The error is: %@", trash);
    [[AVAudioSession sharedInstance] setActive: YES error: &trash];
    [[AVAudioSession sharedInstance] setDelegate:self];
    NSLog(@"The error is: %@", trash);
}

- (void) viewWillDisappear:(BOOL)animated {
    NSError *trash;
    [[AVAudioSession sharedInstance] setActive: NO error: &trash];
    NSLog(@"The error is: %@", trash);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadSounds:(NSMutableArray *)sounds  {
    _sounds = sounds;
    [_tableView reloadData];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //NSLog(@"Length of scrapbook is %d", [_scrapbookData count]);
    return [_sounds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    PBPainting *temp = [_paintings objectAtIndex:indexPath.row][1];
    [cell.textLabel setTextAlignment:NSTextAlignmentRight];
    if (temp.solved) {
        [[cell imageView] setImage:temp.posterizedImage];
        [cell.textLabel setText:@"Replay"];
    }
    else {
        [[cell imageView] setImage:[UIImage imageNamed:@"qmark.png"]];
        [cell.textLabel setText:@"Play"];
    }
    
    [[cell imageView].layer setBorderWidth:6.0];
    [[cell imageView].layer setBorderColor:[[UIColor whiteColor] CGColor]];
    //[[cell imageView].layer setCornerRadius:10.0];
    [[cell imageView] setClipsToBounds:YES];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if (![_database executeUpdate:@"DELETE FROM paintings WHERE rowid=?", _paintings[indexPath.row][0]])
            NSLog(@"Failure to delete at rowid %ld", (long)indexPath.row);
        [_paintings removeObjectAtIndex:indexPath.row];
        
        NSLog(@"paintings has size: %lu", (unsigned long)[_paintings count]);
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Trying to get the painting at row %ld", (long)indexPath.row);
    _lastSelectedPaintingIndex = indexPath.row;
    _colorVC = [[PBColorViewController alloc] initWithPainting:[_paintings objectAtIndex:indexPath.row][1]];
    _colorVC.delegate = self;
    [self presentViewController:_colorVC animated:NO completion:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
