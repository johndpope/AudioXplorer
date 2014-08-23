
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

#define SOUND_DATA_TYPE float
#define SOUND_DATA_PTR SOUND_DATA_TYPE*
#define SOUND_DATA_SIZE sizeof(SOUND_DATA_TYPE)
#define SOUND_DEFAULT_RATE 44100
#define DEFAULT_FFT_SIZE 4096

#define UNIT_NONE 0
#define UNIT_POINTS 1
#define UNIT_MS 2
#define UNIT_S 3

#define CANCEL 0
#define OK 1
#define INSERT_DATA 2
#define ADD_DATA 3

#define INPUT 1
#define OUTPUT 0

#define LEFT_CHANNEL 0
#define RIGHT_CHANNEL 1
#define STEREO_CHANNEL 2
#define LISSAJOUS_CHANNEL 3
#define MAX_CHANNEL 2	// Count only LEFT & RIGHT

#define OPERATION_AMPLITUDE 1
#define OPERATION_FFT_CURSOR 2
#define OPERATION_FFT_SELECTION 3
#define OPERATION_SONO 4
#define OPERATION_SONO_SELECTION 5
#define OPERATION_SONO_TO_AMPLITUDE 6
#define OPERATION_COPY 7
#define OPERATION_LINKED_FFT 8

#define KIND_AMPLITUDE 1
#define KIND_FFT 2
#define KIND_SONO 3

#define VIEW_NOTDEF 0
#define VIEW_2D 1
#define VIEW_3D 2

#define XAxisLinearScale 0
#define XAxisLogScale 1

#define YAxisLinearScale 0
#define YAxisLogScale 1

#define DEFAULT_VIEWCELL_WIDTH 400
#define DEFAULT_VIEWCELL_HEIGHT 200

#define EMPTY_VIEW_ID 999999

#define sign(r) (r<0?-1:1)
#define pow10(x) pow(10, x)

// Open action

#define OPEN_DO_NOTHING 0
#define OPEN_STATIC_WINDOW 1
#define OPEN_RT_WINDOW 2
#define OPEN_LAST_FILE 3

// Pasteboard

#define AudioViewPtrPboardType @"AudioViewPtrPboardType"
#define AudioDataPboardType @"AudioDataPboardType"
#define AudioViewFeaturesPboardType @"AudioViewFeaturesPboardType"

// Exception

#define AXExceptionName @"AXExceptionName"
