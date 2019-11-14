/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>

#if UA_USE_MODULE_AIRSHIP_IMPORTS
@import AirshipCore;
#else
#import "UALocationModuleLoaderFactory.h"
#import "UAModuleLoader.h"
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 * Location module loader.
 */
@interface UALocationModuleLoader : NSObject<UAModuleLoader, UALocationModuleLoaderFactory>

@end


NS_ASSUME_NONNULL_END
