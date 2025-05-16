// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "./BaseTest.sol";
import {console2} from "forge-std/console2.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2Pool} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Pool.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public {
        startFork();
    }

    function testMintYap() public {
        yapPool.tokenA().approve(address(manager), 1e30);
        yapPool.tokenB().approve(address(manager), 1e30);

        IMaverickV2PoolLens.AddParamsSpecification memory addSpec = IMaverickV2PoolLens.AddParamsSpecification({
            slippageFactorD18: 0,
            numberOfPriceBreaksPerSide: 0,
            targetAmount: 100000,
            targetIsA: true
        });

        (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            ,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,

        ) = lens.getAddLiquidityParamsForBoostedPosition(yap, addSpec);

        (uint256 amountAq, uint256 amountBq, ) = quoter.calculateAddLiquidity(yapPool, addParams[0]);
        console2.log("Amount tokenA Required ", amountAq);
        console2.log("Amount tokenB Required ", amountBq);

        (uint256 amountMinted, uint256 amountA, uint256 amountB) = manager.addLiquidityAndMintBoostedPosition(
            this_,
            yap,
            packedSqrtPriceBreaks,
            packedArgs
        );
        console2.log("Yap amount minted ", amountMinted);
        console2.log("Amount tokenA Added ", amountA);
        console2.log("Amount tokenB Added ", amountB);

        //// REMOVE
        (amountA, amountB) = yap.burn(this_, amountMinted);

        console2.log("Amount tokenA Removed", amountA);
        console2.log("Amount tokenB Removed", amountB);
    }
}
