//
//  ECAddAccountWindow.h
//  This
//
//  Created by Chris Stroud on 7/5/12.
//  Copyright (c) 2012 Elevé Creations. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/******** Not documented (yet) ********/

@protocol NUAlgorithmSelectionProtocol <NSObject>

- (void)algorithmSelectedForIndex:(NSInteger)index;

@end

@interface NUAlgorithmSelectionWindow : NSWindowController

- (id)initWithDelegate:(id <NUAlgorithmSelectionProtocol>)delegate andData:(NSArray*)data;

- (IBAction)doneButtonSelected:(id)sender;
- (IBAction)cancelButtonSelected:(id)sender;

@end
