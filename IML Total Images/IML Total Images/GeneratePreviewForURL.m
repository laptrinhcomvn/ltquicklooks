#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <AppKit/AppKit.h>
#import "ImageProcessing.h"


#define NYX_FONTSIZE 18.0f
#define NYX_BOTTOM_MARGIN 2.0f

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool{
        CFDictionaryRef properties = properties_for_file(url, url);
        if (NULL == properties)
        {
            // Some kind of error, fallback & abort
            QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
            return kQLReturnNoError;
        }
        // Create the string containing dimensions
        const CGSize imgSize = (CGSize){.width = [(__bridge NSNumber*)CFDictionaryGetValue(properties, NYX_KEY_IMGWIDTH) integerValue], .height = [(__bridge NSNumber*)CFDictionaryGetValue(properties, NYX_KEY_IMGHEIGHT) integerValue]};
        
        // Create a local properties dic to update titlebar
        CFNumberRef n = CFDictionaryGetValue(properties, NYX_KEY_IMGSIZE);
        int64_t size = 0;
        CFNumberGetValue(n, kCFNumberSInt64Type, &size);
        NSString* fmtSize = nil;
        if (size > 1048576) // More than 1Mb
            fmtSize = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)size / 1048576.0f)];
        else if ((size < 1048576) && (size > 1024)) // 1Kb - 1Mb
            fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)size / 1024.0f)];
        else // Less than 1Kb
            fmtSize = [[NSString alloc] initWithFormat:@"%lldb", size];
        CFStringRef filename = CFURLCopyLastPathComponent(url);
        CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
        // WIDTHxHEIGHT | filename | 25.01Kb
        
        NSString* strDimensions = [[NSString alloc] initWithFormat:@"%.fx%.f | %@", imgSize.width, imgSize.height, fmtSize];
        
        // Minimum size for the string
        NSFont* font = [NSFont systemFontOfSize:NYX_FONTSIZE];
        CGSize minSize = [strDimensions sizeWithAttributes:@{NSFontAttributeName : font}];
        minSize.width = ceil(minSize.width);
        minSize.height = ceil(minSize.height);
        
        // Bitmap context dimensions (2pt bottom margin)
        const CGSize sizeCtx = (CGSize){.width = ((imgSize.width < minSize.width) ? minSize.width : imgSize.width), .height = imgSize.height + minSize.height + NYX_BOTTOM_MARGIN};
        
        
        
        CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d | %@ | %@"), (int)imgSize.width, (int)imgSize.height, filename, fmtSize)};
        CFDictionaryRef props = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFRelease(values[0]);
        CFRelease(filename);
        
        // Bitmap context, render the size at the bottom
        CGContextRef ctx = QLPreviewRequestCreateContext(preview, sizeCtx, true, props);
        if (ctx != NULL)
        {
            CGImageRef cgImg = (CGImageRef)CFDictionaryGetValue(properties, NYX_KEY_IMGREPR);
            
            // Draw image at top, X-centered
            CGContextDrawImage(ctx, (CGRect){.origin.x = (imgSize.width < minSize.width) ? (minSize.width - imgSize.width) * 0.5f : 0.0f, .origin.y = minSize.height + NYX_BOTTOM_MARGIN, .size = imgSize}, cgImg);
            // Set font/color
            CGColorRef blackColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
            CGContextSetFillColorWithColor(ctx, blackColor);
            CGContextSelectFont(ctx, [[font fontName] cStringUsingEncoding:NSUTF8StringEncoding], NYX_FONTSIZE, kCGEncodingMacRoman);
            CGColorRelease(blackColor);
            
            // Draw text
            const CGFloat x = (imgSize.width < minSize.width) ? 0.0f : (imgSize.width - minSize.width) * 0.5f;
            
            
            //            CGContextShowTextAtPoint(ctx, x, NYX_BOTTOM_MARGIN, [strDimensions cStringUsingEncoding:NSASCIIStringEncoding], [strDimensions length]);
            
            // draw size label
            CTFontRef fontRef = CTFontCreateWithName((CFStringRef)[font fontName], NYX_FONTSIZE, NULL);
            NSDictionary *attrDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)fontRef, (NSString *)kCTFontAttributeName, nil];
            CFRelease(fontRef);
            
            NSAttributedString *attString = [[NSAttributedString alloc] initWithString:strDimensions attributes:attrDictionary];
            CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attString); // 5-1
            
            // Set text position and draw the line into the graphic context
            CGContextSetTextPosition(ctx, x, NYX_BOTTOM_MARGIN);
            CTLineDraw(line, ctx);
            CFRelease(line);
            
            // Will render the bitmap into the QL window
            QLPreviewRequestFlushContext(preview, ctx);
            CGContextRelease(ctx);
        }
        else
        {
            // Some kind of error, fallback, as we have a property dic, we can update the titlebar
            QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, props);
        }
        
        if (props != NULL)
            CFRelease(props);
        
        CFRelease(properties);
        
        return kQLReturnNoError;
        
    }
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
