//
//  GRSLowHash.m
//  Hash Visualizer
//
//  Created by Chris Stroud on 12/4/12.
//  Copyright (c) 2012 NCSU. All rights reserved.
//

#import "GRSLowHash.h"


@implementation GRSLowHash

/**
 * Computes a hash from given inputs
 * Works based on a sum hash
 *
 * @param component The component for which a hash is being generated
 * @return Computed hash
 */
- (unsigned long long)hashForComponents:(NUHashComponents)component
{

	// Create a base return value
	unsigned long long retVal=0;

	// Loop through the byte array
	for(unsigned int i=0; i<component.length;i++){

		// Add the byte to the return value
		retVal += component.bytes[i];
	}

	// Return the hash
	return retVal;
}

/**
 * Provides a bucket index for the given hash
 * Works based on a simple modulo compression function
 *
 * @param hash The hash for which an index must be computed
 * @return The bucket index
 */
- (unsigned long long)bucketIndexForHash:(unsigned long long)hash
{

	return hash % [self hashTableLength];
}

/**
 * Returns the title of the hashing algorithm
 *
 * @return The algorithm title
 */
-(NSString*)title
{

	return @"RUSlow Hash";
}

@end
