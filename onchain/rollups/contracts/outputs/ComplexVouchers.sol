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

    function checkOrderedVoucher(
        address _destination,
        bytes calldata _payload,
        uint256 _inputIndex,
        uint256 _outputIndex
    ) external {
        //check if Previous voucher was executed
        bool ok = ICartesiDApp(dapp).wasVoucherExecuted(
            _inputIndex,
            _outputIndex
        );

        if (!ok) {
            revert OrderedVoucherNeedsPreviousVoucher();
        }

        // execute voucher
        (bool succ, ) = _destination.call(_payload);
        require(succ);
    }

    function checkPaidVoucher(
        address _destination,
        bytes calldata _payload,
        uint256 amount
    ) external payable {
        //execute the payable transfer

        (bool success, ) = tx.origin.call{value: amount}("");
        require(success, "failed to send payment");
        //execute voucher
        (bool succ, ) = _destination.call(_payload);
        require(succ);
    }

    function checkTargetedVoucher(
        address _destination,
        bytes calldata _payload,
        address[] calldata ValidAddress
    ) external {
        //check if address is valid for this voucher
        if (!_isAddressValid(ValidAddress)) {
            revert AddressNotValidForVoucher();
        }

        // execute voucher
        (bool succ, ) = _destination.call(_payload);
        require(succ);
    }

    function checkExpirableVoucher(
        address _destination,
        bytes calldata _payload,
        uint256 _expiryTime
    ) external {
        //check expirable date
        if (_expiryTime <= block.timestamp) {
            revert VoucherExpiredNotAllowed();
        }

        // execute voucher
        (bool succ, ) = _destination.call(_payload);
        require(succ);
    }

    function checkFutureVoucher(
        address _destination,
        bytes calldata _payload,
        uint256 _validDate
    ) external {
        //check if it is time so voucher can be executed
        if (block.timestamp < _validDate) {
            revert NotYetTimeForFutureVoucher();
        }

        // execute voucher
        (bool succ, ) = _destination.call(_payload);
        require(succ);
    }

    function executeAtomicVoucher(
        bytes[] calldata _payloads,
        address[] calldata _destinations
    ) external {
        //check if this is beign executed by CartesiDApp
        require(msg.sender == dapp);
        //check if there is the same amount of addresses and payloads
        require(_destinations.length == _payloads.length);
        // execute voucher sequence
        for (uint count = 0; count < _destinations.length; count++) {
            (bool succ, ) = _destinations[count].call(_payloads[count]);
            require(succ);
        }
    }
}
