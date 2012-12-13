//
//  NUHashModule.h
//  Hash Visualizer
//
//  Created by Chris Stroud on 12/4/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 * Delegate protocol that establishes the callbacks required to be implemented
 * These will be called to alert the App Delegate of interface changes and updates
 *
 */
@protocol NUHashModuleDelegateProtocol <NSObject>

@required
- (void)updateHashImageData:(NSImage *)img;
- (void)updateBucketImageData:(NSImage *)img;
- (void)incrementHashCount;
- (void)tasksDidEnd:(NSString *)results;
- (void)tasksDidCancel;
- (void)numberOfInputsChanged:(unsigned long long)number;
@end

/**
 *
 * This class is the base for which all computations will be handled
 * It manages all dispatch operations and coordinates image generation
 *
 */
@interface NUHashModule : NSObject

/**
 * Public enum for which mechanism computations will be handled with
 */
typedef enum NUHashGenerationMechanism{
	NUHashGenerationMechanismLottery,
	NUHashGenerationMechanismDictionary,
	NUHashGenerationMechanismNoneSelected,
}NUHashGenerationMechanism;

/**
 * Struct to hold a representation of a word in bytes
 */
typedef struct NUHashComponents{
	unsigned long long int *bytes;
	unsigned int length;
}NUHashComponents;

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) CGFloat pointSize;
@property (nonatomic, assign) CGSize  imageSize;
@property (nonatomic, assign) unsigned int resolution;
@property (nonatomic, assign) NUHashGenerationMechanism hashingMechanism;
@property (nonatomic, assign) unsigned long long queueSize;

// Methods that are invoked by the App Delegate
- (void)cancelComputations;
- (void)performComputations;

// These are exposed for the convenience of subclasses
- (unsigned long long)maxCellValue;
- (unsigned long long)numberOfInputs;
- (unsigned long long)hashTableLength;

/** Things to override in subclasses **/
- (NSString*)title;
- (unsigned long long)bucketIndexForHash:(unsigned long long)hash;
- (unsigned long long)hashForComponents:(NUHashComponents)component;

@end
