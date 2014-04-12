//
//  SCSoundTableViewCell.h
//  soundgeocache
//
//  Created by Rupert Deese on 4/12/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SCSound.h"

@interface SCSoundTableViewCell : UITableViewCell <AVAudioPlayerDelegate>
@property AVAudioPlayer *audioPlayer;

- (id) initWithSound:(SCSound*) sound;

- (void) togglePlay;

@end
