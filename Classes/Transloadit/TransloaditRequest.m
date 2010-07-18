#import <CommonCrypto/CommonHMAC.h>

#import "TransloaditRequest.h"
#import "JSON.h"

@implementation TransloaditRequest
@synthesize params, response;

#pragma mark public

- (id)initWithCredentials:(NSString *)key secret:(NSString *)secretKey
{
	NSURL *serviceUrl = [NSURL URLWithString:@"http://api2.transloadit.com/assemblies?pretty=true"];
	[super initWithURL:serviceUrl];

	params = [[NSMutableDictionary alloc] init];
	secret = secretKey;

	NSMutableDictionary *auth = [[NSMutableDictionary alloc] init];
	[auth setObject:key forKey:@"key"];
	[params setObject:auth forKey:@"auth"];
	[auth release];

	return self;
}

- (void)addPickedFile:(NSDictionary *)info
{
	uploads++;
	NSString *field = [NSString stringWithFormat:@"upload_%i", uploads];
	[self addPickedFile:info forField:field];
}

- (void)addPickedFile:(NSDictionary *)info forField:(NSString *)field;
{
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

	if ([mediaType isEqualToString:@"public.image"]) {
		backgroundTasks++;
		NSMutableDictionary *file = [[NSMutableDictionary alloc] init];
		[file setObject:info forKey:@"info"];
		[file setObject:field forKey:@"field"];
		[self performSelectorInBackground:@selector(saveImageToDisk:) withObject:file];
	} else if ([mediaType isEqualToString:@"public.movie"]) {
		NSURL *fileUrl = [info valueForKey:UIImagePickerControllerMediaURL];
		NSString *filePath = [fileUrl path];
		[self setFile:filePath withFileName:@"iphone_video.mov" andContentType: @"video/quicktime" forKey:field];
	}
}

- (void)startAsynchronous
{
	readyToStart = YES;
	if (backgroundTasks) {
		return;
	}

	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateFormat:@"yyyy-MM-dd HH:mm-ss 'GMT'"];

	NSDate *localExpires = [[NSDate alloc] initWithTimeIntervalSinceNow:60*60];
	NSTimeInterval timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
	NSTimeInterval gmtTimeInterval = [localExpires timeIntervalSinceReferenceDate] - timeZoneOffset;
	NSDate *gmtExpires = [NSDate dateWithTimeIntervalSinceReferenceDate:gmtTimeInterval];

	[[params objectForKey:@"auth"] setObject:[format stringFromDate:gmtExpires] forKey:@"expires"];
	[localExpires release];
	[format release];

	NSString *paramsField = [params JSONRepresentation];
	NSString *signatureField = [TransloaditRequest stringWithHexBytes:[TransloaditRequest hmacSha1withKey:secret forString:paramsField]];
	
	[self setPostValue:paramsField forKey:@"params"];
	[self setPostValue:signatureField forKey:@"signature"];
	[super startAsynchronous];
}

- (void)setTemplateId:(NSString *)templateId
{
	[params setObject:templateId forKey:@"template_id"];
}

- (void)requestFinished
{
	response = [[self responseString] JSONValue];
	[response retain];
	[super requestFinished];
}

- (bool)hadError
{
	if ([response objectForKey:@"error"]) {
		return true;
	}
	return false;
}

#pragma mark private
- (void)saveImageToDisk:(NSMutableDictionary *)file
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *tmpFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"transloadfile" stringByAppendingString:[[NSProcessInfo processInfo] globallyUniqueString]]];	
	UIImage *image = [[file objectForKey:@"info"] objectForKey:@"UIImagePickerControllerOriginalImage"];
	[UIImageJPEGRepresentation(image, 0.9f) writeToFile:tmpFile atomically:YES];
	[file setObject:tmpFile forKey:@"path"];
	[self performSelectorOnMainThread:@selector(addImageFromDisk:) withObject:file waitUntilDone:NO];

	[pool release];
}

- (void)addImageFromDisk:(NSMutableDictionary *)file
{
	[self setFile:[file objectForKey:@"path"] withFileName:@"iphone_image.jpg" andContentType: @"image/jpeg" forKey:[file objectForKey:@"field"]];
	backgroundTasks--;
	if (readyToStart) {
		[self startAsynchronous];
	}
	[file release];
}

// from: http://stackoverflow.com/questions/476455/is-there-a-library-for-iphone-to-work-with-hmac-sha-1-encoding
+ (NSData *)hmacSha1withKey:(NSString *)key forString:(NSString *)string
{
	NSData *clearTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

// from: http://notes.stripsapp.com/nsdata-to-nsstring-as-hex-bytes/
+ (NSString *)stringWithHexBytes:(NSData *)data
{
	static const char hexdigits[] = "0123456789abcdef";
	const size_t numBytes = [data length];
	const unsigned char* bytes = [data bytes];
	char *strbuf = (char *)malloc(numBytes * 2 + 1);
	char *hex = strbuf;
	NSString *hexBytes = nil;
	
	for (int i = 0; i<numBytes; ++i) {
		const unsigned char c = *bytes++;
		*hex++ = hexdigits[(c >> 4) & 0xF];
		*hex++ = hexdigits[(c ) & 0xF];
	}
	*hex = 0;
	hexBytes = [NSString stringWithUTF8String:strbuf];
	free(strbuf);
	return hexBytes;
}

- (void)dealloc
{
	[super dealloc];
	[params release];
	[response release];
	[secret release];
}

@end
