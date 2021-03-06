/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAAPIClient.h"

@class UAChannelRegistrationPayload;
@class UARuntimeConfig;

NS_ASSUME_NONNULL_BEGIN

/**
 * A block called when the channel ID creation succeeded.
 *
 * @param channelID The channel identifier string.
 * @param existing Boolean to indicate if the channel previously existed or not.
 */
typedef void (^UAChannelAPIClientCreateSuccessBlock)(NSString *channelID, BOOL existing);

/**
 * A block called when the channel update succeeded.
 */
typedef void (^UAChannelAPIClientUpdateSuccessBlock)(void);

/**
 * A block called when the channel creation or update failed.
 *
 * @param statusCode The request status code.
 */
typedef void (^UAChannelAPIClientFailureBlock)(NSUInteger statusCode);

/**
 * A high level abstraction for performing Channel API creation and updates.
 */
@interface UAChannelAPIClient : UAAPIClient

///---------------------------------------------------------------------------------------
/// @name Channel API Client Internal Methods
///---------------------------------------------------------------------------------------

/**
 * Factory method to create a UAChannelAPIClient.
 * @param config The Airship config.
 * @return UAChannelAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UARuntimeConfig *)config;

/**
 * Factory method to create a UAChannelAPIClient.
 * @param config The Airship config.
 * @param session The UARequestSession instance.
 * @return UAChannelAPIClient instance.
 */
+ (instancetype)clientWithConfig:(UARuntimeConfig *)config session:(UARequestSession *)session;

/**
 * Create the channel ID.
 *
 * @param payload An instance of UAChannelRegistrationPayload.
 * @param successBlock A UAChannelAPIClientCreateSuccessBlock that will be called
 *        if the channel ID was created successfully.
 * @param failureBlock A UAChannelAPIClientFailureBlock that will be called if
 *        the channel ID creation was unsuccessful.
 *
 */
- (void)createChannelWithPayload:(UAChannelRegistrationPayload *)payload
                      onSuccess:(UAChannelAPIClientCreateSuccessBlock)successBlock
                      onFailure:(UAChannelAPIClientFailureBlock)failureBlock;

/**
 * Update the channel.
 *
 * @param channelID The channel identifier.
 * @param payload An instance of UAChannelRegistrationPayload.
 * @param successBlock A UAChannelAPIClientUpdateSuccessBlock that will be called
 *        if the channel was updated successfully.
 * @param failureBlock A UAChannelAPIClientFailureBlock that will be called if
 *        the channel update was unsuccessful.
 *
 */
- (void)updateChannelWithID:(NSString *)channelID
                withPayload:(UAChannelRegistrationPayload *)payload
                  onSuccess:(UAChannelAPIClientUpdateSuccessBlock)successBlock
                  onFailure:(UAChannelAPIClientFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
