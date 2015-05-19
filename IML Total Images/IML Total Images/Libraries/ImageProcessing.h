//
//  ImageProcessing.h
//  IML Total Images
//
//  Created by Le Anh Tung on 5/19/15.
//  Copyright (c) 2015 © IML. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NYX_KEY_IMGWIDTH @"nyx.width"
#define NYX_KEY_IMGHEIGHT @"nyx.height"
#define NYX_KEY_IMGSIZE @"nyx.size"
#define NYX_KEY_IMGREPR @"nyx.repr"

CF_RETURNS_RETAINED CFDictionaryRef properties_for_file(CFTypeRef src, CFURLRef url);

@interface ImageProcessing : NSObject

@end
