// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {ICartesiDApp} from "../dapp/ICartesiDApp.sol";

/// @title Complex Vouchers
/// @notice All complex vouchers functions can only be called by the ComplexVoucher contract itself except for the
/// AtomicVoucher function that can only be called by the Cartesi Dapp contract.
contract ComplexVouchers {
    address internal immutable dapp;

    /// @notice Raised when an ordered voucher execution is called without the requisite been executed.
    error OrderedVoucherNeedsPreviousVoucher();

    /// @notice Raised when an expirable voucher is executed after its expiration date.
    error VoucherExpiredNotAllowed();

    /// @notice Raised when an Future Voucher is executed before the correct time.
    error NotYetTimeForFutureVoucher();

    /// @notice Raised when a voucher is executed by an invalid address.
    error AddressNotValidForVoucher();

    /// Function to verify if the caller has permission to execute the voucher for Targeted vouchers.
    constructor(address _dappAddress) {
        dapp = _dappAddress;
    }

    modifier onlyDApp() {
        require(msg.sender == dapp);
        _;
    }

    /// @notice Check for valid addresses for targeted vouchers.
    /// @param validAddress The list of addresses which wich are allowed to execute this voucher
    /// @dev This function verifies if the tx.origin address that is trying to execute a targeted voucher has been set
    /// as a valid address.
    function _isAddressValid(
        address[] calldata validAddress
    ) public view returns (bool) {
        for (uint256 i; i < validAddress.length; i++) {
            if (validAddress[i] == tx.origin) {
                return true;
            }
        }
        return false;
    }

    /// @notice Check if previous voucher has been executed.
    /// @param _inputIndex index input that is used in the ICartesiDApp to verify if a voucher has been executed
    /// @param _outputIndex index output that is used in the ICartesiDApp to verify if a voucher has been executed
    /// @dev This function receives a voucher inputIndex and outputIndex and revert if the voucher has not been executed.
    function checkOrderedVoucher(
        uint256 _inputIndex,
        uint256 _outputIndex
    ) external view {
        // check if Previous voucher was executed
        bool ok = ICartesiDApp(dapp).wasVoucherExecuted(
            _inputIndex,
            _outputIndex
        );

        if (!ok) {
            revert OrderedVoucherNeedsPreviousVoucher();
        }
    }

    /// @notice A function that transfers ether to the tx.origin and can only be executed by this contract.
    /// @param amount Transfer amount
    /// @dev It receives an amount value and transfers it to the tx.origin.
    function checkPaidVoucher(
        uint256 amount
    ) external {
        // execute the paid transfer
        require(msg.sender == address(this));
        (bool success, ) = tx.origin.call{value: amount}("");
        require(success, "failed to send payment");
    }

    /// @notice A function that receives an array of addresses and revert if the tx.origin is not included in that array.
    /// @param ValidAddress Array of addresses that are permited to execute this voucher.
    /// @dev It receives an array of addresses and call an auxiliary function to check if the tx.origin address is listed
    /// in the array. Currently it assumes the array is not ordered.
    function checkTargetedVoucher(
        address[] calldata ValidAddress
    ) external view {
        // check if address is valid for this voucher
        if (!_isAddressValid(ValidAddress)) {
            revert AddressNotValidForVoucher();
        }
    }

    /// @notice A function that checks the time of expiration of an expirable voucher.
    /// @param _expiryTime voucher time of expiration.
    /// @dev It checks if the execution atempt is before the voucher's expiration date.
    function checkExpirableVoucher(
        uint256 _expiryTime
    ) external view {
        // check expirable date
        if (_expiryTime <= block.timestamp) {
            revert VoucherExpiredNotAllowed();
        }
    }

    /// @notice A function that checks the time of activation of a future voucher.
    /// @param _validDate voucher time of activation.
    /// @dev It checks if the execution atempt is after the voucher's activation date.
    function checkFutureVoucher(
        uint256 _validDate
    ) external view {
        // check if it is time so voucher can be executed
        if (block.timestamp < _validDate) {
            revert NotYetTimeForFutureVoucher();
        }
    }

    /// @notice The main function of this contract it is called directly and only by the Dapp and executes all combinations
    /// of complex vouchers.
    /// @param _destinations Array of addresses with the destination of each payload.
    /// @param _payloads Array of payloads that are to be executed by the voucher.
    /// @dev This function receives 2 arrays that need to have the same size. It executes the payloads in order and
    /// it reverts if at least one payload cant be executed.
    function executeAtomicVoucher(
        address[] calldata _destinations,
        bytes[] calldata _payloads
    ) external onlyDApp {
        // check if there is the same amount of addresses and payloads
        require(_destinations.length == _payloads.length);
        // execute voucher sequence
        for (uint count = 0; count < _destinations.length; count++) {
            (bool succ, ) = _destinations[count].call(_payloads[count]);
            require(succ);
        }
    }
}
