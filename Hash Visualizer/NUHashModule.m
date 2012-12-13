//
//  NUHashModule.m
//  Hash Visualizer
//
//  Created by Chris Stroud on 12/4/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import "NUHashModule.h"
#import "NUPreferencesWindow.h"

@implementation NUHashModule

// The default base range value for a lottery ticket cell
#define TICKET_CELL_VALUE_RANGE_MIN 1

/***** Globals *****/

CGSize imageSizeInternal;
NSImage *hashImage;
NSImage *bucketImage;

CGFloat scaledHeight;
CGPoint *hash_point_list;
CGPoint *bucket_point_list;
CGPoint point_null;

dispatch_queue_t mainQueue;
dispatch_queue_t ticketGeneratorQueue;
dispatch_queue_t ticketProcessorQueue;
dispatch_queue_t interfaceUpdatingQueue;
dispatch_group_t interfaceUpdatingGroup;
dispatch_group_t ticketProcessorGroup;

CGColorSpaceRef deviceColorSpace;

NSArray *_dictData;
NSURL *dictionaryPath, *previousDictionaryPath;

unsigned long long int totalCount;
unsigned long long int outputTally;
unsigned long long int *bucketList;
unsigned long long int tableLength;
unsigned long long int numberOfInputs;
unsigned long long int maxHashValue;
unsigned int _ticketMax;

BOOL cancelOperations;

/**
 * Overridden initializer
 * Allows for the configuration of various default parameters
 *
 * @return Self instance
 */
- (id)init
{
	// Call super init and assign it to self
	self = [super init];
	if(self){

		// Set default values for our globals
		cancelOperations = NO;
		_delegate = nil;
		_hashingMechanism = NUHashGenerationMechanismNoneSelected;
		imageSizeInternal = NSZeroSize;
		point_null = CGPointMake(-1, -1);

		// Substribe for preference update notifications, which are broadcasted from the preferences window controller
		[(NSNotificationCenter*)[NSNotificationCenter defaultCenter] addObserver:self
																		selector:@selector(updateParameters:)
																			name:NUPreferencesUpdatedNotification
																		  object:nil];
	}
	
	return self;
}

/**
 * Handler method for NSNotificationCenter
 * Method is invoked any time preferences are updated
 *
 * @param note The notification object
 */
- (void)updateParameters:(NSNotification*)note
{
	// Store a reference to defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// Update the globals based on the current values
	dictionaryPath  =  [defaults URLForKey:NUPreferencesDictionaryPathKey];
	_queueSize      = [[defaults objectForKey:NUPreferencesQueueSizeKey]       unsignedIntValue];
	_pointSize      = [[defaults objectForKey:NUPreferencesPointSizeKey]       unsignedIntValue];
	_resolution     = [[defaults objectForKey:NUPreferencesResolutionKey]      unsignedIntValue];
	_ticketMax      = [[defaults objectForKey:NUPreferencesTicketCellMaxKey]   unsignedIntValue];
	tableLength		= [[defaults objectForKey:NUPreferencesHashTableLengthKey] unsignedLongLongValue];

	// Set the image size
	[self setImageSize:_imageSize];

	// Get the scaled height from that resolution-dependant image size
	scaledHeight    = imageSizeInternal.height * [[defaults objectForKey:NUPreferencesBucketHeightKey]    floatValue];

	// Notify the delegate that the number of inputs (potentially) changed
	if(_delegate){
		[_delegate numberOfInputsChanged:[self numberOfInputs]];
	}
}

/**
 * Clears a given NSImage and paints a white overlay onto it
 *
 * @param image The image to clear
 */
- (void)clearImage:(NSImage *)image
{
	// If there is no image, bail
	if(!image){
		return;
	}

	// Fetch the device color space if it isn't already stored
	if(!deviceColorSpace){
		deviceColorSpace = CGColorSpaceCreateDeviceRGB();
	}

	// Lock onto the image and paint it white
	[image lockFocus];
	NSGraphicsContext *hash_context = [NSGraphicsContext currentContext];
	CGContextRef hash_contextRef = [hash_context graphicsPort];
	CGFloat components[4] = {1.0f, 1.0f, 1.0f, 1.0f};
	CGColorRef whiteColor = CGColorCreate(deviceColorSpace, components);
	CGContextSetFillColorWithColor(hash_contextRef, whiteColor);
	CGContextFillRect(hash_contextRef, CGRectMake(0.0, 0.0, imageSizeInternal.width, imageSizeInternal.height));
	[image unlockFocus];

	// Clean up
	CGColorRelease(whiteColor);
}

/**
 *
 * Prepares everything for computations
 *
 */
- (void)prepareForComputations
{
	// Update parameters so that the most current information is pulled from defaults
	[self updateParameters:nil];

	// Ensure a delegate is configured
	if(!_delegate){

		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:[NSString stringWithFormat:@"No Delegate set"]
									 userInfo:nil];
		
	}

	// Ensure that an image size is set
	if(NSEqualSizes(imageSizeInternal, NSZeroSize)){

		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:[NSString stringWithFormat:@"No Image Size set"]
									 userInfo:nil];
	}

	// Ensure that a hashing mechanism is set
	if(_hashingMechanism == NUHashGenerationMechanismNoneSelected){

		@throw [NSException exceptionWithName:NSInternalInconsistencyException
									   reason:[NSString stringWithFormat:@"No Hash Mechanism Selected"]
									 userInfo:nil];
	}

	// If the hash point list isn't null, free it
	if(hash_point_list){
		free(hash_point_list);
		hash_point_list = NULL;
	}

	// If the bucket point list isn't null, free it
	if(bucket_point_list){
		free(bucket_point_list);
		bucket_point_list = NULL;
	}

	// Allocate fresh space for the lists
	hash_point_list   = calloc(_queueSize, sizeof(struct CGPoint));
	bucket_point_list = calloc(_queueSize, sizeof(struct CGPoint));

	// Reset the tallys
	outputTally = 0;
	totalCount  = 0;

	// Setup the hash and bucket images and clear them
	hashImage    = [[NSImage alloc] initWithSize:imageSizeInternal];
	bucketImage  = [[NSImage alloc] initWithSize:imageSizeInternal];
	[self clearImage:bucketImage];
	[self clearImage:hashImage];

	// Assign the main queue to the global (for convenience)
	mainQueue = dispatch_get_main_queue();

	// Construct all the groups and queues
	ticketProcessorGroup   = dispatch_group_create();
	interfaceUpdatingGroup = dispatch_group_create();
	ticketGeneratorQueue   = dispatch_queue_create("edu.ncsu.clstroud.ticket_generator_queue",   0);
	ticketProcessorQueue   = dispatch_queue_create("edu.ncsu.clstroud.ticket_processor_queue",   0);
	interfaceUpdatingQueue = dispatch_queue_create("edu.ncsu.clstroud.interface_updating_queue", 0);

	// Store the hash table length, number of inputs, etc. so that the methods aren't called repeatedly
	tableLength    = [self hashTableLength];
	numberOfInputs = [self numberOfInputs];
	maxHashValue   = [self maxHashValue];

	// Setup the bucket list
	bucketList     = calloc(tableLength, sizeof(unsigned long long));
}

/**
 * Dealloc for cleanup
 */
- (void)dealloc
{
	// Remove self from the notification center
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// Free all the lists
	if(bucketList)free(bucketList);
	if(hash_point_list)free(hash_point_list);
	if(bucket_point_list)free(bucket_point_list);
}

/**
 * Called when the current running task should be cancelled
 */
- (void)cancelComputations
{
	cancelOperations = YES;
}

/**
 * Called when the queue is full and the images should be drawn
 */
- (void)updateInterfaceComponents
{
	// Wait for any lingering tickets to process
	dispatch_group_wait(ticketProcessorGroup,  DISPATCH_TIME_FOREVER);
	
	// Dispatch the interface updating block
	dispatch_group_async(interfaceUpdatingGroup, interfaceUpdatingQueue, ^{

		// Lock the image for drawing
		[hashImage lockFocus];

		// Store references to the contexts
		NSGraphicsContext *hash_context = [NSGraphicsContext currentContext];
		CGContextRef hash_ctx = [hash_context graphicsPort];

		// Loop through all items in the array of points
		for (unsigned int i = 0; i < _queueSize ; i++) {

			// Store the point
			CGPoint aPoint = hash_point_list[i];

			// Ensure the point isn't "null"
			if(!CGPointEqualToPoint(aPoint, point_null)){

				// Get the ratio on the y axis, which tells us the color
				CGFloat yRatio_local = aPoint.y / imageSizeInternal.height;

				// Create a color with that hue
				NSColor *theColor = [NSColor colorWithCalibratedHue:yRatio_local saturation:.8 brightness:1.0 alpha:1.0];

				// Set that color as the context fill color
				CGContextSetFillColorWithColor(hash_ctx, theColor.CGColor);

				// Create a rectangle in which to draw an ellipse for the point
				CGRect circlePoint = CGRectMake((int)aPoint.x, (int)aPoint.y, _pointSize, _pointSize);

				// Draw the point
				CGContextFillEllipseInRect(hash_ctx, circlePoint);

				// Nullify that point in the array
				hash_point_list[i] = point_null;

			}

		}

		// Unlock the image since editing is finished
		[hashImage unlockFocus];


		// Lock the image for drawing
		[bucketImage lockFocus];

		// Store references to the contexts
		NSGraphicsContext *bucket_context = [NSGraphicsContext currentContext];
		CGContextRef bucket_ctx = [bucket_context graphicsPort];

		// Loop through all items in the array of points
		for (unsigned int i = 0; i < _queueSize ; i++) {

			// Store the point
			CGPoint aPoint = bucket_point_list[i];

			// Ensure the point isn't "null"
			if(!CGPointEqualToPoint(aPoint, point_null)){

				// Create a color with that hue
				NSColor *theColor = [NSColor redColor];

				// Set that color as the context fill color
				CGContextSetFillColorWithColor(bucket_ctx, theColor.CGColor);

				// Create a rectangle in which to draw an ellipse for the point
				CGRect circlePoint = CGRectMake((int)aPoint.x, (int)aPoint.y, _pointSize, _pointSize);

				// Draw the point
				CGContextFillEllipseInRect(bucket_ctx, circlePoint);

				// Nullify that point in the array
				bucket_point_list[i] = point_null;

			}

		}

		// Unlock the image since editing is finished
		[bucketImage unlockFocus];

		// Dispatch an update block for the image on the main thread
		dispatch_group_async(interfaceUpdatingGroup, mainQueue, ^{

			[_delegate updateHashImageData:hashImage];
			[_delegate updateBucketImageData:bucketImage];

		});

	});

	// Wait for it to finish the task before returning
	dispatch_group_wait(interfaceUpdatingGroup, DISPATCH_TIME_FOREVER);
}

/**
 * Performs the appropriate calculations for lottery mode
 */
- (void)performLotteryComputations
{
	// Dispatch the main generator block onto its queue
	dispatch_async(ticketGeneratorQueue, ^{

		// Create an index-holder for the point list
		unsigned int hash_point_list_index = 0;

		// Loop through all items that compose the lottery ticket
		for(unsigned int a = TICKET_CELL_VALUE_RANGE_MIN; a <= _ticketMax; a++){

			for(unsigned int b = TICKET_CELL_VALUE_RANGE_MIN; b <= _ticketMax; b++){

				for(unsigned int c = TICKET_CELL_VALUE_RANGE_MIN; c <= _ticketMax; c++){

					for(unsigned int d = TICKET_CELL_VALUE_RANGE_MIN; d <= _ticketMax; d++){

						for(unsigned int e = TICKET_CELL_VALUE_RANGE_MIN; e <= _ticketMax; e++){

							for(unsigned int f = TICKET_CELL_VALUE_RANGE_MIN; f <= _ticketMax; f++){

								// Capture the current point index in a constant variable
								const unsigned int point_index = hash_point_list_index++;

								// If there are active interface update operations, wait for them to stop
								dispatch_group_wait(interfaceUpdatingGroup, DISPATCH_TIME_FOREVER);

								// Make sure we don't need to stop all tasks
								if(cancelOperations){

									goto forceQuit;
								}

								// Increment the counter
								totalCount++;

								// Dispatch a ticket processing instance to the ticket processor queue
								dispatch_group_async(ticketProcessorGroup, ticketProcessorQueue, ^{

									if(cancelOperations){
										return;
									}

									//unsigned long long retVal = 0;
									unsigned long long int bytes[] = {a,b,c,d,e,f};
									NUHashComponents someComponents = {.bytes=bytes, .length=6};
									unsigned long long hash = [self hashForComponents:someComponents];

									// Find the compressed hash index
									const unsigned long long bucketIndex = [self bucketIndexForHash:hash];

									// Construct an x/y coordinate pair for this bucket entry
									CGFloat bucketXCoordinate = (CGFloat)((long double)bucketIndex/(long double)tableLength) * imageSizeInternal.width;
									CGFloat bucketYCoordinate = (CGFloat)((long double)++bucketList[bucketIndex]/(long double)scaledHeight) * imageSizeInternal.height;

									// Construct the final coordinate the the point for this compression will reside
									bucket_point_list[point_index] = CGPointMake(bucketXCoordinate, bucketYCoordinate);

									// Calculate a y index and x index as if this were a multi-dimensional array
									const long double yIndex = hash / ceill(sqrtl(maxHashValue));
									const long double xIndex = hash % (unsigned long long)ceill(sqrtl(maxHashValue));

									// Get the actual ratio so it can be applied to the image dimensions
									CGFloat xRatio = (CGFloat)(xIndex / ceill(sqrtl(maxHashValue)));
									CGFloat yRatio = (CGFloat)(yIndex / ceill(sqrtl(maxHashValue)));

									// Calculate actual coordinates in the image bounds
									CGFloat yCoordinate = yRatio * imageSizeInternal.height;
									CGFloat xCoordinate = xRatio * imageSizeInternal.width;

									// Add those coordinates to the array
									hash_point_list[point_index] = CGPointMake(xCoordinate, yCoordinate);

									// Increment the hash counter
									dispatch_async(mainQueue, ^{

										[_delegate incrementHashCount];

									});

								});

								// See if that submission marks at the max list count
								if(hash_point_list_index == _queueSize -1){

									// Update the UI
									[self updateInterfaceComponents];

									// Reset the index value
									hash_point_list_index = 0;

								}

							}

						}

					}

				}

			}

		}

	forceQuit:
		// Update the UI one final time
		[self updateInterfaceComponents];

		if(!cancelOperations){

			// Inform the delegate that the operations have completed
			dispatch_async(mainQueue, ^{

				[_delegate tasksDidEnd:nil];

			});

		}else{

			// Inform the delegate that the operations have completed
			dispatch_async(mainQueue, ^{

				[_delegate tasksDidCancel];

			});

		}

		// Ensure that everything can execute if things start back
		cancelOperations = NO;
	});
}

/**
 * Performs the appropriate calculations for dictionary mode
 */
- (void)performDictionaryComputations
{
	// Dispatch the main generator block onto its queue
	dispatch_async(ticketGeneratorQueue, ^{

		// Create an index-holder for the point list
		unsigned int hash_point_list_index = 0;

		// Loop through all items that compose the lottery ticket
		for(NSString *str in [self dictionaryData]){

			// Capture the current point index in a constant variable
			const unsigned int point_index = hash_point_list_index++;

			// If there are active interface update operations, wait for them to stop
			dispatch_group_wait(interfaceUpdatingGroup, DISPATCH_TIME_FOREVER);

			// Make sure we don't need to stop all tasks
			if(cancelOperations){

				goto forceQuit;
			}

			totalCount++;

			// Dispatch a ticket processing instance to the ticket processor queue
			dispatch_group_async(ticketProcessorGroup, ticketProcessorQueue, ^{

				// If operations should be canceled, bail
				if(cancelOperations){
					return;
				}

				// Construct a component with the appropriate length
				NUHashComponents component = {.length=(unsigned int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]};

				// Allocate space for the byte array
				unsigned long long int *bytes = calloc(component.length+3, sizeof(unsigned long long int));

				// Fetch the bytes from the string
				NSUInteger anInt = 0;
				[str getBytes:bytes
					maxLength:component.length
				   usedLength:&anInt
					 encoding:NSUTF8StringEncoding
					  options:0
						range:NSMakeRange(0, component.length)
			   remainingRange:NULL];

				// Put those bytes into the component struct
				component.bytes = bytes;

				// Compute the hash for the word
				unsigned long long int hash = [self hashForComponents:component];

				// Find the compressed hash index
				const unsigned long long bucketIndex = [self bucketIndexForHash:hash];

				// Construct an x/y coordinate pair for this bucket entry
				CGFloat bucketXCoordinate = (CGFloat)((long double)bucketIndex/(long double)tableLength) * imageSizeInternal.width;
				CGFloat bucketYCoordinate = (CGFloat)((long double)++bucketList[bucketIndex]/(long double)scaledHeight) * imageSizeInternal.height;

				// Construct the final coordinate the the point for this compression will reside
				bucket_point_list[point_index] = CGPointMake(bucketXCoordinate, bucketYCoordinate);

				// Calculate a y index and x index as if this were a multi-dimensional array
				const long double yIndex = hash / ceill(sqrtl(maxHashValue));
				const long double xIndex = hash % (unsigned long long)ceill(sqrtl(maxHashValue));

				// Get the actual ratio so it can be applied to the image dimensions
				CGFloat xRatio = (CGFloat)(xIndex / ceill(sqrtl(maxHashValue)));
				CGFloat yRatio = (CGFloat)(yIndex / ceill(sqrtl(maxHashValue)));

				// Calculate actual coordinates in the image bounds
				CGFloat yCoordinate = yRatio * imageSizeInternal.height;
				CGFloat xCoordinate = xRatio * imageSizeInternal.width;

				// Add those coordinates to the array
				hash_point_list[point_index] = CGPointMake(xCoordinate, yCoordinate);

				// Increment the hash counter
				dispatch_async(mainQueue, ^{

					[_delegate incrementHashCount];

				});

				free(bytes);

			});

			// See if that submission marks at the max list count
			if(hash_point_list_index == _queueSize -1){

				// Update the UI
				[self updateInterfaceComponents];

				// Reset the index value
				hash_point_list_index = 0;

			}


		}

	forceQuit:
		// Update the UI one final time
		[self updateInterfaceComponents];

		if(!cancelOperations){

			// Inform the delegate that the operations have completed
			dispatch_async(mainQueue, ^{

				[_delegate tasksDidEnd:nil];

			});

		}else{

			// Inform the delegate that the operations have completed
			dispatch_async(mainQueue, ^{

				[_delegate tasksDidCancel];

			});

		}

		// Ensure that calculations may continue if called again
		cancelOperations = NO;
	});
	
}

/**
 * Called when the current configuration should start execution
 */
- (void)performComputations
{
	// Prepare everything for the computation job
	[self prepareForComputations];

	// Based on the currently configured mechanism, call the appropriate computation method
	switch (_hashingMechanism) {
		case NUHashGenerationMechanismLottery:
			[self performLotteryComputations];
			break;
		case NUHashGenerationMechanismDictionary:
			[self performDictionaryComputations];
			break;
		default:
			break;
	}
	
}

/**
 * Returns the contents of the dictionary file, but only if it *needs* to be loaded
 *
 * @return The contents of the dicionary
 */
- (NSArray *)dictionaryData
{
	if(!_dictData || ![previousDictionaryPath isEqual:dictionaryPath]){
		_dictData = [self loadDictionaryData];
	}

	return _dictData;
}

/**
 * Returns the contents of the dictionary file
 *
 * @return The contents of the dictionary as it exists on disk
 */
- (NSArray *)loadDictionaryData
{
	// Get the file contents at the dictionary path URL
	NSString *fileContents = [NSString stringWithContentsOfURL:dictionaryPath encoding:NSUTF8StringEncoding error:nil];

	// Fetch the lines from the file
	NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];

	// Store this path for later reference
	previousDictionaryPath = [dictionaryPath copy];

	// Returns the lines from the file
	return lines;
}

/**
 * Ensures that the hashForComponents: method is subclassed
 */
- (unsigned long long)hashForComponents:(NUHashComponents)component
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
								 userInfo:[NSString stringWithFormat:@"%u",component.length]];
}

/**
 * Ensures that the bucketIndexForHash: method is subclassed
 */
- (unsigned long long)bucketIndexForHash:(unsigned long long)hash
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
								 userInfo:[NSString stringWithFormat:@"%llu",hash]];
}

/**
 * Ensures that the title method is subclassed
 */
- (NSString *)title
{
	@throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
								 userInfo:nil];
}

/**
 * Iterates through the dictionary and returns the largest computed hash
 * otherwise it computes the largest hash based on the maximum for ticket cells
 *
 * @return The maximum hash value
 */
- (unsigned long long)maxHashValue
{
	// Calculate based on the hashing mechanism
	switch (_hashingMechanism) {
		case NUHashGenerationMechanismDictionary:{

			// Max hash based at 0
			unsigned long long maxHash = 0;

			// Get the dictionary lines
			NSArray *aDict = [self dictionaryData];

			// Iterate through the array of lines
			for(NSString *str in aDict){

				// Construct a component
				NUHashComponents component = {.length=(unsigned int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]};

				// Allocate some space
				unsigned long long int *bytes = calloc(component.length+3, sizeof(unsigned long long int));

				// Get the bytes for the string
				NSUInteger anInt = 0;
				[str getBytes:bytes
					maxLength:component.length
				   usedLength:&anInt
					 encoding:NSUTF8StringEncoding
					  options:0
						range:NSMakeRange(0, component.length)
			   remainingRange:NULL];

				// Put those bytes into the component struct
				component.bytes = bytes;

				// Compute the hash
				unsigned long long int aHash = [self hashForComponents:component];

				// Store that hash into max if it is larger
				if(aHash > maxHash){

					maxHash = aHash;
					
				}

				// Cleanup
				free(bytes);
			}

			// Return the max hash
			return maxHash;

		}break;

		case NUHashGenerationMechanismLottery:{

			// Make a byte array with max cell values
			unsigned long long int bytes[] = {[self maxCellValue],[self maxCellValue],[self maxCellValue],[self maxCellValue],[self maxCellValue],[self maxCellValue]};

			// Create a components struct
			NUHashComponents someComponents = {.bytes =bytes, .length=6};

			// Return the hash derived from that byte array
			return [self hashForComponents:someComponents];

		}break;
		default:
			break;
	}

	// Garbage
	return 0;
}

/**
 * Returns the largest possible ticket cell value
 *
 * @return The largest possible ticket cell value
 */
- (unsigned long long)maxCellValue
{
	return _ticketMax;
}

/**
 * Returns the length of the virtual hash table
 *
 * @return The virtual hash table length
 */
- (unsigned long long)hashTableLength
{
	return tableLength;
}

/**
 * Returns the number of inputs being computed
 *
 * @return The number of inputs
 */
- (unsigned long long)numberOfInputs
{
	// Based on the mechanism, return the number of hashes being computed
	switch (_hashingMechanism) {
		case NUHashGenerationMechanismDictionary:
			return [[self dictionaryData] count];
			break;
		case NUHashGenerationMechanismLottery:
				return (unsigned long long)powl([self maxCellValue],6);
		default:
			break;
	}

	return 0;
}

/**
 * Sets the image size for what will be drawn and displayed
 * Also handles the internal image size depending on the resolution scale
 *
 * @param size The display image size
 */
- (void)setImageSize:(CGSize)size
{
	_imageSize = size;
	imageSizeInternal = CGSizeMake(_resolution * _imageSize.width, _resolution * _imageSize.height);
}

@end
