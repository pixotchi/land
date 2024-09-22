// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibWareHouse } from "../libs/LibWareHouse.sol";
import "../shared/Structs.sol";
import { AccessControl2 } from "../libs/libAccessControl2.sol";

/// @title WareHouseFacet
/// @notice Manages warehouse operations for plant points and lifetime assignments
/// @dev Inherits from AccessControl2 for access control functionality
contract WareHouseFacet is AccessControl2 {
  /// @notice Assigns plant points to a specific plant on a land
  /// @param _landId The ID of the land where the plant is located
  /// @param _plantId The ID of the plant to assign points to
  /// @param _addedPoints The number of points to add
  /// @return _newPlantPoints The updated total plant points for the plant
  function wareHouseAssignPlantPoints(
    uint256 _landId,
    uint256 _plantId,
    uint256 _addedPoints
  ) external isApproved(_landId) returns (uint256 _newPlantPoints) {
    return LibWareHouse.landToPlantAssignPlantPoints(_landId, _plantId, _addedPoints);
  }

  /// @notice Assigns lifetime to a specific plant on a land
  /// @param _landId The ID of the land where the plant is located
  /// @param _plantId The ID of the plant to assign lifetime to
  /// @param _lifetime The lifetime value to assign
  /// @return _newLifetime The updated lifetime for the plant
  function wareHouseAssignLifeTime(
    uint256 _landId,
    uint256 _plantId,
    uint256 _lifetime
  ) external isApproved(_landId) returns (uint256 _newLifetime) {
    return LibWareHouse.landToPlantAssignLifeTime(_landId, _plantId, _lifetime);
  }
}
