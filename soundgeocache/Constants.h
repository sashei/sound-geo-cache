#define TOKEN_VENDING_MACHINE_URL    @"http://echoanontvm.elasticbeanstalk.com"

/**
 * This indiciates whether or not the TVM is supports SSL connections.
 */
#define USE_SSL                      NO


#define CREDENTIALS_ALERT_MESSAGE    @"Please update the Constants.h file with your credentials or Token Vending Machine URL."
#define ACCESS_KEY_ID                @"USED-ONLY-FOR-TESTING"  // Leave this value as is.
#define SECRET_KEY                   @"USED-ONLY-FOR-TESTING"  // Leave this value as is.


// Constants for the Bucket and Object name.
#define SOUNDS_BUCKET  @"sounds-bucket"

#define CREDENTIALS_ERROR_TITLE    @"Missing Credentials"
#define CREDENTIALS_ERROR_MESSAGE  @"AWS Credentials not configured correctly.  Please review the README file."


@interface Constants:NSObject {
}

/**
 * Utility method to create a bucket name using the Access Key Id.  This will help ensure uniqueness.
 */

@end
