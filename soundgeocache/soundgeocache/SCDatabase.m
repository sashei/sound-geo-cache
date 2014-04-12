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
        if(self.s3 == nil)
        {
            // Initial the S3 Client.
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // This sample App is for demonstration purposes only.
            // It is not secure to embed your credentials into source code.
            // DO NOT EMBED YOUR CREDENTIALS IN PRODUCTION APPS.
            // We offer two solutions for getting credentials to your mobile App.
            // Please read the following article to learn about Token Vending Machine:
            // * http://aws.amazon.com/articles/Mobile/4611615499399490
            // Or consider using web identity federation:
            // * http://aws.amazon.com/articles/Mobile/4617974389850313
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            
            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
            
//            // Create the sounds bucket
//            S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:SOUNDS_BUCKET andRegion:[S3Region USWest2]];
//            S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];
//            if(createBucketResponse.error != nil)
//            {
//                NSLog(@"Error: %@", createBucketResponse.error);
//            }
        }
    }
    
    return self;
}

- (void) requestSoundsNear:(CLLocationCoordinate2D) location {
    
    
    // The prefix for our search.
    NSString *prefix = [[self getKeyFromLocation:location] substringToIndex:8];
    
    NSLog(@"Sounds requested with prefix: %@", prefix);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
//        S3ListObjectsRequest * listObjectsRequest = [[[S3ListObjectsRequest alloc] init] autorelease];
//        listObjectsRequest.bucket = @"same bucket as above";
//        listObjectsRequest.prefix = self.prevailStore.prov;
//        for (S3ObjectSummary * summary in [s3 listObjects:listObjectsRequest].listObjectsResult.objectSummaries)
        
        // THIS IS GOING TO INVOLVE some kind of call to the s3 database, to get the keys
        // for a given prefix. best to do it in here.
        
        
        S3ListObjectsRequest *listobjsr = [[S3ListObjectsRequest alloc] init];
        listobjsr.prefix = prefix;
        listobjsr.bucket = SOUNDS_BUCKET;
        //listobjsr.marker = prefix; // help! not gonna set it
        //listobjsr.maxKeys = 1000; // this is literally random
        //listobjsr.delimiter  // not setting this one for now.
        
        S3ListObjectsResponse *response = [_s3 listObjects:listobjsr];
        
        NSLog(@"Response with error: %@, count: %lu", [response.error localizedDescription], (unsigned long)[response.listObjectsResult.objectSummaries count]);

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
            NSLog(@"Key from getSounds for keys is: %@", objSum.key);
            
            // Request a pre-signed URL to picture that has been uplaoded.
            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
            gpsur.key                     = objSum.key;
            gpsur.bucket                  = SOUNDS_BUCKET;
            gpsur.expires                 = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600]; // Added an hour's worth of seconds to the current time.
            gpsur.responseHeaderOverrides = override;
            
            // Get the URL
            NSError *error = nil;
            NSURL *url = [self.s3 getPreSignedURL:gpsur error:&error];
            
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
                SCSound *temp = [[SCSound alloc] initWithLocation:[self getLocationFromKey:objSum.key] andSoundURL:url];
                [sounds addObject:temp];
            }
        }
        
        [_delegate receiveSounds:sounds];
    });
}

- (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location;
{
    // run this in a background thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // FIXME make the key here
        NSString *key = [self getKeyFromLocation:location];
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                                 inBucket:SOUNDS_BUCKET];

        por.contentType = @"audio/mpeg";
        por.data        = soundData;
        
        // Put the image data into the specified s3 bucket and object.
        S3PutObjectResponse *putObjectResponse = [_s3 putObject:por];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(putObjectResponse.error != nil)
            {
                NSLog(@"Error: %@", putObjectResponse.error);
                [self showAlertMessage:[putObjectResponse.error.userInfo objectForKey:@"message"] withTitle:@"Upload Error"];
            }
            else
            {
                [self showAlertMessage:@"The sound was successfully uploaded." withTitle:@"Upload Completed"];
            }
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    });
}

// we use our gps coordinates for keys
- (NSString*) getKeyFromLocation:(CLLocationCoordinate2D)location
{
    
    // CAUTION : this should be at the top of the file.
    int accuracy_rating = 10000;
    
    int lat_sign = 0;
    if (location.latitude > 0) lat_sign=1;
    int lon_sign = 0;
    if (location.longitude > 0) lon_sign=1;
    
    int lat_front = abs((int)location.latitude);
    int lat_back = abs((int)((location.latitude - lat_front) * accuracy_rating));
    int lon_front = abs((int)location.longitude);
    int lon_back = abs((int)((location.longitude - lon_front) * accuracy_rating));
    
    NSString *lat_front_string = [NSString stringWithFormat:@"%03d", lat_front];
    NSString *lon_front_string = [NSString stringWithFormat:@"%03d", lon_front];
    
    NSDate *now = [[NSDate alloc] init];
    
    //Random numbers for good measure.
    uint64_t n1 = arc4random_uniform(10);
    uint64_t n2 = arc4random_uniform(10);
    uint64_t n3 = arc4random_uniform(10);
    if (n3 == 0) n3= 2;
    int random_key_end = n1 + (n2*10) + (n3*100);
    
    NSString *key = [[NSString alloc] initWithFormat:@"%d%@%d%@%d%d%@%d",lat_sign, lat_front_string, lon_sign, lon_front_string, lat_back, lon_back, now.dateStamp, random_key_end ];
    
    //NSLog(@"key variable is %@", key);
    
    return key;
}

- (CLLocationCoordinate2D) getLocationFromKey:(NSString*) key
{
    
    int key_int = [key intValue];
    
    // CAUTION : this should be at the top of the file.
    int accuracy_rating = 10000;
    
    // get lat and lon from key
    
    int new_lat_sign = [[[key substringFromIndex:0] substringToIndex:1] integerValue];
    int new_lat_front = [[[key substringFromIndex:1] substringToIndex:3] integerValue];
    int new_lon_sign = [[[key substringFromIndex:4] substringToIndex:1] integerValue];
    int new_lon_front = [[[key substringFromIndex:5] substringToIndex:3] integerValue];

    // The date is the last 8 digits. 3 Random digits at the end of the key.
    int new_lon_back = (key_int / 10^11) % accuracy_rating;
    int new_lat_back = ((key_int / 10^11) % accuracy_rating) % accuracy_rating;
    
    double new_lat = new_lat_front + ((double)new_lat_back / accuracy_rating);
    double new_lon = new_lon_front + ((double)new_lon_back / accuracy_rating);
    
    if (new_lat_sign == 0) new_lat = new_lat * (-1);
    if (new_lon_sign == 0) new_lon = new_lon * (-1);
    
//    NSLog(@"New latitude is %f", new_lat);
//    NSLog(@"New longitude is %f", new_lon);
    
    CLLocationCoordinate2D location =CLLocationCoordinate2DMake(new_lat, new_lon);
    return location;
}

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
