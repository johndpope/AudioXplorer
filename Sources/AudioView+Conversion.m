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

#import "AudioView+Conversion.h"


@implementation AudioView (Conversion)

- (FLOAT)computeXRealValueFromXPixel:(FLOAT)pixel
{
    return (((pixel-mDrawableRect.origin.x)/mDrawableRect.size.width)*
                            (mVisual_MaxX-mVisual_MinX)+mVisual_MinX);
}

- (FLOAT)computeYRealValueFromXPixel:(FLOAT)pixel channel:(SHORT)channel
{
    return [mDataSource yValueAtX:[self computeXRealValueFromXPixel:pixel] channel:channel];
}

- (FLOAT)computeYRealValueFromXRealValue:(FLOAT)xValue channel:(SHORT)channel
{
    return [mDataSource yValueAtX:[self computeXRealValueFromXValue:xValue] channel:channel];
}

- (FLOAT)computeYRealValueFromYPixel:(FLOAT)pixel
{
    return (((pixel-mDrawableRect.origin.y)/mDrawableRect.size.height)*
                            (mVisual_MaxY-mVisual_MinY)+mVisual_MinY);
}

- (FLOAT)computeXDeltaPixelFromRealValue:(FLOAT)value
{
    return (value/(mVisual_MaxX-mVisual_MinX)*(mDrawableRect.size.width));
}

- (FLOAT)computeXPixelFromXRealValue:(FLOAT)value
{
    return (((value-mVisual_MinX)/(mVisual_MaxX-mVisual_MinX))*
                            mDrawableRect.size.width+mDrawableRect.origin.x);
}

- (FLOAT)computeYPixelFromYRealValue:(FLOAT)value
{
    return (((value-mVisual_MinY)/(mVisual_MaxY-mVisual_MinY))*
                            mDrawableRect.size.height+mDrawableRect.origin.y);
}

- (FLOAT)computeXRealValueFromXValue:(float)value
{
	// Log scale
	if([mDataSource respondsToSelector:@selector(xAxisScale)] && [mDataSource xAxisScale] == XAxisLogScale)
		return pow10((value-mVisual_MinX)/(mVisual_MaxX-mVisual_MinX)*(log10(mVisual_MaxX)-log10(mVisual_MinX))+log10(mVisual_MinX));	
	else
		return value;
}

- (NSString*)stringFromEngineeringFloat:(FLOAT)value
{
    NSMutableString *v = [NSMutableString stringWithFormat:@"%e", value];
    SHORT index = 0;
    BOOL remove = NO;
    
    while(index<[v length])
    {
        if([v characterAtIndex:index] == [[NSString stringWithString:@"."] characterAtIndex:0])
            remove = YES;
        else if([v characterAtIndex:index] == [[NSString stringWithString:@"e"] characterAtIndex:0])
            remove = NO;
            
        if(remove)
            [v deleteCharactersInRange:NSMakeRange(index,1)];
        else
            index++;
    }
    return v;
}

- (NSString*)roundFloatToString:(FLOAT)value maxValue:(FLOAT)maxValue
{
    SHORT dec = 1;
    if(maxValue!=0)
        dec = log10(fabs(maxValue));
    else if(value!=0)
        dec = log10(fabs(value));
        
    
    if(dec<1)
    {
        switch(dec) {
            case 0:	// Ex: 0.5
                [mNumberFormatter setFormat:@"#,##0.00;-#,##0.00"];
                break;
            case -1:	// Ex: 0.05
                [mNumberFormatter setFormat:@"#,##0.000;-#,##0.000"];
                break;
            case -2:	// Ex: 0.05
                [mNumberFormatter setFormat:@"#,##0.000;-#,##0.000"];
                break;
            default:
               return [self stringFromEngineeringFloat:value];
                break;
        }
    } else
        switch(dec) {
            case 1:	// Ex: 20.3
                [mNumberFormatter setFormat:@"#,##0.0;-#,##0.0"];
                break;
            case 2:	// Ex: 102
                [mNumberFormatter setFormat:@"#,##0;-#,##0"];
                break;
            case 3:	// Ex: 1024
                [mNumberFormatter setFormat:@"#,##0;-#,##0"];
                break;
            case 4:	// Ex: 1024
                [mNumberFormatter setFormat:@"#,##0;-#,##0"];
                break;
            default:
                return [self stringFromEngineeringFloat:value];
                break;
        }
        
    return [mNumberFormatter stringForObjectValue:[NSNumber numberWithFloat:value]];
}

@end
