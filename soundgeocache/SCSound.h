//
//  SCSound.h
//  soundgeocache
//
//  Created by Rupert Deese on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SCSound : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property NSURL *soundURL;
@property NSDate *recordDate;

- (id) initWithLocation:(CLLocationCoordinate2D) loc andSoundURL:(NSURL*) url andDate:(NSDate*) date;

@end
