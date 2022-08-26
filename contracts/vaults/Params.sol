// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Base.sol";

contract Params is Base {

    /**
    * @notice Set new committee address. Can be called by existing committee,
    * or by the governance in the case that the committee hadn't checked in
    * yet.
    * @param _committee The address of the new committee 
    */
    function setCommittee(address _committee)
    external {
        // governance can update committee only if committee was not checked in yet.
        if (msg.sender == owner() && committee != msg.sender) {
            if (committeeCheckedIn)
                revert CommitteeAlreadyCheckedIn();
        } else {
            if (committee != msg.sender) revert OnlyCommittee();
        }

        committee = _committee;

        emit SetCommittee(_committee);
    }

    /**
    * @notice Called by governance to set the vesting params for the part of
    * the bounty that the hacker gets vested in the vault's native token
    * @param _duration Duration of the vesting period. Must be smaller than
    * 120 days and bigger than `_periods`
    * @param _periods Number of vesting periods. Cannot be 0.
    */
    function setVestingParams(uint256 _duration, uint256 _periods) external onlyOwner {
        _setVestingParams(_duration, _periods);
    }

    function _setVestingParams(uint256 _duration, uint256 _periods) internal {
        if (_duration > 120 days) revert VestingDurationTooLong();
        if (_periods == 0) revert VestingPeriodsCannotBeZero();
        if (_duration < _periods) revert VestingDurationSmallerThanPeriods();
        vestingDuration = _duration;
        vestingPeriods = _periods;
        emit SetVestingParams(_duration, _periods);
    }

    /**
    * @notice Called by the vault's owner to set the vault token bounty split
    * upon an approval.
    * Can only be called if is no active claim and not during safety periods.
    * @param _bountySplit The bounty split
    */
    function setBountySplit(BountySplit memory _bountySplit)
    external
    onlyOwner noActiveClaim noSafetyPeriod {
        validateSplit(_bountySplit);
        bountySplit = _bountySplit;
        emit SetBountySplit(_bountySplit);
    }

    /**
    * @notice Called by the fee setter to set the fee for withdrawals from the
    * vault.
    * @param _fee The new fee. Must be smaller then `MAX_FEE`
    */
    function setWithdrawalFee(uint256 _fee) external onlyFeeSetter {
        if (_fee > MAX_FEE) revert WithdrawalFeeTooBig();
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    /**
    * @notice Called by the vault's committee to claim it's role.
    * Deposits are enabled only after committee check in.
    */
    function committeeCheckIn() external onlyCommittee {
        committeeCheckedIn = true;
        emit CommitteeCheckedIn();
    }

    /**
    * @notice Called by the vault's owner to set a pending request for the
    * maximum percentage of the vault that can be paid out as a bounty.
    * Cannot be called if there is an active claim that has been submitted.
    * Max bounty should be less than or equal to `HUNDRED_PERCENT`.
    * The pending value can later be set after the time delay (of 
    * HATVaultsRegistry.GeneralParameters.setMaxBountyDelay) had passed.
    * Max bounty should be less than or equal to `MAX_BOUNTY_LIMIT`
    * @param _maxBounty The maximum bounty percentage that can be paid out
    */
    function setPendingMaxBounty(uint256 _maxBounty)
    external
    onlyOwner noActiveClaim {
        if (_maxBounty > MAX_BOUNTY_LIMIT)
            revert MaxBountyCannotBeMoreThanMaxBountyLimit();
        pendingMaxBounty.maxBounty = _maxBounty;
        // solhint-disable-next-line not-rely-on-time
        pendingMaxBounty.timestamp = block.timestamp;
        emit SetPendingMaxBounty(_maxBounty, pendingMaxBounty.timestamp);
    }

    /**
    * @notice Called by the vault's owner to set the vault's max bounty to
    * the already pending max bounty.
    * Cannot be called if there are active claims that have been submitted.
    * Can only be called if there is a max bounty pending approval, and the
    * time delay since setting the pending max bounty had passed.
    * Max bounty should be less than or equal to `MAX_BOUNTY_LIMIT`
    */
    function setMaxBounty() external onlyOwner noActiveClaim {
        if (pendingMaxBounty.timestamp == 0) revert NoPendingMaxBounty();

        HATVaultsRegistry.GeneralParameters memory generalParameters = registry.getGeneralParameters();

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - pendingMaxBounty.timestamp <
            generalParameters.setMaxBountyDelay)
            revert DelayPeriodForSettingMaxBountyHadNotPassed();
        maxBounty = pendingMaxBounty.maxBounty;
        delete pendingMaxBounty;
        emit SetMaxBounty(maxBounty);
    }

    /**
    * @notice Called by governance to disable all deposits to the vault
    * @param _depositPause Are deposits paused
    */
    function setDepositPause(bool _depositPause) external onlyOwner {
        depositPause = _depositPause;
        emit SetDepositPause(_depositPause);
    }

    /**
    * @notice change the description of the vault
    * only calleable by the owner of the vault
    * @param _descriptionHash the hash of the vault's description.
    */
    function setVaultDescription(string memory _descriptionHash) external onlyOwner {
        emit SetVaultDescription(_descriptionHash);
    }

    /**
    * @notice Called by vault's owner to set the vault's reward controller
    * @param _newRewardController The new reward controller
    */
    function setRewardController(IRewardController _newRewardController) external onlyOwner {
        rewardController = _newRewardController;
        emit SetRewardController(_newRewardController);
    }

    /**
    * @notice Called by governance to set the vault HAT token bounty split upon
    * an approval. Either sets it to the value passed, marking the useVaultSpecific flags to
    * as true, or make the vault always use the default value.
    * @param _hatBountySplitConfig The HAT bounty split config
    */
    function setHATBountySplitConfig(HATBountySplitConfig memory _hatBountySplitConfig) external onlyRegistryOwner {
        if (_hatBountySplitConfig.useVaultSpecific) {
            registry.validateHATSplit(_hatBountySplitConfig.hatBountySplit);
            hatBountySplitConfig = _hatBountySplitConfig;
        } else {
            delete hatBountySplitConfig;
            (uint256 governanceHat, uint256 hackerHatVested) = registry.defaultHATBountySplit();
            _hatBountySplitConfig = HATBountySplitConfig({
                hatBountySplit: HATVaultsRegistry.HATBountySplit({
                    governanceHat: governanceHat,
                    hackerHatVested: hackerHatVested
                }),
                useVaultSpecific: false
            });
        }

        emit SetHATBountySplitConfig(_hatBountySplitConfig);
    }

    /**
    * @notice Called by governance to set the vault arbitration configurations
    * @param _arbitrationConfig The vault's arbitration configurations
    */
    function setArbitrationConfig(ArbitrationConfig memory _arbitrationConfig) external onlyRegistryOwner {
        if (_arbitrationConfig.useVaultSpecific) {
            registry.validateChallengePeriod(_arbitrationConfig.challengePeriod);
            registry.validateChallengeTimeOutPeriod(_arbitrationConfig.challengeTimeOutPeriod);
            arbitrationConfig = _arbitrationConfig;
        } else {
            delete arbitrationConfig;
            _arbitrationConfig = ArbitrationConfig({
                arbitrator: registry.defaultArbitrator(),
                challengePeriod: registry.defaultChallengePeriod(),
                challengeTimeOutPeriod: registry.defaultChallengeTimeOutPeriod(),
                useVaultSpecific: false
            });
        }
        
        emit SetArbitrationConfig(_arbitrationConfig);
    }
}