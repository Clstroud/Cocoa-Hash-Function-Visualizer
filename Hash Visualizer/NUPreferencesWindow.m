//
//  NUPreferencesWindow.m
//  Hash Visualizer
//
//  Created by Chris Stroud on 12/9/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

/******** Not documented (yet) ********/

#import "NUPreferencesWindow.h"

#define DEFAULT_QUEUE_SIZE 500
#define DEFAULT_POINT_SIZE_INDEX 0
#define DEFAULT_RESOLUTION_INDEX 0
#define DEFAULT_BUCKET_HEIGHT .25f
#define DEFAULT_DICTIONARY_NAME @"Default"
#define DEFAULT_LOTTERY_MAX 15
#define DEFAULT_HASH_TABLE_LENGTH 34981
#define QUEUE_MAX 10000
#define QUEUE_MIN 500

@interface NUPreferencesWindow (){

	BOOL customDictionary;
	unsigned int ticketMax;
	unsigned int queueSize;
	unsigned int pointSize;
	unsigned int resolution;
	unsigned long long int tableLength;
	CGFloat bucketHeight;
	NSString *dictionaryName;
	NSURL *dictionaryPath;
	NSNumberFormatter *formatter;
}

@end

@implementation NUPreferencesWindow

NSString * const NUPreferencesUpdatedNotification = @"NUPreferencesUpdatedNotification";

NSString * const NUPreferencesQueueSizeKey        = @"NUPreferencesQueueSizeKey";
NSString * const NUPreferencesPointSizeKey        = @"NUPreferencesPointSizeKey";
NSString * const NUPreferencesResolutionKey       = @"NUPreferencesResolutionKey";
NSString * const NUPreferencesBucketHeightKey     = @"NUPreferencesBucketHeightKey";
NSString * const NUPreferencesTicketCellMaxKey    = @"NUPreferencesTicketCellMaxKey";
NSString * const NUPreferencesDictionaryPathKey   = @"NUPreferencesDictionaryPathKey";
NSString * const NUPreferencesCustomDictionaryKey = @"NUPreferencesCustomDictionaryKey";
NSString * const NUPreferencesHashTableLengthKey  = @"NUPreferencesHashTableLengthKey";

- (id)init
{
    self = [super initWithWindowNibName:@"NUPreferencesWindow"];
    return self;
}

+ (void)configureDefaults{

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if(![defaults objectForKey:NUPreferencesQueueSizeKey]){
		
		[defaults setObject:@(DEFAULT_QUEUE_SIZE)
					 forKey:NUPreferencesQueueSizeKey];
		[defaults setObject:@(DEFAULT_RESOLUTION_INDEX+1)
					 forKey:NUPreferencesResolutionKey];
		[defaults setObject:@(DEFAULT_POINT_SIZE_INDEX+1)
					 forKey:NUPreferencesPointSizeKey];
		[defaults setObject:@(DEFAULT_LOTTERY_MAX)
					 forKey:NUPreferencesTicketCellMaxKey];
		[defaults setURL:[[NSBundle mainBundle] URLForResource:@"dict_105000" withExtension:@"txt"]
				  forKey:NUPreferencesDictionaryPathKey];
		[defaults setBool:NO
				   forKey:NUPreferencesCustomDictionaryKey];
		[defaults setObject:@(DEFAULT_BUCKET_HEIGHT)
					 forKey:NUPreferencesBucketHeightKey];
		[defaults setObject:@(DEFAULT_HASH_TABLE_LENGTH)
					 forKey:NUPreferencesHashTableLengthKey];
		
	}

	[defaults synchronize];
}

- (void)loadDefaults{

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	customDictionary = [defaults boolForKey:NUPreferencesCustomDictionaryKey];

	if(!customDictionary){

		[defaults setURL:[[NSBundle mainBundle] URLForResource:@"dict_105000" withExtension:@"txt"]
				  forKey:NUPreferencesDictionaryPathKey];

		dictionaryName = DEFAULT_DICTIONARY_NAME;

	}else{

		[_useDefaultDictionaryButton setEnabled:YES];
		dictionaryName = [[[defaults URLForKey:NUPreferencesDictionaryPathKey] pathComponents] lastObject];

	}

	dictionaryPath = [defaults URLForKey:NUPreferencesDictionaryPathKey];
	bucketHeight   = [[defaults objectForKey:NUPreferencesBucketHeightKey]  floatValue];
	queueSize      = [[defaults objectForKey:NUPreferencesQueueSizeKey]     unsignedIntValue];
	pointSize      = [[defaults objectForKey:NUPreferencesPointSizeKey]     unsignedIntValue];
	resolution     = [[defaults objectForKey:NUPreferencesResolutionKey]    unsignedIntValue];
	ticketMax      = [[defaults objectForKey:NUPreferencesTicketCellMaxKey] unsignedIntValue];
	tableLength    = [[defaults objectForKey:NUPreferencesHashTableLengthKey] unsignedLongLongValue];
	
}

- (void)windowDidLoad
{
    [super windowDidLoad];

	[self loadDefaults];

	formatter = [NSNumberFormatter new];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];

	NSMutableArray *resolutionTitles = [[NSMutableArray alloc] initWithCapacity:10];
	for(int i=1; i<11; i++){
		[resolutionTitles addObject:[NSString stringWithFormat:@"%dx", i]];
	}

	NSMutableArray *pointSizeTitles = [[NSMutableArray alloc] initWithCapacity:5];
	for(int i=1; i<6; i++){
		[pointSizeTitles addObject:[NSString stringWithFormat:@"%dpt", i]];
	}

	NSMutableArray *lotteryMaxTitles = [[NSMutableArray alloc] initWithCapacity:35];
	for(int i=1; i<37; i++){
		[lotteryMaxTitles addObject:[NSString stringWithFormat:@"%d", i]];
	}

	[_pointSizeDropDown     removeAllItems];
	[_resolutionDropDown    removeAllItems];
	[_ticketCellMaxDropDown removeAllItems];
	
	[_pointSizeDropDown     addItemsWithTitles:pointSizeTitles];
	[_resolutionDropDown    addItemsWithTitles:resolutionTitles];
	[_ticketCellMaxDropDown addItemsWithTitles:lotteryMaxTitles];

	NSString *tickets = [formatter	stringFromNumber:@((unsigned long long)powl(ticketMax,6))];
	[_generateNumberOfTicketsLabel	setStringValue:[NSString stringWithFormat:@"Generate %@ tickets", tickets]];
	[_bucketHeightPercentageLabel	setStringValue:[NSString stringWithFormat:@"%0.2f%% of Maximum", bucketHeight]];
	[_dictionaryNameLabel			setStringValue:[NSString stringWithFormat:@"Dictionary File: %@", dictionaryName]];

	[_ticketCellMaxDropDown selectItemAtIndex:ticketMax-1];
	[_pointSizeDropDown		selectItemAtIndex:pointSize-1];
	[_resolutionDropDown	selectItemAtIndex:resolution-1];
	
	[_queueSizeField		setStringValue:[formatter stringFromNumber:@(queueSize)]];
	[_hashTableLengthField	setStringValue:[formatter stringFromNumber:@(tableLength)]];
}

- (IBAction)doneButtonSelected:(id)sender{

	NSDictionary *notificationData = @{
									NUPreferencesDictionaryPathKey: dictionaryPath,
									NUPreferencesBucketHeightKey:   @(bucketHeight),
									NUPreferencesPointSizeKey:      @(pointSize),
									NUPreferencesQueueSizeKey:      @(queueSize),
									NUPreferencesTicketCellMaxKey:  @(ticketMax),
									NUPreferencesResolutionKey:     @(resolution)};

	[(NSNotificationCenter*)[NSNotificationCenter defaultCenter] postNotificationName:NUPreferencesUpdatedNotification
																			   object:nil
																			 userInfo:notificationData];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:customDictionary	forKey:NUPreferencesCustomDictionaryKey];
	[defaults setURL:dictionaryPath		forKey:NUPreferencesDictionaryPathKey];
	[defaults setObject:@(pointSize)	forKey:NUPreferencesPointSizeKey];
	[defaults setObject:@(queueSize)	forKey:NUPreferencesQueueSizeKey];
	[defaults setObject:@(ticketMax)	forKey:NUPreferencesTicketCellMaxKey];
	[defaults setObject:@(resolution)	forKey:NUPreferencesResolutionKey];
	[defaults setObject:@(bucketHeight) forKey:NUPreferencesBucketHeightKey];
	[defaults setObject:@(tableLength)  forKey:NUPreferencesHashTableLengthKey];
	
	[defaults synchronize];

	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
}

- (IBAction)resetButtonSelected:(id)sender {

	customDictionary	= NO;
	queueSize			= DEFAULT_QUEUE_SIZE;
	bucketHeight		= DEFAULT_BUCKET_HEIGHT;
	dictionaryName		= DEFAULT_DICTIONARY_NAME;
	ticketMax			= DEFAULT_LOTTERY_MAX;
	tableLength			= DEFAULT_HASH_TABLE_LENGTH;
	resolution			= DEFAULT_RESOLUTION_INDEX + 1;
	pointSize			= DEFAULT_POINT_SIZE_INDEX + 1;
	
	[_queueSizeField		setStringValue:[@(queueSize) stringValue]];
	[_hashTableLengthField	setStringValue:[@(tableLength) stringValue]];
	
	[_pointSizeDropDown		selectItemAtIndex:pointSize-1];
	[_resolutionDropDown	selectItemAtIndex:resolution-1];
	[_ticketCellMaxDropDown selectItemAtIndex:ticketMax-1];
	
	[_useDefaultDictionaryButton setEnabled:NO];
	[_bucketHeightSlider setDoubleValue:bucketHeight];
	
	dictionaryPath = [[NSBundle mainBundle] URLForResource:@"dict_105000" withExtension:@"txt"];
	[_bucketHeightPercentageLabel	setStringValue:[NSString stringWithFormat:@"%0.2f%% of Maximum", bucketHeight]];
	[_dictionaryNameLabel			setStringValue:[NSString stringWithFormat:@"Dictionary File: %@", dictionaryName]];

	NSString *tickets = [formatter stringFromNumber:@((unsigned long long)powl(ticketMax,6))];
	[_generateNumberOfTicketsLabel setStringValue:[NSString stringWithFormat:@"Generate %@ tickets", tickets]];
}

- (IBAction)chooseDictionaryFileButton:(id)sender {

	NSOpenPanel *openDictionaryPanel = [NSOpenPanel openPanel];
	[openDictionaryPanel setCanChooseFiles:YES];
	[openDictionaryPanel setCanChooseDirectories:NO];
	[openDictionaryPanel setCanCreateDirectories:NO];
	[openDictionaryPanel setAllowsMultipleSelection:NO];
	[openDictionaryPanel setAllowedFileTypes:@[@"txt", @""]];
	[openDictionaryPanel beginWithCompletionHandler:^(NSInteger result) {

		if(result == NSFileHandlingPanelOKButton){

			dictionaryPath = [openDictionaryPanel URL];
			NSArray *names = [dictionaryPath pathComponents];
			dictionaryName = [names lastObject];
			[_dictionaryNameLabel setStringValue:[NSString stringWithFormat:@"Dictionary File: %@", dictionaryName]];
			[_useDefaultDictionaryButton setEnabled:YES];
			customDictionary = YES;
		}
	}];
}

- (IBAction)useDefaultDictionaryButton:(id)sender {

	[_dictionaryNameLabel setStringValue:[NSString stringWithFormat:@"Dictionary File: %@", DEFAULT_DICTIONARY_NAME]];
	dictionaryName = DEFAULT_DICTIONARY_NAME;
	dictionaryPath = [[NSBundle mainBundle] URLForResource:@"dict_105000" withExtension:@"txt"];
	[_useDefaultDictionaryButton setEnabled:NO];
	customDictionary = NO;
}

- (IBAction)bucketHeightChanged:(id)sender {

	bucketHeight = [_bucketHeightSlider floatValue];
	[_bucketHeightPercentageLabel setStringValue:[NSString stringWithFormat:@"%0.2f%% of Maximum", bucketHeight]];
}

- (IBAction)ticketCellMaxChanged:(id)sender{

	ticketMax = (unsigned int)[_ticketCellMaxDropDown indexOfSelectedItem] + 1;
	NSString *tickets = [formatter stringFromNumber:@((unsigned long long)powl(ticketMax,6))];
	[_generateNumberOfTicketsLabel setStringValue:[NSString stringWithFormat:@"Generate %@ tickets", tickets]];
}

- (IBAction)resolutionDropDownChanged:(id)sender {

	resolution = (unsigned int)[_resolutionDropDown indexOfSelectedItem] + 1;
}

- (IBAction)pointSizeDropDownChanged:(id)sender {

	pointSize = (unsigned int)[_pointSizeDropDown indexOfSelectedItem] + 1;
}

- (IBAction)queueSizeChanged:(id)sender{

	queueSize = [[formatter numberFromString:[_queueSizeField stringValue]] unsignedIntValue];

	if(queueSize > QUEUE_MAX){
		
		NSBeep();
		
		[_queueSizeField setStringValue:[formatter stringFromNumber:@(QUEUE_MAX)]];
		queueSize = QUEUE_MAX;
		
	}else if(queueSize < QUEUE_MIN){

		NSBeep();
		
		[_queueSizeField setStringValue:[formatter stringFromNumber:@(QUEUE_MIN)]];
		queueSize = QUEUE_MIN;
	}
}

- (IBAction)tableLengthChanged:(id)sender {

	tableLength = [[formatter numberFromString:[_hashTableLengthField stringValue]] unsignedLongLongValue];
	
}

@end
