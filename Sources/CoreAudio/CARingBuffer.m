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

#import "CARingBuffer.h"

enum { BUFFER_EMPTY, BUFFER_SPACE_LEFT, BUFFER_DIRTY, BUFFER_FULL };

@implementation CARingBuffer

- (id)initWithBufferSize:(long)size
{
    if(self = [super init])
    {
        mLoopBufferPtr = malloc(size);
        if(mLoopBufferPtr==NULL)
        {
            [super dealloc];
            return NULL;
        }
        
		mGeneralLock = [[NSLock alloc] init];
		[mGeneralLock setName:@"General lock"];
		mReadLock = [[NSConditionLock alloc] initWithCondition:BUFFER_EMPTY];
		[mReadLock setName:@"Read lock"];
		mWriteLock = [[NSConditionLock alloc] initWithCondition:BUFFER_SPACE_LEFT];
		[mWriteLock setName:@"Write lock"];
		
		mBufferMaxSize = size;
		mDataInBufferSize = 0;
        mMaxOffset = size-1;	// Offset from 0 to n-1 bytes
        mWriteOffset = 0;
        mReadOffset = 0;
		
		mRunning = YES;
    }
    return self;
}

- (void)dealloc
{	
	[mReadLock release];
	[mWriteLock release];
	[mGeneralLock release];
    if(mLoopBufferPtr)
        free(mLoopBufferPtr);
    [super dealloc];
}

- (void)writeData:(void*)data ofSize:(long)size
{	
	while(size>0 && mRunning) {
		[mWriteLock lockWhenCondition:BUFFER_SPACE_LEFT];
		if(!mRunning) {
			[mWriteLock unlock];
			break;
		}

		[mGeneralLock lock];
				
		long sizeToCopy = MIN(size, mMaxOffset-mWriteOffset+1);
		if(mReadOffset>mWriteOffset)
			sizeToCopy = MIN(size, mReadOffset-mWriteOffset);
		
		memcpy(mLoopBufferPtr+mWriteOffset, data, sizeToCopy);
		mDataInBufferSize += sizeToCopy;
		
		size -= sizeToCopy;
		data += sizeToCopy;

		mWriteOffset += sizeToCopy;
		if(mWriteOffset>mMaxOffset)
			mWriteOffset -= mMaxOffset+1;
	
		[mReadLock tryLock]; // in case it was not locked
		[mReadLock unlockWithCondition:BUFFER_DIRTY];
		if(mDataInBufferSize == mBufferMaxSize)
			[mWriteLock unlockWithCondition:BUFFER_FULL];
		else
			[mWriteLock unlockWithCondition:BUFFER_SPACE_LEFT];
			
		[mGeneralLock unlock];
	}				
}

- (void)readData:(void*)data ofSize:(long)size
{
	while(size>0 && mRunning) {
		[mReadLock lockWhenCondition:BUFFER_DIRTY];
		if(!mRunning) {
			[mReadLock unlock];
			break;
		}
			
		[mGeneralLock lock];
		
		long sizeToCopy = MIN(size, mMaxOffset-mReadOffset+1);
		if(mWriteOffset>mReadOffset)
			sizeToCopy = MIN(size, mWriteOffset-mReadOffset);
		
		if(data != nil)
			memcpy(data, mLoopBufferPtr+mReadOffset, sizeToCopy);
		mDataInBufferSize -= sizeToCopy;
		
		size -= sizeToCopy;
		if(data != nil)
			data += sizeToCopy;
		
		mReadOffset += sizeToCopy;		
		if(mReadOffset>mMaxOffset)
			mReadOffset -= mMaxOffset+1;
	
		[mWriteLock tryLock]; // in case it was not locked
		[mWriteLock unlockWithCondition:BUFFER_SPACE_LEFT];
		if(mDataInBufferSize == 0)
			[mReadLock unlockWithCondition:BUFFER_EMPTY];
		else
			[mReadLock unlockWithCondition:BUFFER_DIRTY];
			
		[mGeneralLock unlock];
	}				
}

- (void)flush
{
	[mGeneralLock lock];
	mDataInBufferSize = 0;
	[mWriteLock tryLock]; // in case it was not locked
	[mWriteLock unlockWithCondition:BUFFER_SPACE_LEFT];
	[mReadLock tryLock]; // in case it was not locked
	[mReadLock unlockWithCondition:BUFFER_DIRTY];
	[mGeneralLock unlock];
}

- (void)start
{
	mReadOffset = mWriteOffset = 0;
	mDataInBufferSize = 0;
	mRunning = YES;
}

- (void)stop
{
	mRunning = NO;
	[self flush];
}

@end
