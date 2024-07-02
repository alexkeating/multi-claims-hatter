// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console2, Vm } from "forge-std/Test.sol";
import { MultiClaimsHatter } from "../src/MultiClaimsHatter.sol";
import { MultiClaimsHatterFactory } from "../src/MultiClaimsHatterFactory.sol";

contract TestMultiClaimsHatterFactory is Test {
  MultiClaimsHatterFactory factory;

  function setUp() public {
    factory = new MultiClaimsHatterFactory();
  }

  function testFuzz_deployMultiClaimsHatter(uint256 _hatId, address _hat, uint256 _saltNonce) public {
    address instance = factory.deployMultiClaimsHatter(_hatId, _hat, "", _saltNonce);
    address expectedAddress = factory._getAddress(_hatId, _hat, "", _saltNonce);
    console2.log("instance", instance);
    console2.log("expectedAddress", expectedAddress);
    assertEq(instance, expectedAddress);
  }
}
