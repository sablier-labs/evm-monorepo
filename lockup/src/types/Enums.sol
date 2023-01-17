// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

/// @notice Enum with all the possible statuses of a stream.
/// @custom:value NULL The stream has not been created yet. This is the default value.
/// @custom:value ACTIVE The stream has been created and it is active, meaning assets are being streamed.
/// @custom:value CANCELED The stream has been canceled by either the sender or the recipient.
/// @custom:value DEPLETED The stream has been depleted, meaning all assets have been withdrawn.
enum Status {
    NULL,
    ACTIVE,
    CANCELED,
    DEPLETED
}
