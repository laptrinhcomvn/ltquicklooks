#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSURL.h>

/// Comment this line if you don't want the type displayed inside the icon
#define kNyxDisplayTypeInIcon

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    @autoreleasepool
    {
        CFDictionaryRef properties = NULL;
#ifdef kNyxDisplayTypeInIcon
        // Get the UTI properties
        NSDictionary* utiDeclarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(contentTypeUTI);
        
        // Get the extensions corresponding to the image UTI, for some UTI there can be more than 1 extension (ex image.jpeg = jpeg, jpg...)
        id extensions = utiDeclarations[(__bridge NSString*)kUTTypeTagSpecificationKey][(__bridge NSString*)kUTTagClassFilenameExtension];
        NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? extensions[0] : extensions;
        
        // Create the properties dic
        CFTypeRef keys[1] = {kQLThumbnailPropertyExtensionKey};
        CFTypeRef values[1] = {(__bridge CFStringRef)extension};
        properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
#endif /* kNyxDisplayTypeInIcon */
        // Check if the image is a PNG
        if (CFStringCompare(contentTypeUTI, kUTTypePNG, kCFCompareCaseInsensitive) == kCFCompareEqualTo)
        {

            QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);

        }
        else
            QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
        
#ifdef kNyxDisplayTypeInIcon
        if (properties != NULL)
            CFRelease(properties);
#endif /* kNyxDisplayTypeInIcon */
        
        return kQLReturnNoError;
    }
    
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
