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
            
            // Create the sounds bucket
            S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:SOUNDS_BUCKET andRegion:[S3Region USWest2]];
            S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];
            if(createBucketResponse.error != nil)
            {
                NSLog(@"Error: %@", createBucketResponse.error);
            }
        }
    }
    
    return self;
}

- (void) requestSoundsInRectWithCorners:(CLLocationCoordinate2D) topLeft and: (CLLocationCoordinate2D) bottomRight {
    
    //FIXME GET KEYS, put them in here
     NSMutableArray *keys;
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // THIS IS GOING TO INVOLVE some kind of call to the s3 database, to get the keys
        // for a given prefix. best to do it in here.
        

        dispatch_async(dispatch_get_main_queue(), ^{
            [self getSoundsForKeys:keys];
        });
    });
}

- (void) getSoundsForKeys:(NSMutableArray*) keys {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // hold the sounds we're getting
        NSMutableArray *sounds = [[NSMutableArray alloc] initWithCapacity:0];
        
        // Set the content type so that the browser will treat the URL as an image.
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        
        // FIXME TO CORRECT CONTENT TYPE
        override.contentType = @"image/jpeg";
        
        for (NSString* key in keys) {
            // Request a pre-signed URL to picture that has been uplaoded.
            S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
            gpsur.key                     = key;
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
                //FIXME GET THE LAT LON BACK FROM THE KEY
                
                
                //  AND THEN INSTANTIATE THIS SOUND OBJECT
                SCSound *temp;
                
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
        NSString *key = @"HELP";
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                                 inBucket:SOUNDS_BUCKET];
        // FIXME this should be the right content type for sound files
        por.contentType = @"image/jpeg";
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
- (int) makeKeyForLocation:(CLLocationCoordinate2D)location
{
    int key = 0;
    
    // we have the lat and lon
    int lat = location.latitude;
    int lon = location.longitude;
    NSLog(@"makeKeyForLocation : lat is %d", lat);
    
    // we format the lat and lon
    NSString *latString = [NSString stringWithFormat:@"%3d%.4d", lat, lat];
    NSString *lonString = [NSString stringWithFormat:@"%3d%.4d", lon, lon];
    NSLog(@"makeKeyForLocation : latString is %@", latString);
    
    
    return key;
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
