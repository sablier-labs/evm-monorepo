// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { NFTSVG } from "./../src/libraries/NFTSVG.sol";
import { SVGElements } from "./../src/libraries/SVGElements.sol";
import { LockupNFTDescriptor } from "./../src/LockupNFTDescriptor.sol";
import { BaseScript } from "././Base.s.sol";

/// @notice Generates an NFT SVG using the user-provided parameters.
contract GenerateSVG is BaseScript, LockupNFTDescriptor {
    using Strings for address;
    using Strings for string;

    address internal constant DAI = address(uint160(uint256(keccak256("DAI"))));
    address internal constant LOCKUP = address(uint160(uint256(keccak256("SablierLockup"))));

    /// @param progress The streamed amount as a numerical percentage with 4 implied decimals.
    /// @param status The status of the stream, as a string.
    /// @param amount The abbreviated deposited amount, as a string.
    /// @param duration The total duration of the stream in days, as a number.
    function run(
        uint256 progress,
        string memory status,
        string memory amount,
        uint256 duration
    )
        public
        view
        returns (string memory svg)
    {
        svg = NFTSVG.generateSVG(
            NFTSVG.SVGParams({
                accentColor: generateAccentColor({ sablier: LOCKUP, streamId: uint256(keccak256(msg.data)) }),
                amount: string.concat(SVGElements.SIGN_GE, " ", amount),
                tokenAddress: DAI.toHexString(),
                tokenSymbol: "DAI",
                duration: calculateDurationInDays({ startTime: 0, endTime: duration * 1 days }),
                progress: stringifyPercentage(progress),
                progressNumerical: progress,
                lockupAddress: LOCKUP.toHexString(),
                status: status
            })
        );
    }
}
