#import "IphoneSdkViewController.h"
#import "Config.h"
#import "JSON.h"

@implementation IphoneSdkViewController

@synthesize button, thumb, progressBar, spinner, status;

#pragma mark helpers

- (void)setThumbnail:(UIImagePickerController *)picker info:(NSDictionary *)info
{
	[progressBar setProgress:0.f];
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:@"public.image"]) {
		spinner.hidden = NO;
		spinner.hidesWhenStopped = YES;
		[spinner startAnimating];
		[self performSelectorInBackground:@selector(setImageThumbnail:) withObject:info];
	} else if ([mediaType isEqualToString:@"public.movie"]) {
		// getting a thumbnail for a video is tricky business, basically we are taking
		// a screenshot of the picker itself which is displaying the video right before it
		// gets closed. UIGraphicsBeginImageContext is not thread safe, so we need to do this
		// on the main thread.
		// see: http://www.iphonedevsdk.com/forum/iphone-sdk-development/24025-uiimagepickercontroller-videorecording-iphone-3gs.html
		CGSize thumbSize = CGSizeMake(picker.view.bounds.size.width, picker.view.bounds.size.height - 55);
		UIGraphicsBeginImageContext(thumbSize);
		[[picker.view layer] renderInContext:UIGraphicsGetCurrentContext()];
		thumb.image = UIGraphicsGetImageFromCurrentImageContext();
		thumb.hidden = NO;
		UIGraphicsEndImageContext();
		[spinner stopAnimating];
	}
}

- (void)setImageThumbnail:(NSDictionary *)info
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// sleep(1); // @todo remove before releasing

	UIImage *original = [info objectForKey:UIImagePickerControllerOriginalImage];
	UIImage *resized = [IphoneSdkViewController imageWithImage:original scaledToSizeWithSameAspectRatio:thumb.frame.size];
	[thumb performSelectorOnMainThread:@selector(setImage:) withObject:resized waitUntilDone:YES];
	[thumb performSelectorOnMainThread:@selector(setHidden:) withObject:NO waitUntilDone:NO];
	[spinner performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void)startUpload:(NSDictionary *)info
{
	spinner.hidden = YES;
	progressBar.hidden = NO;

	status.text = NSLocalizedString(@"preparing upload", @"");	

	transload = [[TransloaditRequest alloc] initWithCredentials:TransloaditKey secret:TransloaditSecret];
	[transload setTemplateId:TransloaditTemplateId];
	[transload addPickedFile:info];
	[transload setNumberOfTimesToRetryOnTimeout:5];
	[transload setDelegate:self];
	[transload setUploadProgressDelegate:self];
	[transload startAsynchronous];
}

- (void)requestFinished:(TransloaditRequest *)transloadRequest
{
	status.hidden = progressBar.hidden = YES;
	[button setTitle:NSLocalizedString(@"Select File", @"") forState:UIControlStateNormal];

	NSString *responseStatus;
	if ([transloadRequest hadError]) {
		responseStatus = [[transloadRequest response] objectForKey:@"error"];
	} else {
		responseStatus = [[transloadRequest response] objectForKey:@"ok"];
	}

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:responseStatus message:[transloadRequest responseString] delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil];

	[alert show];
	[alert release];
	[transload release];
	transload = nil;
	
	// hack to align text on the left
	((UILabel *)[[alert subviews] objectAtIndex:1]).textAlignment = UITextAlignmentLeft;
}

- (void)setProgress:(float)currentProgress
{
	status.text = NSLocalizedString(@"uploading file", @"");	
	[progressBar setProgress:currentProgress];
}

// see: http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;
{  
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
		
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }     
	
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
	
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
	
    CGContextRef bitmap;
	
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
    }   
	
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
		
        CGContextRotateCTM (bitmap, 90 * (3.1415927/180.0));
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
		
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
		
        CGContextRotateCTM (bitmap, -90 * (3.1415927/180.0));
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
		
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, -180. * (3.1415927/180.0));
    }
	
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
	
    CGContextRelease(bitmap);
    CGImageRelease(ref);
	
    return newImage; 
}

#pragma mark actions

- (IBAction)buttonTouch
{
	if (transload) {
		[transload cancel];
		[button setTitle:NSLocalizedString(@"Select File", @"") forState:UIControlStateNormal];
		[transload release];
		transload = nil;
		progressBar.hidden = status.hidden = YES;
		thumb.hidden = YES;
		[spinner stopAnimating];
		return;
	}

	// Pops up the image picker showing al available images and videos
	thumb.hidden = YES;
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
	picker.delegate = self;
	[self presentModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	spinner.hidden = status.hidden = NO;
	[spinner startAnimating];

	status.text = NSLocalizedString(@"generating thumb", @"");
	[button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];

	[self setThumbnail:picker info:info];
	[self startUpload:info];

	[picker dismissModalViewControllerAnimated:YES];
	[picker release];
}

#pragma mark controller
- (void) viewDidLoad
{
	[button setTitle:NSLocalizedString(@"Select File", @"") forState:UIControlStateNormal];

	if ([TransloaditKey length] == 0 || [TransloaditSecret length] == 0 || [TransloaditTemplateId length] == 0) {
		UIAlertView *error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Bad config", @"") message:NSLocalizedString(@"Please edit the Config.h file and insert your transloadit credentials.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil];
		[error show];
		[error release];
	}
}

- (void) dealloc
{
	[status release];
	[progressBar release];
	[button release];
	[thumb release];
    [super dealloc];
}


@end
