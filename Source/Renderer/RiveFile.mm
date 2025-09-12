//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 5/14/21.
//  Copyright © 2021 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RenderContext.h>
#import <RenderContextManager.h>
#import <RiveFileAssetLoader.h>
#import <CDNFileAssetLoader.h>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <Foundation/Foundation.h>

#import <FileAssetLoaderAdapter.hpp>

/*
 * RiveFile
 */
@implementation RiveFile
{
    rive::rcp<rive::File> riveFile;
    rive::FileAssetLoader* fileAssetLoader;
    RenderContext* _renderContext;
}

+ (uint)majorVersion
{
    return UInt8(rive::File::majorVersion);
}
+ (uint)minorVersion
{
    return UInt8(rive::File::minorVersion);
}

- (nullable instancetype)initWithByteArray:(NSArray*)array
                                   loadCdn:(bool)cdn
                                     error:(NSError**)error
{
    if (self = [super init])
    {
        UInt8* bytes;
        @try
        {
            if (array.count > SIZE_MAX / sizeof(UInt64)) {
                return nil;
            }

            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));

            [array enumerateObjectsUsingBlock:^(
                       NSNumber* number, NSUInteger index, BOOL* stop) {
              bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes
                        byteLength:array.count
                           loadCdn:cdn
                             error:error];
            if (!ok)
            {
                return nil;
            }
            self.isLoaded = true;
        }
        @finally
        {
            free(bytes);
        }

        return self;
    }
    return nil;
}

- (nullable instancetype)initWithByteArray:(NSArray*)array
                                   loadCdn:(bool)cdn
                         customAssetLoader:(LoadAsset)customAssetLoader
                                     error:(NSError**)error
{
    if (self = [super init])
    {
        UInt8* bytes;
        @try
        {
            bytes = (UInt8*)calloc(array.count, sizeof(UInt64));

            [array enumerateObjectsUsingBlock:^(
                       NSNumber* number, NSUInteger index, BOOL* stop) {
              bytes[index] = number.unsignedIntValue;
            }];
            BOOL ok = [self import:bytes
                        byteLength:array.count
                           loadCdn:cdn
                 customAssetLoader:customAssetLoader
                             error:error];
            if (!ok)
            {
                return nil;
            }
            self.isLoaded = true;
        }
        @finally
        {
            free(bytes);
        }

        return self;
    }
    return nil;
}

// QUESTION: deprecate? init with NSData feels like its all we need?
- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                                 error:(NSError**)error
{
    if (self = [super init])
    {
        BOOL ok = [self import:bytes byteLength:length loadCdn:cdn error:error];
        if (!ok)
        {
            return nil;
        }
        self.isLoaded = true;
        return self;
    }
    return nil;
}
- (nullable instancetype)initWithBytes:(UInt8*)bytes
                            byteLength:(UInt64)length
                               loadCdn:(bool)cdn
                     customAssetLoader:(LoadAsset)customAssetLoader
                                 error:(NSError**)error
{
    if (self = [super init])
    {
        BOOL ok = [self import:bytes
                    byteLength:length
                       loadCdn:cdn
             customAssetLoader:customAssetLoader
                         error:error];
        if (!ok)
        {
            return nil;
        }
        self.isLoaded = true;
        return self;
    }
    return nil;
}

- (nullable instancetype)initWithData:(NSData*)data
                              loadCdn:(bool)cdn
                                error:(NSError**)error
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [self initWithBytes:bytes
                    byteLength:data.length
                       loadCdn:cdn
                         error:error];
}
- (nullable instancetype)initWithData:(NSData*)data
                              loadCdn:(bool)cdn
                    customAssetLoader:(LoadAsset)customAssetLoader
                                error:(NSError**)error
{
    UInt8* bytes = (UInt8*)[data bytes];
    return [self initWithBytes:bytes
                    byteLength:data.length
                       loadCdn:cdn
             customAssetLoader:customAssetLoader
                         error:error];
}

/*
 * Creates a RiveFile from a binary resource
 */
- (nullable instancetype)initWithResource:(NSString*)resourceName
                            withExtension:(NSString*)extension
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error
{
    // QUESTION: good ideas on how we can combine a few of these into following
    // the same path better?
    //    there's a lot of copy pasta here.

    [RiveLogger logLoadingFromResource:[NSString stringWithFormat:@"%@.%@",
                                                                  resourceName,
                                                                  extension]];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:resourceName
                                                         ofType:extension];
    NSURL* fileUrl = [NSURL fileURLWithPath:filepath];
    NSData* fileData = [NSData dataWithContentsOfURL:fileUrl];

    return [self initWithData:fileData loadCdn:cdn error:error];
}

/*
 * Creates a RiveFile from a binary resource, and assumes the resource extension
 * is '.riv'
 */
- (nullable instancetype)initWithResource:(NSString*)resourceName
                                  loadCdn:(bool)cdn
                                    error:(NSError**)error
{
    return [self initWithResource:resourceName
                    withExtension:@"riv"
                          loadCdn:cdn
                            error:error];
}

- (nullable instancetype)
     initWithResource:(nonnull NSString*)resourceName
              loadCdn:(bool)cdn
    customAssetLoader:(nonnull LoadAsset)customAssetLoader
                error:(NSError* __autoreleasing _Nullable* _Nullable)error
{
    return [self initWithResource:resourceName
                    withExtension:@"riv"
                          loadCdn:cdn
                customAssetLoader:customAssetLoader
                            error:error];
}

- (nullable instancetype)
     initWithResource:(nonnull NSString*)resourceName
        withExtension:(nonnull NSString*)extension
              loadCdn:(bool)cdn
    customAssetLoader:(nonnull LoadAsset)customAssetLoader
                error:(NSError* __autoreleasing _Nullable* _Nullable)error
{
    [RiveLogger logLoadingFromResource:[NSString stringWithFormat:@"%@.%@",
                                                                  resourceName,
                                                                  extension]];
    NSString* filepath = [[NSBundle mainBundle] pathForResource:resourceName
                                                         ofType:extension];
    NSURL* fileUrl = [NSURL fileURLWithPath:filepath];
    NSData* fileData = [NSData dataWithContentsOfURL:fileUrl];
    return [self initWithData:fileData
                      loadCdn:cdn
            customAssetLoader:customAssetLoader
                        error:error];
}

/*
 * Creates a RiveFile from an HTTP url
 */
- (nullable instancetype)initWithHttpUrl:(NSString*)url
                                 loadCdn:(bool)loadCdn
                            withDelegate:(id<RiveFileDelegate>)delegate
{
    (void)url; (void)loadCdn; (void)delegate;
    NSCAssert(NO, @"Loading Rive files over HTTP is disabled in hardened build");
    return nil;
}

- (nullable instancetype)initWithHttpUrl:(nonnull NSString*)url
                                 loadCdn:(bool)cdn
                       customAssetLoader:(nonnull LoadAsset)customAssetLoader
                            withDelegate:(nonnull id<RiveFileDelegate>)delegate
{
    (void)url; (void)cdn; (void)customAssetLoader; (void)delegate;
    NSCAssert(NO, @"Loading Rive files over HTTP is disabled in hardened build");
    return nil;
}

- (BOOL)import:(UInt8*)bytes
    byteLength:(UInt64)length
       loadCdn:(bool)loadCdn
         error:(NSError**)error
{
    if (loadCdn) {
        NSCAssert(NO, @"CDN asset loading is disabled in hardened build");
    }
    return [self import:bytes
               byteLength:length
                  loadCdn:false /* force-disable CDN */
        customAssetLoader:^bool(
            RiveFileAsset* asset, NSData* data, RiveFactory* factory) {
          return false;
        }
                    error:error];
}
- (BOOL)import:(UInt8*)bytes
           byteLength:(UInt64)length
              loadCdn:(bool)loadCdn
    customAssetLoader:(LoadAsset)custom
                error:(NSError**)error
{
    rive::ImportResult result;
    _renderContext = [[RenderContextManager shared] newDefaultContext];
    assert(_renderContext);
    rive::Factory* factory = [_renderContext factory];

    FallbackFileAssetLoader* fallbackLoader =
        [[FallbackFileAssetLoader alloc] init];

    CustomFileAssetLoader* customAssetLoader =
        [[CustomFileAssetLoader alloc] initWithLoader:custom];
    [fallbackLoader addLoader:customAssetLoader];

    // Harden: never add CDN loader; assert if requested.
    if (loadCdn) {
        NSCAssert(NO, @"CDN asset loading is disabled in hardened build");
        // intentionally do not add CDNFileAssetLoader
    }

    fileAssetLoader = new rive::FileAssetLoaderAdapter(fallbackLoader);

    auto file = rive::File::import(
        rive::Span(bytes, length), factory, &result, fileAssetLoader);
    if (result == rive::ImportResult::success)
    {
        riveFile = std::move(file);
        return true;
    }

    switch (result)
    {
        case rive::ImportResult::unsupportedVersion:
        {
            NSString* message = @"Unsupported Rive File Version";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveUnsupportedVersion
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"UnsupportedVersion"
                                     }];
            break;
        }
        case rive::ImportResult::malformed:
        {
            NSString* message = @"Malformed Rive File.";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveMalformedFile
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"Malformed"
                                     }];
            break;
        }
        default:
        {
            NSString* message = @"Unknown error loading file.";
            [RiveLogger logFile:nil error:message];
            *error = [NSError errorWithDomain:RiveErrorDomain
                                         code:RiveUnknownError
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : message,
                                         @"name" : @"Unknown"
                                     }];
            break;
        }
    }
    return false;
}

- (RiveArtboard*)artboard:(NSError**)error
{
    auto artboard = riveFile->artboardDefault();
    if (artboard == nullptr)
    {
        NSString* message = @"No Artboards Found.";
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardsFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardsFound"
                                 }];
        return nil;
    }
    else
    {
        return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
    }
}

- (NSInteger)artboardCount
{
    return riveFile->artboardCount();
}

- (RiveArtboard*)artboardFromIndex:(NSInteger)index error:(NSError**)error
{
    auto artboard = riveFile->artboardAt(index);
    if (artboard == nullptr)
    {
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found at index %ld.", (long)index];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
}

- (RiveArtboard*)artboardFromName:(NSString*)name error:(NSError**)error
{
    std::string stdName = std::string([name UTF8String]);
    auto artboard = riveFile->artboardNamed(stdName);
    if (artboard == nullptr)
    {
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found with name %@.", name];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    else
    {
        return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
    }
}

- (NSArray*)artboardNames
{
    NSMutableArray* artboardNames = [NSMutableArray array];

    for (NSUInteger i = 0; i < [self artboardCount]; i++)
    {
        RiveArtboard* artboard = [self artboardFromIndex:i error:nil];
        if (artboard != nil)
        {
            [artboardNames addObject:[artboard name]];
        }
    }
    return artboardNames;
}

#pragma mark - Data Binding

- (NSUInteger)viewModelCount
{
    return riveFile->viewModelCount();
}

- (nullable id)viewModelAtIndex:(NSUInteger)index
{
    auto viewModel = riveFile->viewModelByIndex(index);
    if (viewModel == nullptr)
    {
        [RiveLogger logFileViewModelAtIndex:index found:NO];
        return nil;
    }
    [RiveLogger logFileViewModelAtIndex:index found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (nullable id)viewModelNamed:(NSString*)name
{
    auto viewModel = riveFile->viewModelByName(std::string([name UTF8String]));
    if (viewModel == nullptr)
    {
        [RiveLogger logFileViewModelWithName:name found:NO];
        return nil;
    }
    [RiveLogger logFileViewModelWithName:name found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (RiveDataBindingViewModel*)defaultViewModelForArtboard:(RiveArtboard*)artboard
{
    auto viewModel =
        riveFile->defaultArtboardViewModel(artboard.artboardInstance);
    if (viewModel == nullptr)
    {
        [RiveLogger logFileDefaultViewModelForArtboard:artboard found:NO];
        return nil;
    }
    [RiveLogger logFileDefaultViewModelForArtboard:artboard found:YES];
    return [[RiveDataBindingViewModel alloc] initWithViewModel:viewModel];
}

- (RiveArtboard*)bindableArtboardAtIndex:(NSInteger)index
                                   error:(NSError* __autoreleasing _Nullable*)
                                             error
{
    auto artboard = riveFile->artboardAt(index);
    if (artboard == nullptr)
    {
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found at index %ld.", (long)index];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
}

- (RiveArtboard*)bindableArtboardWithName:(NSString*)name
                                    error:(NSError* __autoreleasing _Nullable*)
                                              error
{
    std::string stdName = std::string([name UTF8String]);
    auto artboard = riveFile->artboardNamed(stdName);
    if (artboard == nullptr)
    {
        NSString* message = [NSString
            stringWithFormat:@"No Artboard Found with name %@.", name];
        [RiveLogger logFile:nil error:message];
        *error = [NSError errorWithDomain:RiveErrorDomain
                                     code:RiveNoArtboardFound
                                 userInfo:@{
                                     NSLocalizedDescriptionKey : message,
                                     @"name" : @"NoArtboardFound"
                                 }];
        return nil;
    }
    else
    {
        return [[RiveArtboard alloc] initWithArtboard:std::move(artboard)];
    }
}

/// Clean up rive file
- (void)dealloc
{
    riveFile = nullptr;
    delete fileAssetLoader;
}

@end
