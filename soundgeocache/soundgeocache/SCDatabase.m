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
    if(![ACCESS_KEY_ID isEqualToString:@"CHANGE ME"]
       && self.s3 == nil)
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
        
        // Create the picture bucket.
        S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:[Constants pictureBucket] andRegion:[S3Region USWest2]];
        S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];
        if(createBucketResponse.error != nil)
        {
            NSLog(@"Error: %@", createBucketResponse.error);
        }
    }
}

+ (NSArray*) getSoundsInRectWithCorners:(CLLocationCoordinate2D) topLeft and: (CLLocationCoordinate2D) bottomRight {
    
}

+ (void)addSound:(NSData *) soundData withLocation:(CLLocationCoordinate2D)location;
{
    // run this in a background thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // make the key here
        NSString *key = @"HELP";
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                                 inBucket:SOUNDS_BUCKET];
        // fixme this should be something about sound files
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
                [self showAlertMessage:@"The image was successfully uploaded." withTitle:@"Upload Completed"];
            }
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    });
}

@end
