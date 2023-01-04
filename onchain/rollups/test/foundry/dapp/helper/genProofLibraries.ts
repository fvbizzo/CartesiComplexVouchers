import { BytesLike } from "@ethersproject/bytes";
import fs from "fs";
import epochStatus from "./epoch-status.json";

interface OutputValidityProof {
    outputIndex: number;
    outputHashesRootHash: BytesLike;
    vouchersEpochRootHash: BytesLike;
    noticesEpochRootHash: BytesLike;
    machineStateHash: BytesLike;
    keccakInHashesSiblings: BytesLike[];
    outputHashesInEpochSiblings: BytesLike[];
}

function setupVoucherProof(epochInputIndex: number): OutputValidityProof {
    let voucherDataKeccakInHashes =
        epochStatus.processedInputs[epochInputIndex].acceptedData.vouchers[0]
            .keccakInVoucherHashes;
    let voucherHashesInEpoch =
        epochStatus.processedInputs[epochInputIndex].voucherHashesInEpoch
            .siblingHashes;
    var siblingKeccakInHashesV: BytesLike[] = [];
    var voucherHashesInEpochSiblings: BytesLike[] = [];
    voucherDataKeccakInHashes.siblingHashes.forEach((element: any) => {
        siblingKeccakInHashesV.push(element.data);
    });
    voucherHashesInEpoch.forEach((element: any) => {
        voucherHashesInEpochSiblings.push(element.data);
    });
    let voucherProof: OutputValidityProof = {
        outputIndex: 0,
        outputHashesRootHash: voucherDataKeccakInHashes.rootHash.data,
        vouchersEpochRootHash: epochStatus.mostRecentVouchersEpochRootHash.data,
        noticesEpochRootHash: epochStatus.mostRecentNoticesEpochRootHash.data,
        machineStateHash: epochStatus.mostRecentMachineHash.data,
        keccakInHashesSiblings: siblingKeccakInHashesV.reverse(),
        outputHashesInEpochSiblings: voucherHashesInEpochSiblings.reverse(),
    };
    return voucherProof;
}

function setupNoticeProof(epochInputIndex: number): OutputValidityProof {
    let noticeDataKeccakInHashes =
        epochStatus.processedInputs[epochInputIndex].acceptedData.notices[0]
            .keccakInNoticeHashes;
    let noticeHashesInEpoch =
        epochStatus.processedInputs[epochInputIndex].noticeHashesInEpoch
            .siblingHashes;
    var siblingKeccakInHashesN: BytesLike[] = [];
    var noticeHashesInEpochSiblingsN: BytesLike[] = [];
    noticeDataKeccakInHashes.siblingHashes.forEach((element) => {
        siblingKeccakInHashesN.push(element.data);
    });
    noticeHashesInEpoch.forEach((element) => {
        noticeHashesInEpochSiblingsN.push(element.data);
    });
    let noticeProof: OutputValidityProof = {
        outputIndex: 0,
        outputHashesRootHash: noticeDataKeccakInHashes.rootHash.data,
        vouchersEpochRootHash: epochStatus.mostRecentVouchersEpochRootHash.data,
        noticesEpochRootHash: epochStatus.mostRecentNoticesEpochRootHash.data,
        machineStateHash: epochStatus.mostRecentMachineHash.data,
        keccakInHashesSiblings: siblingKeccakInHashesN.reverse(), // from top-down to bottom-up
        outputHashesInEpochSiblings: noticeHashesInEpochSiblingsN.reverse(),
    };
    return noticeProof;
}

function buildSolCodes(
    noticeProof: OutputValidityProof,
    voucherProof: OutputValidityProof,
    libraryName: string
): string {
    const array1 = noticeProof.keccakInHashesSiblings;
    const array2 = noticeProof.outputHashesInEpochSiblings;
    const array3 = voucherProof.keccakInHashesSiblings;
    const array4 = voucherProof.outputHashesInEpochSiblings;
    const lines: string[] = [
        "// SPDX-License-Identifier: UNLICENSED",
        "",
        "pragma solidity ^0.8.13;",
        "",
        "// THIS FILE WAS AUTOMATICALLY GENERATED BY `genProofLibraries.ts`.",
        "",
        'import {OutputValidityProof} from "contracts/library/LibOutputValidation.sol";',
        "",
        `library ${libraryName} {`,
        "    function getNoticeProof() internal pure returns (OutputValidityProof memory) {",
        `        uint256[${array1.length}] memory array1 = [${array1}];`,
        `        uint256[${array2.length}] memory array2 = [${array2}];`,
        `        bytes32[] memory keccakInHashesSiblings = new bytes32[](${array1.length});`,
        `        bytes32[] memory outputHashesInEpochSiblings = new bytes32[](${array2.length});`,
        `        for (uint256 i; i < ${array1.length}; ++i) { keccakInHashesSiblings[i] = bytes32(array1[i]); }`,
        `        for (uint256 i; i < ${array2.length}; ++i) { outputHashesInEpochSiblings[i] = bytes32(array2[i]); }`,
        `        return OutputValidityProof({`,
        `            outputIndex: ${noticeProof.outputIndex},`,
        `            outputHashesRootHash: ${noticeProof.outputHashesRootHash},`,
        `            vouchersEpochRootHash: ${noticeProof.vouchersEpochRootHash},`,
        `            noticesEpochRootHash: ${noticeProof.noticesEpochRootHash},`,
        `            machineStateHash: ${noticeProof.machineStateHash},`,
        "            keccakInHashesSiblings: keccakInHashesSiblings,",
        "            outputHashesInEpochSiblings: outputHashesInEpochSiblings",
        "        });",
        "    }",
        "    function getVoucherProof() internal pure returns (OutputValidityProof memory) {",
        `        uint256[${array3.length}] memory array3 = [${array3}];`,
        `        uint256[${array4.length}] memory array4 = [${array4}];`,
        `        bytes32[] memory keccakInHashesSiblings = new bytes32[](${array3.length});`,
        `        bytes32[] memory outputHashesInEpochSiblings = new bytes32[](${array4.length});`,
        `        for (uint256 i; i < ${array3.length}; ++i) { keccakInHashesSiblings[i] = bytes32(array3[i]); }`,
        `        for (uint256 i; i < ${array4.length}; ++i) { outputHashesInEpochSiblings[i] = bytes32(array4[i]); }`,
        `        return OutputValidityProof({`,
        `            outputIndex: ${voucherProof.outputIndex},`,
        `            outputHashesRootHash: ${voucherProof.outputHashesRootHash},`,
        `            vouchersEpochRootHash: ${voucherProof.vouchersEpochRootHash},`,
        `            noticesEpochRootHash: ${voucherProof.noticesEpochRootHash},`,
        `            machineStateHash: ${voucherProof.machineStateHash},`,
        "            keccakInHashesSiblings: keccakInHashesSiblings,",
        "            outputHashesInEpochSiblings: outputHashesInEpochSiblings",
        "        });",
        "    }",
        "}",
        "",
    ];
    return lines.join("\n");
}

epochStatus.processedInputs.forEach((_value: any, index: number) => {
    let libraryName = `LibOutputProof${index}`;
    let noticeProof = setupNoticeProof(index);
    let voucherProof = setupVoucherProof(index);
    let solidityCode = buildSolCodes(noticeProof, voucherProof, libraryName);
    let fileName = `${__dirname}/${libraryName}.sol`;
    fs.writeFile(fileName, solidityCode, (err: any) => {
        if (err) throw err;
        console.log(`File '${fileName}' was generated.`);
    });
});