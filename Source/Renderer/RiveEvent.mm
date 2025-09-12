//
//  RiveEvent.m
//  RiveRuntime
//
//  Created by Zach Plata on 8/23/23.
//  Copyright © 2023 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <Foundation/Foundation.h>

/*
 * RiveEvent
 */
@implementation RiveEvent
{
    const rive::Event* instance;
    float secondsDelay;
}

- (const rive::Event*)getInstance
{
    return instance;
}

- (instancetype)initWithRiveEvent:(const rive::Event*)riveEvent
                            delay:(float)delay
{
    if (self = [super init])
    {
        secondsDelay = delay;
        instance = riveEvent;
        return self;
    }
    else
    {
        return nil;
    }
}

- (NSString*)name
{
    std::string str = ((const rive::Event*)instance)->name();
    return [NSString stringWithCString:str.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSInteger)type
{
    return ((rive::Event*)[self getInstance])->coreType();
}

- (float)delay
{
    return secondsDelay;
}

- (NSDictionary<NSString*, id>*)properties
{
    bool hasCustomProperties = false;
    NSMutableDictionary<NSString*, id>* customProperties =
        [NSMutableDictionary dictionary];
    for (auto child : ((const rive::Event*)instance)->children())
    {
        if (child->is<rive::CustomProperty>())
        {
            std::string eventName = child->name();
            if (!eventName.empty())
            {
                NSString* convertedName = [NSString
                    stringWithCString:eventName.c_str()
                             encoding:[NSString defaultCStringEncoding]];
                switch (child->coreType())
                {
                    case rive::CustomPropertyBoolean::typeKey:
                    {
                        bool customBoolValue =
                            child->as<rive::CustomPropertyBoolean>()
                                ->propertyValue();
                        customProperties[convertedName] = @(customBoolValue);
                        break;
                    }
                    case rive::CustomPropertyString::typeKey:
                    {
                        std::string customStringValue =
                            child->as<rive::CustomPropertyString>()
                                ->propertyValue();
                        NSString* convertedStringValue = [NSString
                            stringWithCString:customStringValue.c_str()
                                     encoding:[NSString
                                                  defaultCStringEncoding]];
                        customProperties[convertedName] = convertedStringValue;
                        break;
                    }
                    case rive::CustomPropertyNumber::typeKey:
                    {
                        float customNumValue =
                            child->as<rive::CustomPropertyNumber>()
                                ->propertyValue();
                        customProperties[convertedName] = @(customNumValue);
                        break;
                    }
                }
                hasCustomProperties = true;
            }
        }
    }
    if (hasCustomProperties)
    {
        return customProperties;
    }
    return nil;
}
@end

/*
 * RiveGeneralEvent
 */
@implementation RiveGeneralEvent
@end

/*
 * RiveOpenUrlEvent
 */
@implementation RiveOpenUrlEvent
- (NSString*)url
{
    NSCAssert(NO, @"OpenUrlEvent.url is disabled in hardened build");
    // In release (NS_BLOCK_ASSERTIONS), return a safe empty string.
    return @"";
}

- (NSString*)target
{
    NSCAssert(NO, @"OpenUrlEvent.target is disabled in hardened build");
    // In release, return a safe empty string.
    return @"";
}
@end
