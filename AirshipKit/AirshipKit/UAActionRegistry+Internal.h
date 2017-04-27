/* Copyright 2017 Urban Airship and Contributors */

#import "UAActionRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@interface UAActionRegistry ()

/**
 * Map of names to action entries
 */
@property (nonatomic, strong) NSMutableDictionary *registeredActionEntries;

/**
 * An array of the reserved entry names
 */
@property (nonatomic, strong) NSMutableArray *reservedEntryNames;


/**
 * Registers a reserved action. Reserved actions can not be removed or modified.
 * @param action The action to be registered.
 * @param name The NSString name.
 * @param predicate The predicate.
 * @return `YES` if the action was registered, otherwise `NO`
 */
- (BOOL)registerReservedAction:(UAAction *)action
                          name:(NSString *)name
                     predicate:(nullable UAActionPredicate)predicate;

/**
 * Registers default actions.
 */
- (void)registerDefaultActions;

@end

NS_ASSUME_NONNULL_END