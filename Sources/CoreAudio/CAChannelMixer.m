/*
 
 [The "BSD licence"]
 Copyright (c) 2003-2006 Arizona Software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
														   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
														   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "CAChannelMixer.h"

@implementation CAChannelMixer

- (id)init
{
	if(self = [super init]) {
		mLock = [[NSRecursiveLock alloc] init];
		
		mInputChannelCount = 0;
		mOutputChannelCount = 0;
		mMaxChannelCount = 0;
		
		mInputMixerArray = [[CAChannelMixerArray alloc] init];
		mOutputMixerArray = [[CAChannelMixerArray alloc] init];
		
		mMixedOutputChannelArray = 0;
		mInputOptimizedBufferArray = 0;
		mOutputOptimizedBufferArray = 0;
		
		mTableViewArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	if(mInputOptimizedBufferArray)
		free(mInputOptimizedBufferArray);
	if(mOutputOptimizedBufferArray)
		free(mOutputOptimizedBufferArray);
	if(mMixedOutputChannelArray)
		free(mMixedOutputChannelArray);
	
	[mTableViewArray release];
	[mInputMixerArray release];
	[mOutputMixerArray release];
	
	[mLock release];
	
	[super dealloc];
}

- (void)adopt:(CAChannelMixer*)mixer
{
	[self setNumberOfInputChannels:[mixer numberOfInputChannels]];
	[self setNumberOfOutputChannels:[mixer numberOfOutputChannels]];
	
	[mInputMixerArray release];
	mInputMixerArray = [[mixer inputMixerArray] mutableCopyWithZone:[self zone]];
	[mOutputMixerArray release];
	mOutputMixerArray = [[mixer outputMixerArray] mutableCopyWithZone:[self zone]];
	
	[self refresh];
}

- (void)setNumberOfInputChannels:(int)ic
{
	mInputChannelCount = ic;
}

- (int)numberOfInputChannels
{
	return mInputChannelCount;
}

- (void)setNumberOfOutputChannels:(int)oc
{
	mOutputChannelCount = oc;
}

- (int)numberOfOutputChannels
{
	return mOutputChannelCount;
}

- (int)maxChannelCount
{
	return mMaxChannelCount;
}

- (CAChannelMixerArray*)inputMixerArray
{
	return mInputMixerArray;
}

- (CAChannelMixerArray*)outputMixerArray
{
	return mOutputMixerArray;
}

- (void)refresh
{
	[mLock lock];
	
	mMaxChannelCount = MAX(mInputChannelCount, mOutputChannelCount);

	[mInputMixerArray setChannelCount:[self maxChannelCount]];
	[mOutputMixerArray setChannelCount:[self maxChannelCount]];
	
	[self prepare];
	
	[self reloadAllTableView];
	
	[mLock unlock];
}

- (void)prepare
{
	[mLock lock];
	
	if(mInputOptimizedBufferArray)
		free(mInputOptimizedBufferArray);
	if(mOutputOptimizedBufferArray)
		free(mOutputOptimizedBufferArray);
	if(mMixedOutputChannelArray)
		free(mMixedOutputChannelArray);
	
	mInputOptimizedBufferArray = [[self inputMixerArray] optimizedBufferArray];
	mOutputOptimizedBufferArray = [[self outputMixerArray] optimizedBufferArray];
	mMixedOutputChannelArray = malloc([self maxChannelCount]*sizeof(unsigned char));	
	
	[mLock unlock];
}

- (void)mixOutputBuffer:(Float32*)outBuffer fromInputBuffer:(Float32*)inBuffer frameCount:(long)frameCount
{
	// Copy each frame...
	
	[mLock lock];
	
	Float32 noSoundValue = 0;
	
	unsigned short f;
	for(f=0; f<frameCount; f++) {

		unsigned short c;
		for(c=0; c<mMaxChannelCount; c++) {
			mMixedOutputChannelArray[c] = 0;
		}
		
		// ...by mixing the input and output channels as required
		
		unsigned short outOffset = f*mOutputChannelCount;
		unsigned short inOffset = f*mInputChannelCount;
		
		for(c=0; c<mMaxChannelCount; c++) {
			unsigned short inputChannelValue = mInputOptimizedBufferArray[c];
			if(inputChannelValue == NONE_VALUE)
				continue;
				
			unsigned short outputChannelValue = mOutputOptimizedBufferArray[c];
			if(outputChannelValue == NONE_VALUE)
				continue;
			
			mMixedOutputChannelArray[outputChannelValue] = 1;
			
			memcpy(outBuffer+outOffset+outputChannelValue,
					inBuffer+inOffset+inputChannelValue, sizeof(Float32));
		}
		
		// fill with 0 all non-mixed channel(s)
		
		for(c=0; c<mMaxChannelCount; c++) {
			if(mMixedOutputChannelArray[c] == 0) {
				memcpy(outBuffer+outOffset+c, &noSoundValue, sizeof(Float32));				
			}
		}
	}	
	
	[mLock unlock];
}

@end

@implementation CAChannelMixer (NSTableView)

- (void)addTableView:(NSTableView*)tv
{
	if(![mTableViewArray containsObject:tv]) {
		[tv setDataSource:self];
		[mTableViewArray addObject:tv];		
	}
}

- (void)removeTableView:(NSTableView*)tv
{
	if([mTableViewArray containsObject:tv]) {
		if([tv delegate] == self)
			[tv setDelegate:NULL];
		[mTableViewArray removeObject:tv];		
	}
}

- (void)reloadTableView:(NSTableView*)tv
{
	NSEnumerator *enumerator = [[tv tableColumns] objectEnumerator];
	NSTableColumn *column;
	while(column = [enumerator nextObject]) {
		unsigned max = 0;
		if([[column identifier] isEqualToString:@"Input"])
			max = [self numberOfInputChannels];
		else if([[column identifier] isEqualToString:@"Output"])
			max = [self numberOfOutputChannels];
		else
			continue;
		
		NSPopUpButtonCell *cell = [column dataCell];
		[cell removeAllItems];
		[cell addItemWithTitle:NONE_STRING];
		
		int i;
		for(i=0; i<max; i++) {
			[cell addItemWithTitle:[NSString stringWithFormat:@"C%d", i+1]];
		}		
	}

	[tv reloadData];
}

- (void)reloadAllTableView
{
	NSEnumerator *enumerator = [mTableViewArray objectEnumerator];
	NSTableView *tv;
	while(tv = [enumerator nextObject]) {
		[self reloadTableView:tv];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self maxChannelCount];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)column
			row:(int)rowIndex
{
	NSNumber *n;
	if([[column identifier] isEqualToString:@"Input"])
		n = [[self inputMixerArray] channelAtIndex:rowIndex];
	else if([[column identifier] isEqualToString:@"Output"])
		n = [[self outputMixerArray] channelAtIndex:rowIndex];
	else if([[column identifier] isEqualToString:@"#"])
		return [NSNumber numberWithInt:rowIndex+1];
	else 
		return nil;

	int v = [n intValue];
	if(v == NONE_VALUE)
		return [NSNumber numberWithInt:0];
	else
		return [NSNumber numberWithInt:++v];
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)column
			  row:(int)rowIndex
{	
	int v = [anObject intValue];
	if(v <= 0)
		v = NONE_VALUE;
	else
		v--;
	
	[mLock lock];
		
	if([[column identifier] isEqualToString:@"Input"])
		[[self inputMixerArray] setChannel:[NSNumber numberWithInt:v] atIndex:rowIndex];
	else if([[column identifier] isEqualToString:@"Output"])
		[[self outputMixerArray] setChannel:[NSNumber numberWithInt:v] atIndex:rowIndex];
	
	[self prepare];

	[mLock unlock];	
}

@end

