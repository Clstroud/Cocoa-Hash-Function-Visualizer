//
//  ECAppDelegate.m
//  Hash Visualizer
//
//  Created by Chris Stroud on 11/16/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import <objc/objc-class.h>
#import "ECAppDelegate.h"
#import "NUPreferencesWindow.h"
#import "NUAlgorithmSelectionWindow.h"

/**
 * Private enum used to reference segment indices
 */
typedef enum kSegmentIndex{
	kSegmentIndexHashes  = 0,
	kSegmentIndexBuckets = 1,
}kSegmentIndex;

@implementation ECAppDelegate

/***** Globals *****/
NSArray *classes;
NSString *numInputsStr;
NSNumberFormatter *formatter;
NSImage *hashImage, *bucketImage;

NUHashModule *testingModule;
NUPreferencesWindow *preferencesWindow;
NUHashGenerationMechanism mainMechanism;
NUAlgorithmSelectionWindow *algorithmWindow;

unsigned long long  ticketCount, numInputs;
BOOL displayPreferences, displaySaves, displayModes, displayCancel;


/***** C Function Prototype(s) *****/
NSArray *ClassGetSubclasses(Class parentClass);

/**
 * Delegate method implemented to allow handling of a class selection
 * in the algorithm selection modal dialog present at launch
 *
 * @param index The index that was selected
 */
- (void)algorithmSelectedForIndex:(NSInteger)index
{

	// Dismiss the sheet
	if([[algorithmWindow window] isSheet]){

		[NSApp endSheet:[algorithmWindow window]];
		
	}

	// Configure menu items
	displayModes		= YES;
	displayPreferences	= YES;
	displaySaves		= NO;
	displayCancel		= NO;

	// Force the menu to update
	[[_window menu] update];

	// Retrieve the class that was selected
	Class aClass = classes[[@(index) unsignedIntegerValue]];

	// Instantiate that class and assign it to the testing module
	testingModule = [(NUHashModule*)[aClass alloc] init];
}

/**
 * Standard appWillFinishLaunching, handles the querying of hash module subclasses
 * and presenting the algorithm selection sheet, as well as basic menu configuration
 *
 * @param notification System-supplied launch notification object
 **/
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{

	// Hashes should always be the initial selected index segment
	_imageToggle.selectedSegment = kSegmentIndexHashes;

	// Make sure the image toggle is sending actions to self
	[_imageToggle setTarget:self];
	[_imageToggle setAction:@selector(toggleChanged:)];
	
	// Fetch the list of subclasses for the NUHashModule class
	classes = ClassGetSubclasses([NUHashModule class]);

	// Initialize and assign the algorithm selection window instance
	algorithmWindow = [[NUAlgorithmSelectionWindow alloc] initWithDelegate:self andData:classes];

	// Present the window as a sheet
	[NSApp beginSheet:[algorithmWindow window]
	   modalForWindow:_window
		modalDelegate:[algorithmWindow window]
	   didEndSelector:@selector(orderOut:)
		  contextInfo:NULL];

	// Make it key and first responder
	[[algorithmWindow window] becomeKeyWindow];
	[[algorithmWindow window] becomeFirstResponder];

	// Since formatters are expensive, go ahead and create a number formatter and store it
	formatter = [NSNumberFormatter new];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];

	// Configure the menu
	displayModes		= NO;
	displayPreferences	= NO;
	displaySaves		= NO;
	displayCancel		= NO;

	// Force the menu to update
	[[_window menu] update];

	// The hash mechanism will be dictionary by default
	mainMechanism = NUHashGenerationMechanismDictionary;

	// Have the preferences window configure defaults if this is first run
	[NUPreferencesWindow configureDefaults];
}

/**
 * Delegate method for NSMenu allowing granular control over whether to enable items
 *
 * @param menuItem The menu item we are being queried about
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{

	// Determine whether the preferences item should be enabled
	if([menuItem isEqual:_preferencesMenuItem]){
		return displayPreferences;
	}

	// Determine whether the save image items should be enabled
	if([menuItem isEqual:_saveBucketsMenuItem] || [menuItem isEqual:_saveHashMenuItem]){
		return displaySaves;
	}

	// Determine whether the mode items should be enabled
	if([menuItem isEqual:_dictionaryMenuItem] || [menuItem isEqual:_lotteryMenuItem]){
		return displayModes;
	}

	// Determine if the cancel/stop tasks item should be enabled
	if([menuItem isEqual:_stopTaskMenuItem]){
		return displayCancel;
	}

	// Just say no by default
	return NO;
}

/**
 * Handler invoked by the main button (start button), initiating the job
 *
 * @param sender The message sender
 */
- (IBAction)startTasks:(id)sender
{

	// Set the ticket counter to zero
		ticketCount = 0;

	// Hide the waiting to start label
		[_waitingLabel setHidden:YES];

	// Configure the module being tested
		testingModule.delegate = self;
		testingModule.hashingMechanism = mainMechanism;
		[testingModule setImageSize:_stereoGramImageView.frame.size];

	// Get a number of inputs and also convert it to a string
		numInputs = [testingModule numberOfInputs];
		numInputsStr = [formatter stringFromNumber:@(numInputs)];

	// Initiate computations for the module
		[testingModule performComputations];

	// Hide the main button and start the spinner
		[_mainButton setHidden:YES];
		[_spinner startAnimation:nil];

	// Configure the menu
		displayModes		= NO;
		displayPreferences	= NO;
		displaySaves		= NO;
		displayCancel		= YES;

	// Force menu update
		[[_window menu] update];
}

/**
 * Delegate method for the NUHashModule alerting that the number of inputs changed
 * This can be called for several reasons, but it's just to ensure that the
 * percentage value stays current and is not being based off of bad (old) data.
 *
 * @param number The number of inputs
 */
- (void)numberOfInputsChanged:(unsigned long long)number
{

	// Store the number of inputs in the global variable
	numInputs = number;

	// Convert and store it as a string, for speed.
	numInputsStr = [formatter stringFromNumber:@(numInputs)];
}

/**
 * Handles toggle selected index changed events from the main toggle
 * Updates the main image depending on what index is currently selected
 *
 * @param sender The object sending the message
 */
- (void)toggleChanged:(id)sender
{

	// Switch amongst the possible segments
		switch (_imageToggle.selectedSegment) {
			case kSegmentIndexHashes:
				[_stereoGramImageView setImage:hashImage];
				break;
			case kSegmentIndexBuckets:
				[_stereoGramImageView setImage:bucketImage];
				break;
			default:
				break;
		}
}

/**
 * Delegate method required by the NUHashModule class
 * Updates the NSImage stored for the hash image
 *
 * @param img The updated image
 */
- (void)updateHashImageData:(NSImage *)img
{
	// Make a copy of the image and store it
	hashImage = [img copy];

	// If the image toggle is selected for this image type, update the main image
	if(_imageToggle.selectedSegment == kSegmentIndexHashes){
		
		[_stereoGramImageView setImage:hashImage];
		
	}
}

/**
 * Delegate method required by the NUHashModule class
 * Updates the NSImage stored for the bucket image
 *
 * @param img The updated image
 */
- (void)updateBucketImageData:(NSImage *)img
{

	// Make a copy of the image and store it
	bucketImage = [img copy];

	// If the image toggle is selected for this image type, update the main image
	if(_imageToggle.selectedSegment == kSegmentIndexBuckets){
		
		[_stereoGramImageView setImage:bucketImage];
		
	}
}

/**
 * Delegate method required by the NUHashModule class
 * Updates the hash counter and then updates the percentage label
 */
- (void)incrementHashCount
{

	// Increment the counter variable
	ticketCount++;

	// Create a string from the current counter
	NSString *counterStr = [formatter stringFromNumber:@(ticketCount)];

	// Create a string from the appropriate noun
	NSString *nounStr = (mainMechanism == NUHashGenerationMechanismDictionary)?@"Words":@"Tickets";

	// Get the current ratio for the percentage
	long double ratio = 100.0*((long double)ticketCount / (long double)numInputs);

	// Construct the final label string
	NSString *labelStr = [NSString stringWithFormat:@"%@ / %@ %@ Processed  -  %0.2Lf%% Complete", counterStr, numInputsStr, nounStr, ratio];

	// Assign the label string to the label
	[_ticketCounterLabel setStringValue:labelStr];
}

/**
 * Delegate method required by NUHashModule
 * Called when the current task has finished completely
 *
 * @param results Optional string summarizing any statistical or otherwise relevant data
 */
- (void)tasksDidEnd:(NSString*)results
{

	// Construct a basic alert that the computations are completed
		NSAlert *infoAlert = [[NSAlert alloc] init];
		[infoAlert addButtonWithTitle:@"OK"];
		[infoAlert setMessageText:@"Computations Completed!"];
[infoAlert setAlertStyle:NSInformationalAlertStyle];
	
	// If results are non-nil, add them in as informative text
		if(results){
			[infoAlert setInformativeText:results];
		}

	// Present the alert as a sheet
		[infoAlert beginSheetModalForWindow:[self window]
							  modalDelegate:[infoAlert window]
							 didEndSelector:@selector(orderOut:)
								contextInfo:nil];

	// Show the main button and hide the spinner
		[_mainButton setHidden:NO];
		[_spinner stopAnimation:nil];

	// Configure the menu items
		displayModes		= YES;
		displayPreferences	= YES;
		displaySaves		= YES;
		displayCancel		= NO;

	// Force the menu to update
		[[_window menu] update];

}

/**
 * Delegate method required by NUHashModule
 * Called when the current task has finished due to cancellation
 */
- (void)tasksDidCancel
{

	// Show the main button and hide the spinner
		[_mainButton setHidden:NO];
		[_spinner stopAnimation:nil];

	// Configure the menu items
		displayModes		= YES;
		displayPreferences	= YES;
		displaySaves		= YES;
		displayCancel		= NO;

	// Force the menu to update
		[[_window menu] update];
		
}

/**
 * Callback method to ensure that the user really wants to cancel the current job
 *
 * @param alert The alert instance that was dismissed
 * @param choice The selected option index
 * @param ctx Context information
 */
- (void)confirmCancel:(NSAlert*)alert code:(int)choice context:(void *)ctx
{

	// Order out the alert window
	[[alert window] orderOut:nil];

	// If the choice was not to cancel the cancellation, do the cancel operation
	if(choice != NSAlertDefaultReturn){

		[testingModule cancelComputations];

	}
}

/**
 * Handler invoked when the user elects to cancel the job via the menu
 *
 * @param sender The object sending the message
 */
- (IBAction)cancelJob:(id)sender
{

	// Construct and present the alert
	NSAlert *infoAlert = [[NSAlert alloc] init];
	[infoAlert addButtonWithTitle:@"Stop"];
	[infoAlert addButtonWithTitle:@"Cancel"];
	[infoAlert setMessageText:@"Stop current operation?"];
	[infoAlert setInformativeText:@"Stopping the current operation will lose all current data"];
	[infoAlert setAlertStyle:NSInformationalAlertStyle];
	[infoAlert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(confirmCancel:code:context:)
							contextInfo:nil];
}

/**
 * Handler invoked when the user selects the "Preferences" menu item
 *
 * @param sender The object sending the message
 */
- (IBAction)displayPreferences:(id)sender
{

	// Store a new instance of the preferences window in the global variable
	preferencesWindow = [[NUPreferencesWindow alloc] init];

	// Present that window as a sheet on the main window
	[NSApp beginSheet:[preferencesWindow window]
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:NULL];

	// Make it the key window and first responder
	[[preferencesWindow window] becomeKeyWindow];
	[[preferencesWindow window] becomeFirstResponder];
}

/**
 * Handler invoked when the user selects the "Save -> Hash Image" menu item
 * Saves image as a PNG because reasons
 *
 * @param sender The object sending the message
 */
- (IBAction)saveHashImage:(id)sender
{

	// Construct a new save panel 
	NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"png"]];

	// Present the panel
    [savePanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){

		// If they confirmed the save, save the image
        if (result == NSFileHandlingPanelOKButton) {

			// Dismiss the panel
            [savePanel orderOut:self];

			// Lock focus on the image and get a bitmap representation from it
			[hashImage lockFocus];
			NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, hashImage.size.width, hashImage.size.height)];
			[hashImage unlockFocus];

			// Convert the bitmap to a PNG representation and write it to the URL
			[[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}

/**
 * Handler invoked when the user selects the "Save -> Bucket Image" menu item
 * Saves image as a PNG because reasons
 *
 * @param sender The object sending the message
 */
- (IBAction)saveBucketsImage:(id)sender
{

	// Construct a new save panel
	NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes:@[@"png"]];

	// Present the panel
    [savePanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){

		// If they confirmed the save, save the image
        if (result == NSFileHandlingPanelOKButton) {

			// Dismiss the panel
            [savePanel orderOut:self];

			// Lock focus on the image and get a bitmap representation from it
			[bucketImage lockFocus];
			NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, bucketImage.size.width, bucketImage.size.height)];
			[bucketImage unlockFocus];

			// Convert the bitmap to a PNG representation and write it to the URL
			[[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToURL:[savePanel URL] atomically:YES];
        }
    }];
}

/**
 * Handler invoked when the user selected "File -> Mode -> Dictionary"
 * Sets the app up for computing things based on dictionary inputs
 *
 * @param sender The object sending the message
 */
- (IBAction)setDictionaryMode:(id)sender
{

	// Configure the menu items so that the correct item is selected
	[_dictionaryMenuItem setState:NSOnState];
	[_lotteryMenuItem setState:NSOffState];

	// Change the global to the correct mechanism
	mainMechanism = NUHashGenerationMechanismDictionary;
}

/**
 * Handler invoked when the user selected "File -> Mode -> Lottery"
 * Sets the app up for computing things based on lottery inputs
 *
 * @param sender The object sending the message
 */
- (IBAction)setLotteryMode:(id)sender
{

	// Configure the menu items so that the correct item is selected
	[_dictionaryMenuItem setState:NSOffState];
	[_lotteryMenuItem setState:NSOnState];

	// Change the global to the correct mechanism
	mainMechanism = NUHashGenerationMechanismLottery;
}

/** Technique adopted from
 CocoaWithLove: http://cl.ly/0G1A07283Z1O
 Needed a cleaner means of discovering new subclasses
 **/
NSArray *ClassGetSubclasses(Class parentClass)
{
    int numClasses = objc_getClassList(NULL, 0);
    Class *_classes = NULL;

    _classes = (Class *)calloc((size_t)numClasses, sizeof(Class));
    numClasses = objc_getClassList(_classes, numClasses);

    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = _classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);

        if (superClass == nil)
        {
            continue;
        }

        [result addObject:_classes[i]];
    }

    free(_classes);

    return result;
}

@end
