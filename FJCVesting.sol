// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FJCVesting is Context, Ownable, ReentrancyGuard {

    error NotTransfered(address sender, uint256 needed);

    struct Vesting {
        uint80 until;
        uint256 amount;
        uint source;
        bool claimed;
    }
    mapping(address => Vesting[]) vestings;

    address public vestingToken;
    uint maxVestingTime = 3 * 365 days;

    constructor(address _vestingToken) Ownable(msg.sender) {
        vestingToken = _vestingToken;
    }

    function addVesting(
        address _beneficiary,
        uint256 _amount,
        uint80 _until,
        uint source
    ) public onlyOwner returns (bool) {
        address sender = _msgSender();

        vestings[_beneficiary].push(
            Vesting({
            until: _until,
            amount: _amount,
            claimed: false,
            source: source
        }));

        uint256 balanceBefore = IERC20(vestingToken).balanceOf(address(this));

        SafeERC20.safeTransferFrom(
            IERC20(vestingToken),
            sender,
            address(this),
            _amount
        );

        uint256 transferedAmount = IERC20(vestingToken).balanceOf(
            address(this)
        ) - balanceBefore;

        if (transferedAmount != _amount) {
            revert NotTransfered(sender, _amount);
        }

        return true;
    }

    function getVestings(
        address _beneficiary
    ) public view returns (Vesting[] memory) {
        return vestings[_beneficiary];
    }

    function Claim(uint index) external nonReentrant {
        address sender = _msgSender();
        require(vestings[sender].length > index, "Invalid Vesting Index");
        require(vestings[sender][index].claimed == false, "Allready Claimed");
        require(vestings[sender][index].until < block.timestamp, "Locked");
        SafeERC20.safeTransfer(
            IERC20(vestingToken),
            sender,
            vestings[sender][index].amount
        );
        
        vestings[sender][index].claimed = true;
    }
}
