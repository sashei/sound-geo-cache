//
//  SCDatabase.h
//  soundgeocache
//
//  Created by Rupert Deese on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AWSSimpleDB/AWSSimpleDB.h>
#import <AWSS3/AWSS3.h>

#define SOUNDS_BUCKET  @"sounds-bucket"


@interface SCDatabase : NSObject <AmazonServiceRequestDelegate>

@property AmazonS3Client *s3;

- (NSArray*) getSoundsInRectWithCorners:(CLLocationCoordinate2D) topLeft and: (CLLocationCoordinate2D) bottomRight;

- (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location;


@end
