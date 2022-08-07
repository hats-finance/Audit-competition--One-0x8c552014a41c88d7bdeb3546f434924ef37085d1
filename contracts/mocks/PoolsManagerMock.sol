// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../HATVaultsRegistry.sol";
import "../RewardController.sol";

//this contract is used as an helper contract only for testing purpose

contract PoolsManagerMock {

    function createVaults(HATVaultsRegistry _hatVaults,
                    IRewardController _rewardController,
                    uint256 _allocPoint,
                    IERC20[] memory _lpTokens,
                    address _committee,
                    uint256 _maxBounty,
                    HATVault.BountySplit memory _bountySplit,
                    string memory _descriptionHash,
                    uint256[2] memory _bountyVestingParams) external {

        for (uint256 i=0; i < _lpTokens.length; i++) {
            address vault = _hatVaults.createVault(_lpTokens[i],
                                _committee,
                                _rewardController,
                                _maxBounty,
                                _bountySplit,
                                _descriptionHash,
                                _bountyVestingParams,
                                false);
            _rewardController.setAllocPoint(vault, _allocPoint);
        }
    }

    function updateVaultsInfo(HATVault[] memory _hatVaults,
                    IRewardController _rewardController,
                    uint256 _allocPoint,
                    bool _registered,
                    bool _depositPause,
                    string memory _descriptionHash) external {

        for (uint256 i=0; i < _hatVaults.length; i++) {
            _hatVaults[i].updateVaultInfo(_registered,
                            _depositPause,
                            _descriptionHash);
            _rewardController.setAllocPoint(address(_hatVaults[i]), _allocPoint);
        }
    }

    function claimRewardTwice(RewardController target, address _vault) external {
        target.claimReward(_vault);
        target.claimReward(_vault);
    }

    function deposit(HATVault _target, IERC20 _lpToken, uint256 _amount) external {
        _lpToken.approve(address(_target), _amount);
        _target.deposit(_amount);
    }

    function depositTwice(HATVault _target, IERC20 _lpToken, uint256 _amount) external {
        _lpToken.approve(address(_target), _amount * 2);
        _target.deposit(_amount);
        _target.deposit(_amount);
    }

    function claimDifferentPids(RewardController _target, address[] memory _vaults) external {
        uint256 i;
        for (i = 0; i < _vaults.length; i++) {
            _target.claimReward(_vaults[i]);
        }
    }

}
