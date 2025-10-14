// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable max-line-length,quotes
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ILockupNFTDescriptor } from "./interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockup } from "./interfaces/ISablierLockup.sol";
import { NFTSVG } from "./libraries/NFTSVG.sol";
import { SVGElements } from "./libraries/SVGElements.sol";
import { Lockup } from "./types/Lockup.sol";

/*

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗     ███╗   ██╗███████╗████████╗
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗    ████╗  ██║██╔════╝╚══██╔══╝
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝    ██╔██╗ ██║█████╗     ██║
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝     ██║╚██╗██║██╔══╝     ██║
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║         ██║ ╚████║██║        ██║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝         ╚═╝  ╚═══╝╚═╝        ╚═╝

██████╗ ███████╗███████╗ ██████╗██████╗ ██╗██████╗ ████████╗ ██████╗ ██████╗
██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
██║  ██║█████╗  ███████╗██║     ██████╔╝██║██████╔╝   ██║   ██║   ██║██████╔╝
██║  ██║██╔══╝  ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ██║   ██║██╔══██╗
██████╔╝███████╗███████║╚██████╗██║  ██║██║██║        ██║   ╚██████╔╝██║  ██║
╚═════╝ ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝    ╚═════╝ ╚═╝  ╚═╝

*/

/// @title LockupNFTDescriptor
/// @notice See the documentation in {ILockupNFTDescriptor}.
contract LockupNFTDescriptor is ILockupNFTDescriptor {
    using Strings for address;
    using Strings for string;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Needed to avoid Stack Too Deep.
    struct TokenURIVars {
        address token;
        string tokenSymbol;
        uint128 depositedAmount;
        string json;
        ISablierLockup lockup;
        string lockupStringified;
        string status;
        string svg;
        uint256 streamedPercentage;
    }

    /// @inheritdoc ILockupNFTDescriptor
    function tokenURI(IERC721Metadata lockup, uint256 streamId) external view override returns (string memory uri) {
        TokenURIVars memory vars;

        // Load the contracts.
        vars.lockup = ISablierLockup(address(lockup));
        vars.lockupStringified = address(lockup).toHexString();
        vars.depositedAmount = vars.lockup.getDepositedAmount(streamId);

        // Retrieve the underlying token contract's address.
        vars.token = address(vars.lockup.getUnderlyingToken(streamId));
        vars.tokenSymbol = safeTokenSymbol(vars.token);

        // Load the stream's data.
        vars.status = stringifyStatus(vars.lockup.statusOf(streamId));
        vars.streamedPercentage = calculateStreamedPercentage({
            streamedAmount: vars.lockup.streamedAmountOf(streamId),
            depositedAmount: vars.depositedAmount
        });

        // Generate the SVG.
        vars.svg = NFTSVG.generateSVG(
            NFTSVG.SVGParams({
                accentColor: generateAccentColor(address(lockup), streamId),
                amount: abbreviateAmount({ amount: vars.depositedAmount, decimals: safeTokenDecimals(vars.token) }),
                tokenAddress: vars.token.toHexString(),
                tokenSymbol: vars.tokenSymbol,
                duration: calculateDurationInDays({
                    startTime: vars.lockup.getStartTime(streamId),
                    endTime: vars.lockup.getEndTime(streamId)
                }),
                lockupAddress: vars.lockupStringified,
                progress: stringifyPercentage(vars.streamedPercentage),
                progressNumerical: vars.streamedPercentage,
                status: vars.status
            })
        );

        // Generate the JSON metadata.
        vars.json = string.concat(
            '{"attributes":',
            generateAttributes({
                tokenSymbol: vars.tokenSymbol,
                sender: vars.lockup.getSender(streamId).toHexString(),
                status: vars.status
            }),
            ',"description":"',
            generateDescription({
                tokenSymbol: vars.tokenSymbol,
                lockupStringified: vars.lockupStringified,
                tokenAddress: vars.token.toHexString(),
                streamId: streamId.toString(),
                isTransferable: vars.lockup.isTransferable(streamId)
            }),
            '","external_url":"https://sablier.com","name":"',
            string.concat("Sablier Lockup #", streamId.toString()),
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(vars.svg)),
            '"}'
        );

        // Encode the JSON metadata in Base64.
        uri = string.concat("data:application/json;base64,", Base64.encode(bytes(vars.json)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates an abbreviated representation of the provided amount, rounded down and prefixed with ">= ".
    /// @dev The abbreviation uses these suffixes:
    /// - "K" for thousands
    /// - "M" for millions
    /// - "B" for billions
    /// - "T" for trillions
    /// For example, if the input is 1,234,567, the output is ">= 1.23M".
    /// @param amount The amount to abbreviate, denoted in units of `decimals`.
    /// @param decimals The number of decimals to assume when abbreviating the amount.
    /// @return abbreviation The abbreviated representation of the provided amount, as a string.
    function abbreviateAmount(uint256 amount, uint256 decimals) internal pure returns (string memory) {
        if (amount == 0) {
            return "0";
        }

        uint256 truncatedAmount;
        unchecked {
            truncatedAmount = decimals == 0 ? amount : amount / 10 ** decimals;
        }

        // Return dummy values when the truncated amount is either very small or very big.
        if (truncatedAmount < 1) {
            return string.concat(SVGElements.SIGN_LT, " 1");
        } else if (truncatedAmount >= 1e15) {
            return string.concat(SVGElements.SIGN_GT, " 999.99T");
        }

        string[5] memory suffixes = ["", "K", "M", "B", "T"];
        uint256 fractionalAmount;
        uint256 suffixIndex = 0;

        // Truncate repeatedly until the amount is less than 1000.
        unchecked {
            while (truncatedAmount >= 1000) {
                fractionalAmount = (truncatedAmount / 10) % 100; // keep the first two digits after the decimal point
                truncatedAmount /= 1000;
                suffixIndex += 1;
            }
        }

        // Concatenate the calculated parts to form the final string.
        string memory prefix = string.concat(SVGElements.SIGN_GE, " ");
        string memory wholePart = truncatedAmount.toString();
        string memory fractionalPart = stringifyFractionalAmount(fractionalAmount);
        return string.concat(prefix, wholePart, fractionalPart, suffixes[suffixIndex]);
    }

    /// @notice Calculates the stream's duration in days, rounding down.
    function calculateDurationInDays(uint256 startTime, uint256 endTime) internal pure returns (string memory) {
        uint256 durationInDays;
        unchecked {
            durationInDays = (endTime - startTime) / 1 days;
        }

        // Return dummy values when the duration is either very small or very big.
        if (durationInDays == 0) {
            return string.concat(SVGElements.SIGN_LT, " 1 Day");
        } else if (durationInDays > 9999) {
            return string.concat(SVGElements.SIGN_GT, " 9999 Days");
        }

        string memory suffix = durationInDays == 1 ? " Day" : " Days";
        return string.concat(durationInDays.toString(), suffix);
    }

    /// @notice Calculates how much of the deposited amount has been streamed so far, as a percentage with 4 implied
    /// decimals.
    function calculateStreamedPercentage(
        uint128 streamedAmount,
        uint128 depositedAmount
    )
        internal
        pure
        returns (uint256)
    {
        // This cannot overflow because both inputs are uint128s, and zero deposit amounts are not allowed in Sablier.
        unchecked {
            return uint256(streamedAmount) * 10_000 / depositedAmount;
        }
    }

    /// @notice Generates a pseudo-random HSL color by hashing together the `chainid`, the `sablier` address,
    /// and the `streamId`. This will be used as the accent color for the SVG.
    function generateAccentColor(address sablier, uint256 streamId) internal view returns (string memory) {
        // The chain ID is part of the hash so that the generated color is different across chains.
        uint256 chainId = block.chainid;

        // Hash the parameters to generate a pseudo-random bit field, which will be used as entropy.
        // | Hue     | Saturation | Lightness | -> Roles
        // | [31:16] | [15:8]     | [7:0]     | -> Bit positions
        uint32 bitField = uint32(uint256(keccak256(abi.encodePacked(chainId, sablier, streamId))));

        unchecked {
            // The hue is a degree on a color wheel, so its range is [0, 360).
            // Shifting 16 bits to the right means using the bits at positions [31:16].
            uint256 hue = (bitField >> 16) % 360;

            // The saturation is a percentage where 0% is grayscale and 100%, but here the range is bounded to [20,100]
            // to make the colors more lively.
            // Shifting 8 bits to the right and applying an 8-bit mask means using the bits at positions [15:8].
            uint256 saturation = ((bitField >> 8) & 0xFF) % 80 + 20;

            // The lightness is typically a percentage between 0% (black) and 100% (white), but here the range
            // is bounded to [30,100] to avoid dark colors.
            // Applying an 8-bit mask means using the bits at positions [7:0].
            uint256 lightness = (bitField & 0xFF) % 70 + 30;

            // Finally, concatenate the HSL values to form an SVG color string.
            return string.concat("hsl(", hue.toString(), ",", saturation.toString(), "%,", lightness.toString(), "%)");
        }
    }

    /// @notice Generates an array of JSON objects that represent the NFT's attributes:
    /// - Token symbol
    /// - Sender address
    /// - Status
    /// @dev These attributes are useful for filtering and sorting the NFTs.
    function generateAttributes(
        string memory tokenSymbol,
        string memory sender,
        string memory status
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '[{"trait_type":"Token","value":"',
            tokenSymbol,
            '"},{"trait_type":"Sender","value":"',
            sender,
            '"},{"trait_type":"Status","value":"',
            status,
            '"}]'
        );
    }

    /// @notice Generates a string with the NFT's JSON metadata description, which provides a high-level overview.
    function generateDescription(
        string memory tokenSymbol,
        string memory lockupStringified,
        string memory tokenAddress,
        string memory streamId,
        bool isTransferable
    )
        internal
        pure
        returns (string memory)
    {
        // Depending on the transferability of the NFT, declare the relevant information.
        string memory info = isTransferable
            ?
            unicode"⚠️ WARNING: Transferring the NFT makes the new owner the recipient of the stream. The funds are not automatically withdrawn for the previous recipient."
            : unicode"❕INFO: This NFT is non-transferable. It cannot be sold or transferred to another account.";

        return string.concat(
            "This NFT represents a stream in a Sablier Lockup contract. The owner of this NFT can withdraw the streamed tokens, which are denominated in ",
            tokenSymbol,
            ".\\n\\n- Stream ID: ",
            streamId,
            "\\n- ",
            "Sablier Lockup Address: ",
            lockupStringified,
            "\\n- ",
            tokenSymbol,
            " Address: ",
            tokenAddress,
            "\\n\\n",
            info
        );
    }

    /// @notice Checks whether the provided string contains only alphanumeric characters, spaces, and dashes.
    /// @dev Note that this returns true for empty strings.
    function isAllowedCharacter(string memory str) internal pure returns (bool) {
        // Convert the string to bytes to iterate over its characters.
        bytes memory b = bytes(str);

        uint256 length = b.length;
        for (uint256 i = 0; i < length; ++i) {
            bytes1 char = b[i];

            // Check if it's a space, dash, or an alphanumeric character.
            bool isSpace = char == 0x20; // space
            bool isDash = char == 0x2D; // dash
            bool isDigit = char >= 0x30 && char <= 0x39; // 0-9
            bool isUppercaseLetter = char >= 0x41 && char <= 0x5A; // A-Z
            bool isLowercaseLetter = char >= 0x61 && char <= 0x7A; // a-z
            if (!(isSpace || isDash || isDigit || isUppercaseLetter || isLowercaseLetter)) {
                return false;
            }
        }
        return true;
    }

    /// @notice Retrieves the token's decimals safely, defaulting to "0" if an error occurs.
    /// @dev Performs a low-level call to handle tokens in which the decimals are not implemented.
    function safeTokenDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint8));
        } else {
            return 0;
        }
    }

    /// @notice Retrieves the token's symbol safely, defaulting to a hard-coded value if an error occurs.
    /// @dev Performs a low-level call to handle tokens in which the symbol is not implemented or it is a bytes32
    /// instead of a string.
    function safeTokenSymbol(address token) internal view returns (string memory) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeCall(IERC20Metadata.symbol, ()));

        // Non-empty strings have a length greater than 64, and bytes32 has length 32.
        if (!success || returnData.length <= 64) {
            return "ERC20";
        }

        string memory symbol = abi.decode(returnData, (string));

        // Check if the symbol is too long or contains disallowed characters. This measure helps mitigate potential
        // security threats from malicious tokens injecting scripts in the symbol string.
        if (bytes(symbol).length > 30) {
            return "Long Symbol";
        } else {
            if (!isAllowedCharacter(symbol)) {
                return "Unsupported Symbol";
            }
            return symbol;
        }
    }

    /// @notice Converts the provided fractional amount to a string prefixed by a dot.
    /// @param fractionalAmount A numerical value with 2 implied decimals.
    function stringifyFractionalAmount(uint256 fractionalAmount) internal pure returns (string memory) {
        // Return the empty string if the fractional amount is zero.
        if (fractionalAmount == 0) {
            return "";
        }
        // Add a leading zero if the fractional part is less than 10, e.g. for "1", this function returns ".01%".
        else if (fractionalAmount < 10) {
            return string.concat(".0", fractionalAmount.toString());
        }
        // Otherwise, stringify the fractional amount simply.
        else {
            return string.concat(".", fractionalAmount.toString());
        }
    }

    /// @notice Converts the provided percentage to a string.
    /// @param percentage A numerical value with 4 implied decimals.
    function stringifyPercentage(uint256 percentage) internal pure returns (string memory) {
        // Extract the last two decimals.
        string memory fractionalPart = stringifyFractionalAmount(percentage % 100);

        // Remove the last two decimals.
        string memory wholePart = (percentage / 100).toString();

        // Concatenate the whole and fractional parts.
        return string.concat(wholePart, fractionalPart, "%");
    }

    /// @notice Retrieves the stream's status as a string.
    function stringifyStatus(Lockup.Status status) internal pure returns (string memory) {
        if (status == Lockup.Status.DEPLETED) {
            return "Depleted";
        } else if (status == Lockup.Status.CANCELED) {
            return "Canceled";
        } else if (status == Lockup.Status.STREAMING) {
            return "Streaming";
        } else if (status == Lockup.Status.SETTLED) {
            return "Settled";
        } else {
            return "Pending";
        }
    }
}
