
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

#import "AudioDataSono.h"

#define SONO_VERSION_CURRENT 1

@implementation AudioDataSono

- (id)init
{
    if(self = [super init])
    {
        [self initImageParameters];
        [self initSonoParameters];
    }
    return self;
}

- (void)dealloc
{
    if(mGrayScaleIndexTable) free(mGrayScaleIndexTable);
    if(mHotColorIndexTable) free(mHotColorIndexTable);
    if(mColdColorIndexTable) free(mColdColorIndexTable);
    if(mChromaticColorIndexTable) free(mChromaticColorIndexTable);
    if(mImageProvider) CGDataProviderRelease(mImageProvider);
    if(mImageRef) CGImageRelease(mImageRef);
    if(mImageData) free(mImageData);

    if(mSonoBuffer.realp) free(mSonoBuffer.realp);
    if(mSonoBuffer.imagp) free(mSonoBuffer.imagp);

	if(mImageColorSpace)
		CGColorSpaceRelease(mImageColorSpace);

    [super dealloc];
}

- (void)initImageParameters
{
    mImageColorMode = IMAGE_COLOR_HOT;
	mOldImageColorMode = IMAGE_COLOR_NONE;
    mGrayScaleIndexTable = NULL;
    mHotColorIndexTable = NULL;
    mColdColorIndexTable = NULL;
    mChromaticColorIndexTable = NULL;
    mImageProvider = NULL;
	mImageColorSpace = NULL;
	mShouldUpdateColorTable = YES;
	
    mImageRef = NULL;
    mImageData = NULL;

    mImageThresholdMin = 0;
    mImageThresholdMax = 255;
    mImageContrast = 1;
    mImageGain = 0;
    mImageInverseVideo = NO;
}

- (void)initSonoParameters
{
    mSonoBufferLoop = NO;
    mReverseXAxis = NO;
    mStartFFTIndex = -1;
    mEndFFTIndex = -1;
    mMaxFFTIndex = 0;
    
    mFFTWindowWidth = 0;
    mFFTWindowOffset = 0;
    
    mFFT_N2 = 0;
    mFFT_log2 = 0;
    mRate = 0;
    
    mMinX = mMaxX = 0;
    mMinY = mMaxY = 0;
    mMinZ = mMaxZ = 0;
    
    mDeltaT = 0;
}

- (void)applyWrapper:(AudioDataWrapper*)wrapper selection:(BOOL)selection
{
    mFFTWindowWidth = [wrapper windowSize];
    mFFTWindowOffset = [wrapper windowOffset];
    
    mRate = [wrapper dataRate];
        
    if(selection)
    {
        mMinX = [wrapper selMinX];
        mMaxX = [wrapper selMaxX];
    } else
    {
        mMinX = [wrapper visualMinX];
        mMaxX = [wrapper visualMaxX];
    }

    [self prepareParameters];
    [self prepareBuffer];
}

- (void)initImageBuffer
{
    size_t width = mMaxFFTIndex;
    size_t height = mFFT_N2;
    mImageDataSize = width*height;	// Size in bytes
    
    // Dispose the image first because it can crash the program if the image data is not present
    // when Quartz want to redraw the image
    
    if(mImageRef)
    {
        CGImageRelease(mImageRef);
        mImageRef = NULL;
    }
    
    // Allocate buffer
    
    if(mImageData)
        free(mImageData);
    
    mImageData = (unsigned char*)calloc(1, mImageDataSize);
}

- (void)initSonoBuffer
{
    // Buffer to hold the result of all FFT (the complete sonogram)
    if(mSonoBuffer.realp) free(mSonoBuffer.realp);
    if(mSonoBuffer.imagp) free(mSonoBuffer.imagp);

    mSonoBuffer.realp = (SOUND_DATA_PTR)calloc(mFFT_N2*mMaxFFTIndex, SOUND_DATA_SIZE);
    mSonoBuffer.imagp = (SOUND_DATA_PTR)calloc(mFFT_N2*mMaxFFTIndex, SOUND_DATA_SIZE);
}

- (void)prepareBuffer
{
    [self initImageBuffer];
    [self initSonoBuffer];
}

@end

@implementation AudioDataSono (Codec)

- (id)initWithCoder:(NSCoder*)coder
{
    if(self = [super init])
    {
        /*long version =*/ [[coder decodeObject] longValue];

        mImageDataSize = [[coder decodeObject] longValue];
        mImageData = (unsigned char*)malloc(mImageDataSize);
        [coder decodeArrayOfObjCType:@encode(unsigned char) count:mImageDataSize at:mImageData];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mImageThresholdMin];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mImageThresholdMax];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mImageContrast];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mImageGain];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&mImageInverseVideo];
        [coder decodeValueOfObjCType:@encode(USHORT) at:&mImageColorMode];
        long size = [[coder decodeObject] longValue];
        mSonoBuffer.realp = (SOUND_DATA_PTR)malloc(size*SOUND_DATA_SIZE);
        mSonoBuffer.imagp = (SOUND_DATA_PTR)malloc(size*SOUND_DATA_SIZE);
        [coder decodeArrayOfObjCType:@encode(FLOAT) count:size at:mSonoBuffer.realp];
        [coder decodeArrayOfObjCType:@encode(FLOAT) count:size at:mSonoBuffer.imagp];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&mSonoBufferLoop];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&mReverseXAxis];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mDeltaT];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mRate];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFT_N2];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFT_log2];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFTWindowWidth];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mFFTWindowOffset];
        [coder decodeValueOfObjCType:@encode(SLONG) at:&mStartFFTIndex];
        [coder decodeValueOfObjCType:@encode(SLONG) at:&mEndFFTIndex];
        [coder decodeValueOfObjCType:@encode(ULONG) at:&mMaxFFTIndex];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMinX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMaxX];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMinY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMaxY];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMinZ];
        [coder decodeValueOfObjCType:@encode(FLOAT) at:&mMaxZ];
        [self computeImage];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithLong:SONO_VERSION_CURRENT]];

    [coder encodeObject:[NSNumber numberWithLong:mImageDataSize]];
    [coder encodeArrayOfObjCType:@encode(unsigned char) count:mImageDataSize at:mImageData];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mImageThresholdMin];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mImageThresholdMax];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mImageContrast];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mImageGain];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mImageInverseVideo];
    [coder encodeValueOfObjCType:@encode(USHORT) at:&mImageColorMode];
    ULONG size = mFFT_N2*mMaxFFTIndex;
    [coder encodeObject:[NSNumber numberWithLong:size]];
    [coder encodeArrayOfObjCType:@encode(FLOAT) count:size at:mSonoBuffer.realp];
    [coder encodeArrayOfObjCType:@encode(FLOAT) count:size at:mSonoBuffer.imagp];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mSonoBufferLoop];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&mReverseXAxis];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mDeltaT];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mRate];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFT_N2];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFT_log2];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFTWindowWidth];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mFFTWindowOffset];
    [coder encodeValueOfObjCType:@encode(SLONG) at:&mStartFFTIndex];
    [coder encodeValueOfObjCType:@encode(SLONG) at:&mEndFFTIndex];
    [coder encodeValueOfObjCType:@encode(ULONG) at:&mMaxFFTIndex];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMinX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMaxX];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMinY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMaxY];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMinZ];
    [coder encodeValueOfObjCType:@encode(FLOAT) at:&mMaxZ];
}

@end

@implementation AudioDataSono (Image)

- (UInt8*)grayScaleColorTable
{
    if(mGrayScaleIndexTable == NULL)
        mGrayScaleIndexTable = malloc(256);
    
    if(mGrayScaleIndexTable == NULL)
    {
        NSLog(@"Unable to allocate the gray scale index table");
        return NULL;
    }
        
    FLOAT minThreshold = [self minThresholdValue];
    FLOAT maxThreshold = [self maxThresholdValue];
    FLOAT factor = (maxThreshold-minThreshold)/(mImageThresholdMax-mImageThresholdMin);
    
    SHORT index;
    for(index=0; index<256; index++)
    {
        UInt8 value = index;
        
        if(value<=mImageThresholdMin)
            value = minThreshold;
        if(value>=mImageThresholdMax)
            value = maxThreshold;
        
        if(index<256*(1-mImageGain))
            value = index;
        else
            value = 255;
            
        value = (value-minThreshold)*factor+value;
        value *= mImageContrast;
        value = mImageInverseVideo ? (255-value):value;
        
        mGrayScaleIndexTable[index] = value;
    }
    
    return mGrayScaleIndexTable;
}

- (UInt8*)hotColorTable
{
    if(mHotColorIndexTable == NULL)
        mHotColorIndexTable = malloc(3*256);
    
    if(mHotColorIndexTable == NULL)
    {
        NSLog(@"Unable to allocate the hot color index table");
        return NULL;
    }
    
    SHORT level = 255.0/3*(1-mImageGain);
    
    SHORT index_ = 0;
    SHORT index;
    for(index=0; index<256; index++)
    {
        SHORT component;
        for(component=0; component<3; component++)
        {
            UInt8 value = index;
            
            if(component == 0)
            {
                if(index>level)
                    value = 255;
                else
                    value = (float)index/level*255;
            } else if(component == 1)
            {
                if(index>2*level)
                    value = 255;
                else if(index>level && index<2*level)
                    value = (float)(index-level)/level*255;
                else
                    value = 0;
            } else if(component == 2)
            {
                if(index>3*level)
                    value = 255;
                else if(index>2*level && index<3*level)
                    value = (float)(index-2*level)/level*255;
                else
                    value = 0;
            }

            value *= mImageContrast;
            value = mImageInverseVideo ? (255-value):value;

            mHotColorIndexTable[index_++] = value;
        }
    }
    
    return mHotColorIndexTable;
}

- (UInt8*)coldColorTable
{
    if(mColdColorIndexTable == NULL)
        mColdColorIndexTable = malloc(3*256);
    
    if(mColdColorIndexTable == NULL)
    {
        NSLog(@"Unable to allocate the cold color index table");
        return NULL;
    }
    
    SHORT level = 255.0/3*(1-mImageGain);
    
    SHORT index_ = 0;
    SHORT index;
    for(index=0; index<256; index++)
    {
        SHORT component;
        for(component=0; component<3; component++)
        {
            UInt8 value = index;
            
            if(component == 2)
            {
                if(index>level)
                    value = 255;
                else
                    value = (float)index/level*255;
            } else if(component == 1)
            {
                if(index>2*level)
                    value = 255;
                else if(index>level && index<2*level)
                    value = (float)(index-level)/level*255;
                else
                    value = 0;
            } else if(component == 0)
            {
                if(index>3*level)
                    value = 255;
                else if(index>2*level && index<3*level)
                    value = (float)(index-2*level)/level*255;
                else
                    value = 0;
            }

            value *= mImageContrast;
            value = mImageInverseVideo ? (255-value):value;

            mColdColorIndexTable[index_++] = value;
        }
    }
    
    return mColdColorIndexTable;
}

- (UInt8*)chromaticColorTable
{
    if(mChromaticColorIndexTable == NULL)
        mChromaticColorIndexTable = malloc(3*256);
    
    if(mChromaticColorIndexTable == NULL)
    {
        NSLog(@"Unable to allocate the chromatic color index table");
        return NULL;
    }
        
    NSString *colorRGBSpaceName = [[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1] colorSpaceName];
    
    SHORT index_ = 0;
    SHORT index;
    for(index=0; index<256; index++)
    {
        float hue = (float)(256-index)/256*0.66*(1-mImageGain);
        NSColor *color = [[NSColor colorWithDeviceHue:hue saturation:1 brightness:1 alpha:1]
        colorUsingColorSpaceName:colorRGBSpaceName];
        
        SHORT component;
        for(component=0; component<3; component++)
        {            
            UInt8 value = 0;
            switch(component) {
                case 0:
                    value = [color redComponent]*255;
                    break;
                case 1:
                    value = [color greenComponent]*255;
                    break;
                case 2:
                    value = [color blueComponent]*255;
                    break;
            }

            value *= mImageContrast;
            value = mImageInverseVideo ? (255-value):value;
    
            mChromaticColorIndexTable[index_++] = value;
        }
    }
    
    return mChromaticColorIndexTable;
}

- (void)computeImageData
{    
    if(mStartFFTIndex<0) return;
    if(mStartFFTIndex==mEndFFTIndex) return;
    
    ULONG indexFFT = mStartFFTIndex;
    ULONG maxCount = mEndFFTIndex>mStartFFTIndex?mEndFFTIndex-mStartFFTIndex-1:mMaxFFTIndex-1;
    ULONG offsetCount = 0;
    
    if(mReverseXAxis)
        offsetCount = mEndFFTIndex>mStartFFTIndex?mMaxFFTIndex-(mEndFFTIndex-mStartFFTIndex)-1:0;
    
    float zmax = 1/mMaxZ;
    
    ULONG count;
    for(count=offsetCount; count<=offsetCount+maxCount; count++)
    {
        ULONG index;
        for(index=0; index<mFFT_N2; index++)
        {
            ULONG imageIndex = count+mMaxFFTIndex*(mFFT_N2-index-1);
            ULONG sonoIndex = indexFFT*mFFT_N2+index;
            
            FLOAT value = sqrt(mSonoBuffer.realp[sonoIndex]*mSonoBuffer.realp[sonoIndex]
            +mSonoBuffer.imagp[sonoIndex]*mSonoBuffer.imagp[sonoIndex]);
            
            if(imageIndex<0 || imageIndex >= mImageDataSize)
                NSLog(@"Index problem in computeImageData (%d, max = %d)", imageIndex, mImageDataSize);
            else
                mImageData[imageIndex] = (unsigned char)((value*zmax)*255);
        }
        indexFFT++;
        if(indexFFT>=mMaxFFTIndex)
            indexFFT = 0;
    }   
}

- (void)createImage
{
    if(mImageData == NULL) return;

    if(mImageProvider)
        CGDataProviderRelease(mImageProvider);
    if(mImageRef)
        CGImageRelease(mImageRef);

    mImageProvider = NULL;
    mImageRef = NULL;
    
    size_t width = mMaxFFTIndex;
    size_t height = mFFT_N2;
    size_t bitsPerComponent = 8;			// 8 bits
    size_t bitsPerPixel = 8;				// 8 bits per pixel
    size_t bytesPerRow = bitsPerComponent*width/8;	// 1 component per pixel
    size_t imageDataSize = width*height;		// Size in bytes
    
    // Create the image provider

    mImageProvider = CGDataProviderCreateWithData(NULL, mImageData, imageDataSize, NULL);
    
    if(mImageProvider == NULL)
    {
        NSLog(@"CGDataProviderCreateWithData failed");
        return;
    }
        
    // Create the image
    
	if(mShouldUpdateColorTable || mImageColorSpace == NULL || (mImageColorMode != mOldImageColorMode)) {
		mOldImageColorMode = mImageColorMode;
		mShouldUpdateColorTable = NO;
		if(mImageColorSpace) {
			CGColorSpaceRelease(mImageColorSpace);
			mImageColorSpace = NULL;
		}
			
		switch(mImageColorMode) {
			case IMAGE_COLOR_GRAYSCALE:
				mImageColorSpace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceGray(),
														255,
														[self grayScaleColorTable]);
				break;
			
			case IMAGE_COLOR_HOT:
				mImageColorSpace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(),
														255,
														[self hotColorTable]);
				break;
				
			case IMAGE_COLOR_COLD:
				mImageColorSpace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(),
														255,
														[self coldColorTable]);
				break;

			case IMAGE_COLOR_CHROMATIC:
				mImageColorSpace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(),
														255,
														[self chromaticColorTable]);
				break;
		}
	}
            
    mImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                            mImageColorSpace,
                            kCGImageAlphaNone, mImageProvider,
                            NULL, NO, kCGRenderingIntentDefault);
	
    if(mImageRef == NULL) {
        NSLog(@"CGImageCreate failed");		
	}
}

- (void)computeImage
{
    [self computeImageData];
    [self createImage];
}

- (unsigned char*)imageData
{
    return mImageData;
}

- (CGImageRef)imageQ2D
{
    return mImageRef;
}

@end

@implementation AudioDataSono (Sonogram)

- (FLOAT)moduleAtIndex:(ULONG)index fftIndex:(ULONG)fftIndex
{
    FLOAT a = mSonoBuffer.realp[fftIndex*mFFT_N2+index];
    FLOAT b = mSonoBuffer.imagp[fftIndex*mFFT_N2+index];
    return sqrt(a*a+b*b);
}

- (void)addFFT:(COMPLEX_SPLIT)fftData
{    
    if(mEndFFTIndex<mStartFFTIndex)
    {
        mEndFFTIndex++;
        mStartFFTIndex++;
    } else
    {
        mEndFFTIndex++;
        if(mStartFFTIndex==-1)
            mStartFFTIndex++;
    }

    if(mEndFFTIndex>=mMaxFFTIndex)
    {
        mEndFFTIndex = 0;
        if(mStartFFTIndex==0)
            mStartFFTIndex++;
    }
    if(mStartFFTIndex>=mMaxFFTIndex)
        mStartFFTIndex = 0;

    if(mEndFFTIndex<0)
    {
        NSLog(@"Index problem in addFFT (%d)", mEndFFTIndex);
        return;
    }
        
    if(mSonoBuffer.realp && fftData.realp)
        memcpy(&mSonoBuffer.realp[mEndFFTIndex*mFFT_N2], fftData.realp, mFFT_N2*SOUND_DATA_SIZE);
    if(mSonoBuffer.imagp && fftData.imagp)
        memcpy(&mSonoBuffer.imagp[mEndFFTIndex*mFFT_N2], fftData.imagp, mFFT_N2*SOUND_DATA_SIZE);
        
    ULONG index;
    for(index=0; index<mFFT_N2; index++)
        mMaxZ = MAX(mMaxZ, [self moduleAtIndex:index fftIndex:mEndFFTIndex]);
}

- (COMPLEX_SPLIT*)sonoBuffer
{
    return &mSonoBuffer;
}

- (ULONG)indexAtX:(FLOAT)x
{
    SLONG delta = 0;
    SLONG index = 0;

    if(mReverseXAxis)
    {
        delta = (float)(x-mMaxX)/(mMaxX-mMinX)*mMaxFFTIndex;
        index = mEndFFTIndex+delta;

        if(mStartFFTIndex>mEndFFTIndex)
        {
            if(index<0)
                index = mMaxFFTIndex+index;
        } else
        {
            if(index<0)
                index = 0;
        }
    } else
    {
        delta = (float)(x-mMinX)/(mMaxX-mMinX)*mMaxFFTIndex;
        index = mStartFFTIndex+delta;

        if(mStartFFTIndex>mEndFFTIndex)
        {
            if(index>=mMaxFFTIndex)
                index -= mMaxFFTIndex;
        } else
        {
            if(index>=mMaxFFTIndex)
                index = mMaxFFTIndex-1;
        }
    }
        
    return index;
}

- (ULONG)indexAtY:(FLOAT)y
{
    return y/(mRate*0.5)*(mFFT_N2-1);
}

- (COMPLEX_SPLIT)fftBufferAtX:(FLOAT)x
{
    ULONG index = [self indexAtX:x];
        
    COMPLEX_SPLIT buffer;
    buffer.realp = &mSonoBuffer.realp[index*mFFT_N2];
    buffer.imagp = &mSonoBuffer.imagp[index*mFFT_N2];
        
    return buffer;
}

@end

@implementation AudioDataSono (Parameters)

- (void)prepareParameters
{
    FLOAT ratio = (FLOAT)mFFTWindowOffset/mFFTWindowWidth;
    
    // Adapt window width if it's bigger than the data range
    mDeltaT = mMaxX-mMinX;
    while(mDeltaT*mRate<mFFTWindowWidth && mFFTWindowWidth>4)
    {
        mFFTWindowWidth *= 0.5;
        if(mFFTWindowOffset>mFFTWindowWidth)
            mFFTWindowOffset = mFFTWindowWidth*ratio;
    }
    
    if(mDeltaT*mRate<mFFTWindowWidth || mFFTWindowOffset<=0)
        mMaxFFTIndex = 0;
    else
    {
        if(mFFTWindowWidth>mFFTWindowOffset)
            // On soustrait la largeur d'une fenêtre pour ne pas déborder...
            mMaxFFTIndex = (FLOAT)(mDeltaT*mRate-mFFTWindowWidth)/mFFTWindowOffset;
        else
            // Aucun risque de débordement, on divise simplement...
            mMaxFFTIndex = (FLOAT)(mDeltaT*mRate)/mFFTWindowOffset;        
    }
    
    mStartFFTIndex = -1;
    mEndFFTIndex = -1;
    
    mFFT_N2 = mFFTWindowWidth*0.5;
    mFFT_log2 = log(mFFTWindowWidth)/log(2);

    mMinY = 0;
    mMaxY = (FLOAT)mFFT_N2/((FLOAT)mFFTWindowWidth/mRate);    
    
    // Correction de la durée réelle. Elle doit être un multiple de la taille de la fenêtre
    // de la FFT et de son offset (et cela dépend encore du rapport de taille entre ces deux
    // paramètres)
    
    ULONG realDeltaIndex = 0;
    FLOAT realDuration = mDeltaT;
    
    if(mFFTWindowWidth>mFFTWindowOffset)
    {
        // On doit soustraire d'abord la largeur, puis diviser par l'offset
        realDeltaIndex = (mDeltaT*mRate-mFFTWindowWidth)/mFFTWindowOffset;
        realDuration = (FLOAT)(realDeltaIndex*mFFTWindowOffset+mFFTWindowWidth)/mRate;
    } else if(mFFTWindowWidth == mFFTWindowOffset)
    {
        // On tient compte uniquement de la largeur (ou de l'offset)
        realDeltaIndex = (mDeltaT*mRate)/mFFTWindowOffset;
        realDuration = (FLOAT)(realDeltaIndex*mFFTWindowOffset)/mRate;
    } else
    {
        // On tient compte des deux paramètres
        realDeltaIndex = (mDeltaT*mRate)/mFFTWindowOffset;
        realDuration = (FLOAT)(realDeltaIndex*mFFTWindowOffset)/mRate;        
    }
    
    if(mReverseXAxis)
        mMinX = mMaxX-realDuration;
    else
        mMaxX = mMinX+realDuration;
}

- (void)setDuration:(FLOAT)duration
{
    if(mReverseXAxis)
    {
        mMinX = -duration;
        mMaxX = 0;
    } else
    {
        mMinX = 0;
        mMaxX = duration;
    }

    mMinY = 0;
    mMaxY = 10000;
    mDeltaT = duration;
}

- (void)setFFTWindowWidth:(ULONG)width
{
    mFFTWindowWidth = width;
}

- (void)setReverseXAxis:(BOOL)flag
{
    mReverseXAxis = flag;

    FLOAT temp = mMinX;
    mMinX = -mMaxX;
    mMaxX = -temp;
}

- (BOOL)reverseXAxis
{
    return mReverseXAxis;
}

- (void)setFFTWindowOffset:(ULONG)offset
{
    mFFTWindowOffset = offset;
}

- (ULONG)fftWindowWidth
{
    return mFFTWindowWidth;
}

- (ULONG)fftWindowOffset
{
    return mFFTWindowOffset;
}

- (void)setDataRate:(ULONG)rate
{
    mRate = rate;
}

- (ULONG)dataRate
{
    return mRate;
}

- (ULONG)maxFFT
{
    return mMaxFFTIndex;
}

- (void)setImageContrast:(FLOAT)contrast
{
    mImageContrast = contrast;
	mShouldUpdateColorTable = YES;
}

- (FLOAT)imageContrast
{
    return mImageContrast;
}

- (void)setImageGain:(FLOAT)gain
{
    mImageGain = gain;
	mShouldUpdateColorTable = YES;
}

- (FLOAT)imageGain
{
    return mImageGain;
}

- (void)setInverseVideo:(BOOL)flag
{
    mImageInverseVideo = flag;
	mShouldUpdateColorTable = YES;
}

- (BOOL)inverseVideo
{
    return mImageInverseVideo;
}

- (void)setColorMode:(USHORT)mode
{
    mImageColorMode = mode;
	mShouldUpdateColorTable = YES;
}

- (USHORT)colorMode
{
    return mImageColorMode;
}

- (void)setMinThreshold:(FLOAT)value
{
    mImageThresholdMin = value;
	mShouldUpdateColorTable = YES;
}

- (FLOAT)minThreshold
{
    return mImageThresholdMin;
}

- (void)setMaxThreshold:(FLOAT)value
{
    mImageThresholdMax = value;
	mShouldUpdateColorTable = YES;
}

- (FLOAT)maxThreshold
{
    return mImageThresholdMax;
}

- (FLOAT)minThresholdValue
{
    return 0;
}

- (FLOAT)maxThresholdValue
{
    return 255;
}

- (FLOAT)zValueAtIndexX:(ULONG)x indexY:(ULONG)y
{
    ULONG index = x*mFFT_N2+y;
    return sqrt(mSonoBuffer.realp[index]*mSonoBuffer.realp[index]
                +mSonoBuffer.imagp[index]*mSonoBuffer.imagp[index]);
}

- (FLOAT)zValueNormalizedAtX:(FLOAT)x y:(FLOAT)y
{
    return [self zValueAtIndexX:[self indexAtX:x] indexY:[self indexAtY:y]]/mMaxZ;
}

- (FLOAT)zValueAtX:(FLOAT)x y:(FLOAT)y
{
    return [self zValueAtIndexX:[self indexAtX:x] indexY:[self indexAtY:y]];
}
- (FLOAT)minXOfChannel:(SHORT)channel { return mMinX; }
- (FLOAT)maxXOfChannel:(SHORT)channel { return mMaxX; }
- (FLOAT)minYOfChannel:(SHORT)channel { return mMinY; }
- (FLOAT)maxYOfChannel:(SHORT)channel { return mMaxY; }
- (FLOAT)minZOfChannel:(SHORT)channel { return mMinZ; }
- (FLOAT)maxZOfChannel:(SHORT)channel { return mMaxZ; }

- (SHORT)kind { return KIND_SONO; }
- (BOOL)supportTrigger { return NO; }
- (BOOL)supportPlayback { return NO; }
- (BOOL)supportHarmonicCursor { return YES; }

- (NSString*)name { return NSLocalizedString(@"Sonogram", NULL); }
- (NSString*)xAxisUnit { return @"s"; }
- (NSString*)yAxisUnit { return @"Hz"; }
- (NSString*)xAxisName { return NSLocalizedString(@"Time", NULL); }
- (NSString*)yAxisName { return NSLocalizedString(@"Frequency", NULL); }

- (NSString*)xAxisUnitForRange:(FLOAT)range
{
    if(range<1e-3)
        return @"µs";
    else if(range<1)
        return @"ms";
    else
        return @"s";
}

- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range
{
    if(range<1e-3)
        return 1e6;
    else if(range<1)
        return 1e3;
    else
        return 1;
}

- (NSString*)yAxisUnitForRange:(FLOAT)range
{
    if(range>=1000)
        return @"kHz";
    else
        return @"Hz";
}

- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range
{
    if(range>=1000)
        return 0.001;
    else
        return 1;
}

- (NSString*)zAxisUnitForRange:(FLOAT)range
{
    if(range<1 && range>1e-3)
        return @"mV";
    else if(range<1e-3)
        return @"µV";
    else
        return @"V";
}

- (FLOAT)zAxisUnitFactorForRange:(FLOAT)range
{
    if(range<1 && range>1e-3)
        return 1e3;
    else if(range<1e-3)
        return 1e6;
    else
        return 1;
}

@end