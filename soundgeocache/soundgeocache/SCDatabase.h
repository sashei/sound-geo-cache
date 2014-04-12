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

- (void) requestSoundsNear:(CLLocationCoordinate2D) location;

- (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location;


- (NSString*) getKeyFromLocation:(CLLocationCoordinate2D)location;
-(CLLocationCoordinate2D) getLocationFromKey:(NSString*)key;
@end
