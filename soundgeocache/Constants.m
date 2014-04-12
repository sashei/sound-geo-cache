#import "Constants.h"

@implementation Constants


+(NSString *)pictureBucket
{
    return [[NSString stringWithFormat:@"%@-%@", PICTURE_BUCKET, ACCESS_KEY_ID] lowercaseString];
}

@end

