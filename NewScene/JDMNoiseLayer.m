//
//  JDMNoiseLayer.m
//  NewScene
//
//  Created by Justin Madewell on 8/3/15.
//  Copyright © 2015 Justin Madewell. All rights reserved.
//

#import "JDMNoiseLayer.h"


static CGImageRef   __noiseImage        = nil;
static CGFloat      __noiseImageWidth   = 0.0;
static CGFloat      __noiseImageHeight  = 0.0;

@implementation JDMNoiseLayer

- (id)init {
    self = [super init];
    if (self) {
        self.needsDisplayOnBoundsChange = YES;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            CIContext *noiseContext = [CIContext contextWithOptions:nil];
            
            CIFilter *noiseGenerator = [CIFilter filterWithName:@"CIColorMonochrome"];
            [noiseGenerator setValue:[[CIFilter filterWithName:@"CIRandomGenerator"] valueForKey:@"outputImage"] forKey:@"inputImage"];
            [noiseGenerator setDefaults];
            
            CIImage *ciImage = [noiseGenerator outputImage];
            
            CGRect extentRect = [ciImage extent];
            if (CGRectIsInfinite(extentRect) || CGRectIsEmpty(extentRect)) {
                extentRect = CGRectMake(0, 0, 64, 64);
            }
            
            __noiseImage = [noiseContext createCGImage:ciImage fromRect:extentRect];
            __noiseImageWidth = CGImageGetWidth(__noiseImage);
            __noiseImageHeight = CGImageGetHeight(__noiseImage);
        });
    }
    
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    
    [super drawInContext:ctx];
    
        CGContextSaveGState(ctx);
        CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.cornerRadius] CGPath];
        CGContextAddPath(ctx, path);
        CGContextClip(ctx);
        CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
        CGContextSetAlpha(ctx, 1);
    
        
        CGContextDrawTiledImage(ctx, CGRectMake(0, 0, __noiseImageWidth, __noiseImageHeight), __noiseImage);
        
        CGContextRestoreGState(ctx);
}





@end
