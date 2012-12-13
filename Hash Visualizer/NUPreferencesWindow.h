//
//  NUPreferencesWindow.h
//  Hash Visualizer
//
//  Created by Chris Stroud on 12/9/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/******** Not documented (yet) ********/

@interface NUPreferencesWindow : NSWindowController

extern NSString * const NUPreferencesUpdatedNotification;
extern NSString * const NUPreferencesQueueSizeKey;
extern NSString * const NUPreferencesPointSizeKey;
extern NSString * const NUPreferencesResolutionKey;
extern NSString * const NUPreferencesBucketHeightKey;
extern NSString * const NUPreferencesTicketCellMaxKey;
extern NSString * const NUPreferencesHashTableLengthKey;
extern NSString * const NUPreferencesDictionaryPathKey;
extern NSString * const NUPreferencesCustomDictionaryKey;

@property (atomic, assign) IBOutlet NSPopUpButton *resolutionDropDown;
@property (atomic, assign) IBOutlet NSPopUpButton *pointSizeDropDown;
@property (atomic, assign) IBOutlet NSTextField *queueSizeField;
@property (atomic, assign) IBOutlet NSButton *resetButton;
@property (atomic, assign) IBOutlet NSButton *doneButton;
@property (atomic, assign) IBOutlet NSTextField *dictionaryNameLabel;
@property (atomic, assign) IBOutlet NSTextField *bucketHeightPercentageLabel;
@property (atomic, assign) IBOutlet NSPopUpButton *ticketCellMaxDropDown;
@property (atomic, assign) IBOutlet NSSlider *bucketHeightSlider;
@property (atomic, assign) IBOutlet NSButton *useDefaultDictionaryButton;
@property (atomic, assign) IBOutlet NSTextField *generateNumberOfTicketsLabel;
@property (atomic, assign) IBOutlet NSTextField *hashTableLengthField;

+ (void)configureDefaults;

- (IBAction)doneButtonSelected:(id)sender;
- (IBAction)resetButtonSelected:(id)sender;
- (IBAction)chooseDictionaryFileButton:(id)sender;
- (IBAction)useDefaultDictionaryButton:(id)sender;
- (IBAction)bucketHeightChanged:(id)sender;
- (IBAction)ticketCellMaxChanged:(id)sender;
- (IBAction)resolutionDropDownChanged:(id)sender;
- (IBAction)pointSizeDropDownChanged:(id)sender;
- (IBAction)queueSizeChanged:(id)sender;
- (IBAction)tableLengthChanged:(id)sender;

@end
