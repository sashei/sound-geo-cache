//
//  SCDatabase.m
//  soundgeocache
//
//  Created by Rupert Deese on 4/11/14.
//  Copyright (c) 2014 Sasha Heinen. All rights reserved.
//

#import "SCDatabase.h"
#import "Constants.h"
#import <AWSRuntime/AWSRuntime.h>


@implementation SCDatabase

- (id) init {
    self = [super init];
    
    if (self) {
        [AmazonClientManager s3];
        
//        if(self.s3 == nil)
//        {
//            // Initial the S3 Client.
//            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//            // This sample App is for demonstration purposes only.
//            // It is not secure to embed your credentials into source code.
//            // DO NOT EMBED YOUR CREDENTIALS IN PRODUCTION APPS.
//            // We offer two solutions for getting credentials to your mobile App.
//            // Please read the following article to learn about Token Vending Machine:
//            // * http://aws.amazon.com/articles/Mobile/4611615499399490
//            // Or consider using web identity federation:
//            // * http://aws.amazon.com/articles/Mobile/4617974389850313
//            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//            
//            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
//            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
//            
////            // Create the sounds bucket
////            S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:SOUNDS_BUCKET andRegion:[S3Region USWest2]];
////            S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];
////            if(createBucketResponse.error != nil)
////            {
////                NSLog(@"Error: %@", createBucketResponse.error);
////            }
//        }
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy.MM.dd,hh:mm:ss,a"];
    }
    
    return self;
}

- (void) requestSoundsNear:(CLLocationCoordinate2D) location {
    
    
    // The prefix for our search.
    NSString *prefix = [self getKeyPrefixFromLocation:location];
    
    NSLog(@"Sounds requested with prefix: %@", prefix);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        
        // THIS IS GOING TO INVOLVE some kind of call to the s3 database, to get the keys
        // for a given prefix. best to do it in here.
        
        
        S3ListObjectsRequest *listobjsr = [[S3ListObjectsRequest alloc] init];
        listobjsr.prefix = prefix;
        listobjsr.bucket = SOUNDS_BUCKET;
        //listobjsr.marker = prefix; // help! not gonna set it
        //listobjsr.maxKeys = 1000; // this is literally random
        //listobjsr.delimiter  // not setting this one for now.
        
        S3ListObjectsResponse *response = [[AmazonClientManager s3] listObjects:listobjsr];
        
        //NSLog(@"Response with error: %@, count: %lu", [response.error localizedDescription], (unsigned long)[response.listObjectsResult.objectSummaries count]);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self getSoundsForKeys:response.listObjectsResult.objectSummaries];
        });
    });
}

- (void) getSoundsForKeys:(NSMutableArray*) keys {
    
    NSLog(@"Getting sounds for keys");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // hold the sounds we're getting
        NSMutableArray *sounds = [[NSMutableArray alloc] initWithCapacity:0];
        
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        
        override.contentType = @"audio/mpeg";
        
        for (S3ObjectSummary* objSum in keys) {
            //NSLog(@"Key from getSounds for keys is: %@", objSum.key);
            
            // Request a pre-signed URL to picture that has been uplaoded.
            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
            gpsur.key                     = objSum.key;
            gpsur.bucket                  = SOUNDS_BUCKET;
            gpsur.expires                 = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
            gpsur.responseHeaderOverrides = override;
            
            // Get the URL
            NSError *error = nil;
            NSURL *url = [[AmazonClientManager s3] getPreSignedURL:gpsur error:&error];
            
            if(url == nil)
            {
                if(error != nil)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSLog(@"Error: %@", error);
                        [self showAlertMessage:[error.userInfo objectForKey:@"message"] withTitle:@"Browser Error"];
                    });
                }
            }
            else
            {
                //  AND THEN INSTANTIATE THIS SOUND OBJECT
                SCSound *temp = [[SCSound alloc] initWithLocation:[self getLocationFromKey:objSum.key] andSoundURL:url andDate:[self getDateFromKey:objSum.key]];
                [sounds addObject:temp];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate receiveSounds:sounds];
        });
    });
}

- (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location {
    // run this in a background thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSString *key = [self getKeyFromLocation:location andDate:[NSDate date]];
        CLLocationCoordinate2D loc2 = [self getLocationFromKey:key];
        NSLog(@"Adding a sound at location %f, %f. Key is: %@. Getting back the location: %f, %f.", location.latitude, location.longitude, key, loc2.latitude, loc2.longitude);
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                                 inBucket:SOUNDS_BUCKET];

        por.contentType = @"audio/mpeg";
        por.data        = soundData;
        
        // Put the image data into the specified s3 bucket and object.
        S3PutObjectResponse *putObjectResponse = [[AmazonClientManager s3] putObject:por];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(putObjectResponse.error != nil)
            {
                NSLog(@"Error: %@", putObjectResponse.error);
                [self showAlertMessage:[putObjectResponse.error.userInfo objectForKey:@"message"] withTitle:@"Upload Error"];
            }
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [_delegate uploadFinished];
        });
    });
}

// we use our gps coordinates for keys
- (NSString*) getKeyPrefixFromLocation:(CLLocationCoordinate2D)location {
    double latnum = location.latitude;
    double lonnum = location.longitude;
    
    int latpos = 0;
    if (latnum < 0) {
        latpos = 1;
        latnum *= -1;
    }
    int lonpos = 0;
    if (lonnum < 0) {
        lonpos = 1;
        lonnum *= -1;
    }
    
    NSString *lat = [NSString stringWithFormat:@"%09.5f",latnum];
    NSLog(@"Lat: %@", lat);
    NSString *lon = [NSString stringWithFormat:@"%09.5f",lonnum];
    NSLog(@"Lon: %@", lon);
    
    NSArray *latParts = [lat componentsSeparatedByString:@"."];
    NSArray *lonParts = [lon componentsSeparatedByString:@"."];
    
    NSString *keyPrefix = [NSString stringWithFormat:@"%d-%@-%d-%@", latpos, latParts[0], lonpos, lonParts[0]];
    
    return keyPrefix;
}

// we use our gps coordinates for keys
- (NSString*) getKeyFromLocation:(CLLocationCoordinate2D)location andDate:(NSDate *)date {
    double latnum = location.latitude;
    double lonnum = location.longitude;
    
    int latpos = 0;
    if (latnum < 0) {
        latpos = 1;
        latnum *= -1;
    }
    int lonpos = 0;
    if (lonnum < 0) {
        lonpos = 1;
        lonnum *= -1;
    }
    
    NSString *lat = [NSString stringWithFormat:@"%09.5f",latnum];
    NSLog(@"Lat: %@", lat);
    NSString *lon = [NSString stringWithFormat:@"%09.5f",lonnum];
    NSLog(@"Lon: %@", lon);
    
    NSArray *latParts = [lat componentsSeparatedByString:@"."];
    NSArray *lonParts = [lon componentsSeparatedByString:@"."];
    
    NSString *key = [NSString stringWithFormat:@"%d-%@-%d-%@-%@-%@-%@", latpos, latParts[0], lonpos, lonParts[0], latParts[1], lonParts[1], [_dateFormatter stringFromDate:date]];
    
    return key;
}

- (CLLocationCoordinate2D) getLocationFromKey:(NSString*) key
{
    NSArray *keyParts = [key componentsSeparatedByString:@"-"];
    double new_lat = [keyParts[1] intValue] + ([keyParts[4] intValue]/100000.0);
    if ([keyParts[0] intValue] == 1)
        new_lat *= -1;
    
    double new_lon = [keyParts[3] intValue] + ([keyParts[5] intValue]/100000.0);
    if ([keyParts[2] intValue] == 1)
        new_lon *= -1;
    
    CLLocationCoordinate2D location =CLLocationCoordinate2DMake(new_lat, new_lon);
    return location;
}

- (NSDate*) getDateFromKey:(NSString *)key {
    NSArray *keyParts = [key componentsSeparatedByString:@"-"];
//    NSLog(@"last part of key is: %@", [keyParts lastObject]);
//    if ([NSDate dateWithISO8061Format:[keyParts lastObject]] == nil)
//        NSLog(@"date is nil!");
//    NSLog(@"Date is: %@", [[NSDate alloc] initWith[keyParts lastObject]] descriptionWithLocale:[NSLocale currentLocale]]);
    
    return [_dateFormatter dateFromString:[keyParts lastObject]];
}


//- (*NSDate) getDateFromKey:(NSString*) key
//{
//    int key_int = [key integerValue];
//    
//    //get rid of last 3 (random) digits.
//    key_int = key_int / 1000;
//    
//    int date_int = key_int % (10^8)
//    
//}

- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
