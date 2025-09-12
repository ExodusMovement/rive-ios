//
//  CDNFileAssetLoader.m
//  RiveRuntime
//
//  Created by Maxwell Talbot on 07/11/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <RiveFileAsset.h>
#import <RiveFactory.h>
#import <CDNFileAssetLoader.h>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <Foundation/Foundation.h>

@implementation CDNFileAssetLoader
{}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    // Harden: disallow any remote asset fetching through CDN loader.
    (void)asset; (void)data; (void)factory;
    NSCAssert(NO, @"CDNFileAssetLoader is disabled in hardened build");
    // In Release (NS_BLOCK_ASSERTIONS), do nothing and report not handled.
    return false;
}

@end

@implementation FallbackFileAssetLoader
{
    NSMutableArray* loaders;
}

- (instancetype)init
{
    self = [super init];
    loaders = [NSMutableArray array];
    return self;
}

- (void)addLoader:(RiveFileAssetLoader*)loader
{
    [loaders addObject:loader];
}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    for (RiveFileAssetLoader* loader in loaders)
    {
        if ([loader loadContentsWithAsset:asset
                                  andData:data
                               andFactory:factory])
        {
            return true;
        }
    }
    return false;
}

@end

@implementation CustomFileAssetLoader

- (instancetype)initWithLoader:(LoadAsset)loader
{
    self = [super init];
    _loadAsset = loader;
    return self;
}

- (bool)loadContentsWithAsset:(RiveFileAsset*)asset
                      andData:(NSData*)data
                   andFactory:(RiveFactory*)factory
{
    [RiveLogger logLoadingAsset:asset];
    bool loaded = _loadAsset(asset, data, factory);
    if (loaded)
    {
        [RiveLogger logAssetLoaded:asset];
    }
    return loaded;
}

@end
