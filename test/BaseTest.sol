// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMaverickV2Pool} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Pool.sol";
import {IMaverickV2Factory} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Factory.sol";
import {IMaverickV2LiquidityManager} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2LiquidityManager.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2Quoter} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Quoter.sol";
import {IMaverickV2Router} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Router.sol";
import {IMaverickV2Position} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2Position.sol";
import {IMaverickV2BoostedPositionFactory} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2BoostedPositionFactory.sol";
import {IMaverickV2BoostedPosition} from "@maverick/v2-interfaces/contracts/interfaces/IMaverickV2BoostedPosition.sol";

abstract contract BaseTest is Test {
    IMaverickV2Factory internal factory;

    IMaverickV2Pool public pool;
    IMaverickV2Pool public yapPool;
    IERC20 public weth;
    IERC20 public wplume;
    IMaverickV2BoostedPosition public yap;

    IMaverickV2LiquidityManager public manager =
        IMaverickV2LiquidityManager(payable(0xc66e75Fa945fcBdF10f966faa37185204D849BF4));
    IMaverickV2PoolLens public lens = IMaverickV2PoolLens(0xBf0D89E67351f68a0a921943332c5bE0f7a0FF8A);
    IMaverickV2Quoter public quoter = IMaverickV2Quoter(0xf245948e9cf892C351361d298cc7c5b217C36D82);
    IMaverickV2Router public router = IMaverickV2Router(payable(0x35e44dc4702Fd51744001E248B49CBf9fcc51f0C));
    IMaverickV2Position public position = IMaverickV2Position(0x0b452E8378B65FD16C0281cfe48Ed9723b8A1950);
    IMaverickV2BoostedPositionFactory public yapFactory =
        IMaverickV2BoostedPositionFactory(0x62914C093bf76a3f4388b49d268a38f1B4938A73);

    address public this_;

    function startFork() internal {
        vm.selectFork(vm.createFork("https://rpc.plume.org", 2126017));
        factory = IMaverickV2Factory(0x056A588AfdC0cdaa4Cab50d8a4D2940C5D04172E);
        pool = factory.lookup(0, 1)[0];
        wplume = pool.tokenA();
        weth = pool.tokenB();
        console2.log("Pool TokenA", IERC20Metadata(address(wplume)).symbol());
        console2.log("Pool TokenB", IERC20Metadata(address(weth)).symbol());
        this_ = address(this);

        deal(address(weth), this_, 1e20);
        deal(address(wplume), this_, 1e20);

        yap = yapFactory.lookup(0, 1)[0];
        yapPool = yap.pool();
        console2.log(yap.name());
        console2.log("Yap TokenA", IERC20Metadata(address(yapPool.tokenA())).symbol());
        console2.log("Yap TokenB", IERC20Metadata(address(yapPool.tokenB())).symbol());
        deal(address(yapPool.tokenA()), this_, 1e20);
        deal(address(yapPool.tokenB()), this_, 1e20);
    }

    // returns flat liquidity distribution +/- 2 ticks from the active tick
    function _getTickAndRelativeLiquidity(
        uint128 liquidityAmount,
        IMaverickV2Pool _pool
    ) internal view returns (int32[] memory ticks, uint128[] memory relativeLiquidityAmounts) {
        int32 activeTick = _pool.getState().activeTick;
        ticks = new int32[](5);
        (ticks[0], ticks[1], ticks[2], ticks[3], ticks[4]) = (
            activeTick - 2,
            activeTick - 1,
            activeTick,
            activeTick + 1,
            activeTick + 2
        );

        // relative liquidity amounts are in the liquidity domain, not the LP
        // balance domain. i.e. these are the values a user might input into
        // the addLiquidity bar-graph screen in the app.mav.xyz app.  the scale
        // is relative, but larger numbers are better as they allow more
        // precision in the deltaLPBalance calculation.
        relativeLiquidityAmounts = new uint128[](5);
        (
            relativeLiquidityAmounts[0],
            relativeLiquidityAmounts[1],
            relativeLiquidityAmounts[2],
            relativeLiquidityAmounts[3],
            relativeLiquidityAmounts[4]
        ) = (liquidityAmount, liquidityAmount, liquidityAmount, liquidityAmount, liquidityAmount);
    }
}
