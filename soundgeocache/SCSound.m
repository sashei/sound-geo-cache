//
//  SCSound.m
//  soundgeocache
//
//  Created by Rupert Deese on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import "SCSound.h"

@implementation SCSound 

- (id) initWithLocation:(CLLocationCoordinate2D) loc andSoundURL:(NSURL*) url andDate:(NSDate *)date {
    self = [super init];
    if (self) {
        _coordinate = loc;
        _soundURL = url;
        _recordDate = date;
        NSLog(@"Date is: %@", [date descriptionWithLocale:[NSLocale currentLocale]]);
    }
    return self;
}

@end
