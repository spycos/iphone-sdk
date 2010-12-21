# Transloadit iPhone SDK

The transloadit iPhone SDK contains a sample iPhone project along with a
`TransloaditRequest` class that you can use in your own project.

<a href="https://github.com/transloadit/iphone-sdk/raw/master/Screenshots/device/1.png">
<img src="https://github.com/transloadit/iphone-sdk/raw/master/Screenshots/device/1.png" height="500">
</a>
<a href="https://github.com/transloadit/iphone-sdk/raw/master/Screenshots/device/2.png">
<img src="https://github.com/transloadit/iphone-sdk/raw/master/Screenshots/device/2.png" height="500">
</a>

## Getting started

The first thing you should do is edit the `Config.m` file that comes with the
project. You will need a [transloadit](http://transloadit.com/) account, as well
as a [template id](http://transloadit.com/docs/templates).

Once you have set this up, you can start the app and test some file
uploads.

## Using Transloadit in your own app

In order to use transloadit in your own app, you need to add the following
files to your project:

* `Classes/Transloadit/TransloaditRequest.h`
* `Classes/Transloadit/TransloaditRequest.m`

The `TransloaditRequest` class depends on two additional libraries that you
need to install separately:

* [json-framework](http://code.google.com/p/json-framework/wiki/InstallationInstructions) (New BSD License)
* [ASIHttpRequest](http://allseeing-i.com/ASIHTTPRequest/Setup-instructions) (BSD License)

## Examples

Assuming you have a UIImagePickerController callback, you can upload the selected
file like this:

	- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
	{
		TransloaditRequest *transload = [[TransloaditRequest alloc] initWithCredentials:@"your-key" secret:@"your-secret"];
		[transload setTemplateId:@"your-template-id"];
		[transload addPickedFile:info];
		[transload setNumberOfTimesToRetryOnTimeout:5];
		[transload setDelegate:self];
		[transload setUploadProgressDelegate:self];
		[transload startAsynchronous];
	}

	- (void)setProgress:(float)currentProgress
	{
		NSLog(@"upload progress: %f", currentProgress);
	}

	- (void)requestFinished:(TransloaditRequest *)transload
	{
		NSString *assemblyId = [[transload response] objectForKey:@"assembly_id"];
		NSLog(@"assembly id: %@", assemblyId);
		[transload release];
	}

If you need to pass dynamic `params` instead of just a template id, you can
tweak the example from above like this:

	// [transload setTemplateId:@"your-template-id"];
	NSMutableDictionary *steps = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *resizeStep = [[NSMutableDictionary alloc] init];
	[resizeStep setObject:@"/image/resize" forKey:@"robot"];
	[resizeStep setObject:[NSNumber numberWithInt:100] forKey:@"width"];
	[resizeStep setObject:[NSNumber numberWithInt:100] forKey:@"height"];
	[steps setObject:resizeStep forKey:@"resize"];
	[[transload params] setObject:steps forKey:@"steps"];

## TransloaditRequest API

### @property(nonatomic, retain) NSMutableDictionary \*params;

The `params` field with the instructions that will be send to transloadit.

### @property(nonatomic, retain) NSDictionary \*response;

The parsed [response](http://transloadit.com/docs/assemblies#response-format) from transloadit.

### - (id)initWithCredentials:(NSString \*)key secret:(NSString \*)secret;

Initializes a transloadit request with the given `key` and `secret`.

### - (void)addPickedFile:(NSDictionary \*)info;

Takes a picked file and prepares it for uploading. This can either be a video
or an image.

### - (void)addPickedFile:(NSDictionary \*)info forField:(NSString \*)field;

Same as the above, but you can specify the form field name to be used for this
upload.

### - (void)setTemplateId:(NSString \*)templateId;

Sets the `TransloaditRequest.params.template_id` property.

### - (bool)hadError;

Returns `true` if transloadit returned an error code.

## License

The Transloadit iPhone SDK is licensed under the MIT license. The dependencies
have their own licenses.
