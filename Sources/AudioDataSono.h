
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

#import <Foundation/Foundation.h>
#import <vecLib/vDSP.h>

#import "AudioConstants.h"
#import "AudioDataWrapper.h"
#import "AudioDataAmplitude.h"

#define IMAGE_COLOR_GRAYSCALE 0
#define IMAGE_COLOR_HOT 1
#define IMAGE_COLOR_COLD 2
#define IMAGE_COLOR_CHROMATIC 3
#define IMAGE_COLOR_NONE 100

@interface AudioDataSono : NSObject
{
    // Image
    USHORT		mImageColorMode;
	USHORT		mOldImageColorMode;
    UInt8 		*mGrayScaleIndexTable;
    UInt8		*mHotColorIndexTable;
    UInt8		*mColdColorIndexTable;
    UInt8		*mChromaticColorIndexTable;
    CGDataProviderRef 	mImageProvider;
	CGColorSpaceRef		mImageColorSpace;

    CGImageRef  	mImageRef;
    unsigned char*	mImageData;
    size_t		mImageDataSize;

    FLOAT		mImageThresholdMin;
    FLOAT		mImageThresholdMax;
    FLOAT		mImageContrast;
    FLOAT 		mImageGain;
    BOOL		mImageInverseVideo;
	BOOL		mShouldUpdateColorTable;
    
    // Data
    COMPLEX_SPLIT	mSonoBuffer;
    BOOL		mSonoBufferLoop;
    BOOL		mReverseXAxis;
    
    SLONG		mStartFFTIndex;		// Start FFT index
    SLONG		mEndFFTIndex;		// End FFT index
    ULONG		mMaxFFTIndex;		// Maximum of FFT index
    
    FLOAT mDeltaT;
    ULONG mRate;
    
    ULONG mFFT_N2;		// Points
    ULONG mFFT_log2;
    
    ULONG mFFTWindowWidth;	// Points
    ULONG mFFTWindowOffset;	// Points
        
    FLOAT mMinX, mMaxX;
    FLOAT mMinY, mMaxY;
    FLOAT mMinZ, mMaxZ;
}

- (void)initImageParameters;
- (void)initSonoParameters;
- (void)applyWrapper:(AudioDataWrapper*)wrapper selection:(BOOL)selection;
- (void)prepareBuffer;

@end

@interface AudioDataSono (Codec) <NSCoding>
@end

@interface AudioDataSono (Image)
- (void)createImage;
- (void)computeImage;
- (unsigned char*)imageData;
- (CGImageRef)imageQ2D;
@end

@interface AudioDataSono (Sonogram)
- (void)addFFT:(COMPLEX_SPLIT)fftData;
- (COMPLEX_SPLIT*)sonoBuffer;
- (ULONG)indexAtX:(FLOAT)x;
- (ULONG)indexAtY:(FLOAT)y;
- (COMPLEX_SPLIT)fftBufferAtX:(FLOAT)x;
@end

@interface AudioDataSono (Parameters)

- (void)prepareParameters;
- (void)setDuration:(FLOAT)duration;
- (void)setReverseXAxis:(BOOL)flag;
- (BOOL)reverseXAxis;

- (void)setFFTWindowWidth:(ULONG)width;
- (void)setFFTWindowOffset:(ULONG)offset;
- (ULONG)fftWindowWidth;
- (ULONG)fftWindowOffset;

- (void)setDataRate:(ULONG)rate;
- (ULONG)dataRate;

- (ULONG)maxFFT;

- (void)setImageContrast:(FLOAT)contrast;
- (FLOAT)imageContrast;

- (void)setImageGain:(FLOAT)gain;
- (FLOAT)imageGain;

- (void)setInverseVideo:(BOOL)flag;
- (BOOL)inverseVideo;

- (void)setColorMode:(USHORT)mode;
- (USHORT)colorMode;

- (void)setMinThreshold:(FLOAT)value;
- (FLOAT)minThreshold;

- (void)setMaxThreshold:(FLOAT)value;
- (FLOAT)maxThreshold;

- (FLOAT)minThresholdValue;
- (FLOAT)maxThresholdValue;

- (FLOAT)minXOfChannel:(SHORT)channel;
- (FLOAT)maxXOfChannel:(SHORT)channel;
- (FLOAT)minYOfChannel:(SHORT)channel;
- (FLOAT)maxYOfChannel:(SHORT)channel;
- (FLOAT)minZOfChannel:(SHORT)channel;
- (FLOAT)maxZOfChannel:(SHORT)channel;

- (NSString*)xAxisUnitForRange:(FLOAT)range;
- (FLOAT)xAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)yAxisUnitForRange:(FLOAT)range;
- (FLOAT)yAxisUnitFactorForRange:(FLOAT)range;

- (NSString*)zAxisUnitForRange:(FLOAT)range;
- (FLOAT)zAxisUnitFactorForRange:(FLOAT)range;

@end
