#define ACCESS_KEY_ID          @"nooo"
#define SECRET_KEY             @"whaaat"


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
