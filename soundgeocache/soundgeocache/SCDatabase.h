//
//  SCDatabase.h
//  soundgeocache
//
//  Created by Rupert Deese on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#define SOUNDS_BUCKET  @"sounds-bucket"

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AWSSimpleDB/AWSSimpleDB.h>
#import "SCSound.h"
#import <AWSS3/AWSS3.h>

@protocol SCDatabaseListener <NSObject>

- (void) receiveSounds:(NSMutableArray*) sounds;

@end

@interface SCDatabase : NSObject <AmazonServiceRequestDelegate>

@property AmazonS3Client *s3;
@property NSObject <SCDatabaseListener> *delegate;

- (void) requestSoundsInRectWithCorners:(CLLocationCoordinate2D) topLeft and: (CLLocationCoordinate2D) bottomRight;

- (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location;


- (int) makeKeyForLocation:(CLLocationCoordinate2D)location;
-(CLLocationCoordinate2D) getLocationFromKey:(int)key_int;
@end
