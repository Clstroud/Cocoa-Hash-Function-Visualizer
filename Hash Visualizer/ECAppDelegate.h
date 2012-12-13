//
//  ECAppDelegate.h
//  Hash Visualizer
//
//  Created by Chris Stroud on 11/16/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NUHashModule.h"
#import "NUAlgorithmSelectionWindow.h"

@interface ECAppDelegate : NSObject <NSApplicationDelegate, NUHashModuleDelegateProtocol, NUAlgorithmSelectionProtocol>

// IBOutlets for main interface
@property (atomic, assign) IBOutlet NSWindow *window;
@property (atomic, assign) IBOutlet NSButton *mainButton;
@property (atomic, assign) IBOutlet NSTextField *waitingLabel;
@property (atomic, assign) IBOutlet NSProgressIndicator *spinner;
@property (atomic, assign) IBOutlet NSTextField *ticketCounterLabel;
@property (atomic, assign) IBOutlet NSSegmentedControl *imageToggle;
@property (atomic, assign) IBOutlet NSImageView *stereoGramImageView;

// IBOutlets for menu items
@property (atomic, assign) IBOutlet NSMenuItem *lotteryMenuItem;
@property (atomic, assign) IBOutlet NSMenuItem *saveHashMenuItem;
@property (atomic, assign) IBOutlet NSMenuItem *stopTaskMenuItem;
@property (atomic, assign) IBOutlet NSMenuItem *dictionaryMenuItem;
@property (atomic, assign) IBOutlet NSMenuItem *preferencesMenuItem;
@property (atomic, assign) IBOutlet NSMenuItem *saveBucketsMenuItem;

// IBActions for interface
- (IBAction)startTasks:(id)sender;
- (IBAction)cancelJob:(id)sender;
- (IBAction)displayPreferences:(id)sender;
- (IBAction)saveHashImage:(id)sender;
- (IBAction)saveBucketsImage:(id)sender;
- (IBAction)setDictionaryMode:(id)sender;
- (IBAction)setLotteryMode:(id)sender;

@end
