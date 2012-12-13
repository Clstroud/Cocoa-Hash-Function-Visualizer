//
//  ECAddAccountWindow.m
//  This
//
//  Created by Chris Stroud on 7/5/12.
//  Copyright (c) 2012 Elevé Creations. All rights reserved.
//

#import "NUAlgorithmSelectionWindow.h"

/******** Not documented (yet) ********/

@interface NUAlgorithmSelectionWindow (){

    IBOutlet NSView *viewArea;
    IBOutlet NSTextField *titleTextField;
    IBOutlet NSButton *doneButton, *cancelButton;
	IBOutlet NSTableView *_tableView;

	id <NUAlgorithmSelectionProtocol> _delegate;
	NSArray *list;
}

@end

@implementation NUAlgorithmSelectionWindow

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	
	[doneButton setEnabled:YES];
	[doneButton setState:NSOnState];
}

- (id)initWithDelegate:(id)delegate andData:(NSArray*)data{

	self = [super initWithWindowNibName:@"NUAlgorithmSelectionWindow"];

	if(self){

		list = data;
		_delegate = delegate;
	}
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{

	if (!tableView) {
		return 0;
	}
	
    return (NSInteger)list.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
	
    NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];

	Class aClass = list[[@(row) unsignedIntegerValue]];

	id obj = [[aClass alloc] init];

	result.textField.stringValue = [obj title];

	
    return result;
}

- (void)awakeFromNib{

    [super awakeFromNib];


}


- (IBAction)doneButtonSelected:(id)sender{

	[_delegate algorithmSelectedForIndex:[_tableView selectedRow]];

}


- (IBAction)cancelButtonSelected:(id)sender{

    NSWindow *senderWindow = [self window];
	
    if([senderWindow isSheet]){
        
        [NSApp endSheet:senderWindow];
        
    }
    
}

- (BOOL)canBecomeKeyWindow{
    return YES;
}

- (BOOL)canBecomeMainWindow{
    return YES;
}

- (BOOL)acceptsFirstResponder{
    return YES;
}

@end
