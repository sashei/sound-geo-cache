//
//  SCSoundsViewController.h
//  soundgeocache
//
//  Created by Rupert Deese on 4/12/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCSound.h"
#import <AVFoundation/AVFoundation.h>

@interface SCSoundsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property IBOutlet UITableView *tableView;
@property IBOutlet UIButton *backButton;
@property NSMutableArray *sounds;

- (void) loadSounds:(NSMutableArray*) sounds;

@end
