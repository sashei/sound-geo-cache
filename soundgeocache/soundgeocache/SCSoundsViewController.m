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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [_backButton setTitle:@"\U000025C0\U0000FE0E" forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    _dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateFormat:@"'at' HH:mm 'on' MM/dd/yyyy"];
}

- (void) viewWillAppear:(BOOL)animated {
    [_player stop];
    
    NSError *trash;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&trash];
    [[AVAudioSession sharedInstance] setActive: YES error: &trash];
    [[AVAudioSession sharedInstance] setDelegate:self];
}

- (void) viewWillDisappear:(BOOL)animated {
    NSError *trash;
    [_player stop];
    [[AVAudioSession sharedInstance] setActive: NO error: &trash];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadSounds:(NSMutableArray *)sounds  {
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"recordDate"
                                                                    ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    NSMutableArray *soundsSortedByTime = [NSMutableArray arrayWithArray:[sounds sortedArrayUsingDescriptors:sortDescriptors]];
    
    _sounds = soundsSortedByTime;
    [_tableView reloadData];
    _lastSelected = nil;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
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
    SCSound *sound = [_sounds objectAtIndex:indexPath.row];
    [cell.imageView setImage:[UIImage imageNamed:@"Play.png"]];
    NSLog(@"Date is: %@", [sound.recordDate descriptionWithLocale:[NSLocale currentLocale]]);
    [cell.textLabel setText:[_dateFormatter stringFromDate:sound.recordDate]];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CGPoint newCenter = cell.imageView.center;
    newCenter.x = 160;
    [cell.imageView setCenter:newCenter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        if (![_database executeUpdate:@"DELETE FROM paintings WHERE rowid=?", _paintings[indexPath.row][0]])
//            NSLog(@"Failure to delete at rowid %ld", (long)indexPath.row);
//        [_paintings removeObjectAtIndex:indexPath.row];
//        
//        NSLog(@"paintings has size: %lu", (unsigned long)[_paintings count]);
//        
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}


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
    if (_lastSelected != indexPath) {
        SCSound *sound = [_sounds objectAtIndex:indexPath.row];
        [_player stop];
        NSLog(@"URL is: %@", [sound soundURL]);
        
        [[tableView cellForRowAtIndexPath:_lastSelected].imageView setImage:[UIImage imageNamed:@"Play.png"]];
        
        _lastSelected = indexPath;
        
        NSError *playerError;
        NSData *data = [NSData dataWithContentsOfURL:[sound soundURL]];
        _player = [[AVAudioPlayer alloc] initWithData:data error:&playerError];
        if (playerError)
            NSLog(@"The player initializes with error: %@", playerError);
        else {
            _player.delegate = self;
            [_player setVolume:1.0];
            [_player prepareToPlay];
            [_player play];
        }
        
        [[tableView cellForRowAtIndexPath:indexPath].imageView setImage:[UIImage imageNamed:@"Pause.png"]];
    }
    else {
        if ([_player isPlaying]) {
            [_player pause];
            [[tableView cellForRowAtIndexPath:indexPath].imageView setImage:[UIImage imageNamed:@"Play.png"]];
        }
        else {
            [_player play];
            [[tableView cellForRowAtIndexPath:indexPath].imageView setImage:[UIImage imageNamed:@"Pause.png"]];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [[_tableView cellForRowAtIndexPath:_lastSelected].imageView setImage:[UIImage imageNamed:@"Play.png"]];
    _lastSelected = nil;
}




@end
