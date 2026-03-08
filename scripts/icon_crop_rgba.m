#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

static void PrintUsage(void) {
  fprintf(stderr, "Usage: icon_crop_rgba <source> <output> [border_inset_px]\n");
}

static long ParseInset(const char *rawInset) {
  char *endPtr = NULL;
  long inset = strtol(rawInset, &endPtr, 10);
  if (endPtr == rawInset || (endPtr != NULL && *endPtr != '\0') || inset < 0) {
    return 0;
  }
  return inset;
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc < 3 || argc > 4) {
      PrintUsage();
      return 1;
    }

    NSString *sourcePath = [NSString stringWithUTF8String:argv[1]];
    NSString *outputPath = [NSString stringWithUTF8String:argv[2]];
    long borderInset = (argc == 4) ? ParseInset(argv[3]) : 0;

    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:sourcePath];
    if (sourceImage == nil) {
      fprintf(stderr, "Unable to read icon source: %s\n", argv[1]);
      return 1;
    }

    NSData *tiffData = [sourceImage TIFFRepresentation];
    if (tiffData == nil) {
      fprintf(stderr, "Unable to decode icon source TIFF data\n");
      return 1;
    }

    NSBitmapImageRep *sourceBitmap = [[NSBitmapImageRep alloc] initWithData:tiffData];
    if (sourceBitmap == nil || sourceBitmap.CGImage == nil) {
      fprintf(stderr, "Unable to create source bitmap image\n");
      return 1;
    }

    NSInteger width = sourceBitmap.pixelsWide;
    NSInteger height = sourceBitmap.pixelsHigh;
    if (width <= 0 || height <= 0) {
      fprintf(stderr, "Invalid icon source size\n");
      return 1;
    }

    NSInteger cropSize = MIN(width, height);
    NSInteger offsetX = (width - cropSize) / 2;
    NSInteger offsetY = (height - cropSize) / 2;
    if (borderInset > 0 && (borderInset * 2) < cropSize) {
      offsetX += borderInset;
      offsetY += borderInset;
      cropSize -= borderInset * 2;
    }

    CGRect cropRect = CGRectMake(offsetX, offsetY, cropSize, cropSize);
    CGImageRef croppedImage = CGImageCreateWithImageInRect(sourceBitmap.CGImage, cropRect);
    if (croppedImage == NULL) {
      fprintf(stderr, "Unable to crop icon source image\n");
      return 1;
    }

    size_t outputSize = (size_t)cropSize;
    size_t bytesPerRow = outputSize * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 outputSize,
                                                 outputSize,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (context == NULL) {
      CGImageRelease(croppedImage);
      fprintf(stderr, "Unable to create RGBA icon bitmap context\n");
      return 1;
    }

    CGContextClearRect(context, CGRectMake(0, 0, outputSize, outputSize));
    CGContextDrawImage(context, CGRectMake(0, 0, outputSize, outputSize), croppedImage);
    CGImageRelease(croppedImage);

    CGImageRef outputImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    if (outputImage == NULL) {
      fprintf(stderr, "Unable to render output icon image\n");
      return 1;
    }

    NSBitmapImageRep *outputBitmap = [[NSBitmapImageRep alloc] initWithCGImage:outputImage];
    CGImageRelease(outputImage);
    if (outputBitmap == nil) {
      fprintf(stderr, "Unable to create output bitmap image\n");
      return 1;
    }

    NSDictionary *pngProperties = @{NSImageInterlaced : @NO};
    NSData *pngData = [outputBitmap representationUsingType:NSBitmapImageFileTypePNG
                                                 properties:pngProperties];
    if (pngData == nil) {
      fprintf(stderr, "Unable to encode PNG output\n");
      return 1;
    }

    if (![pngData writeToFile:outputPath atomically:YES]) {
      fprintf(stderr, "Unable to write output file: %s\n", argv[2]);
      return 1;
    }
  }

  return 0;
}
