// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibLandStorage } from "../libs/LibLandStorage.sol";
import { LibAppStorage, AppStorage } from "../libs/LibAppStorage.sol";
//import { LibNFT } from "../libs/LibNFT.sol";
import { Land } from "../shared/Structs.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

library LibLand {

    /// @notice Generates coordinates for a given token ID using a quadrant spiral algorithm
    /// @param tokenId The ID of the token to calculate coordinates for
    /// @return x The calculated X coordinate
    /// @return y The calculated Y coordinate
    function landCalculateCoordinatesQuadrantSpiral(uint256 tokenId) public pure returns (int256 x, int256 y) {
        if (tokenId == 0) {
            return (0, 0);
        }

        int256[2][4] memory directions = [
            [int256(0), int256(1)],
            [int256(1), int256(0)],
            [int256(0), int256(-1)],
            [int256(-1), int256(0)]
        ]; // right, down, left, up
        uint256 directionIndex = 0;
        uint256 stepsInThisDirection = 1;
        uint256 stepsCount = 0;

        for (uint256 i = 0; i < tokenId; i++) {
            int256 dx = directions[directionIndex][0];
            int256 dy = directions[directionIndex][1];
            x += dx;
            y += dy;

            stepsCount++;

            if (stepsCount == stepsInThisDirection) {
                directionIndex = (directionIndex + 1) % 4;
                stepsCount = 0;

                // Increase steps every two direction changes
                if (directionIndex % 2 == 0) {
                    stepsInThisDirection++;
                }
            }
        }

        return (x, y);
    }

    /// @notice Assigns coordinates to a newly minted token
    /// @param tokenId The ID of the token to assign coordinates to
    function _landAssignCoordinates(uint256 tokenId) private {
        (int256 x, int256 y) = landCalculateCoordinatesQuadrantSpiral(tokenId);

        // Ensure coordinates are within bounds using custom errors
        if (x < _sN().minX || x > _sN().maxX) {
            revert NFTCoordinateOutOfBounds(x, "X");
        }
        if (y < _sN().minY || y > _sN().maxY) {
            revert NFTCoordinateOutOfBounds(y, "Y");
        }

        // Check if the coordinate is already occupied
        if (_sN().coordinateToTokenId[x][y] != 0) {
            revert NFTCoordinateOccupied(x, y);
        }

        // Assign coordinates
        _sN().tokenCoordinates[tokenId] = LibLandStorage.Coordinates(x, y, true);
        _sN().coordinateToTokenId[x][y] = tokenId;
    }

    /// @notice Assigns coordinates to a newly minted token
    /// @param tokenId The ID of the token to assign coordinates to
    function _AssignLand(uint256 tokenId) internal {
        _landAssignCoordinates(tokenId);
        _sN().mintDate[tokenId] = block.timestamp;
    }

    /// @notice Retrieves land information for a given token ID
    /// @param tokenId The ID of the token to retrieve land information for
    /// @return land The Land struct containing the land information
    function _getLand(uint256 tokenId) internal view returns (Land memory land) {
        require(IERC721(address(this)).exists(tokenId), "LibLand: Token does not exist");

        LibLandStorage.Data storage s = _sN();
        LibLandStorage.Coordinates memory coords = s.tokenCoordinates[tokenId];

        land.tokenId = tokenId;
        land.owner = IERC721(address(this)).ownerOf(tokenId);
        (land.coordinateX, land.coordinateY) = (coords.x, coords.y);
        land.name = s.name[tokenId];
        land.experiencePoints = s.experiencePoints[tokenId];
        land.accumulatedPlantPoints = s.accumulatedPlantPoints[tokenId];
        land.accumulatedPlantLifetime = s.accumulatedPlantLifetime[tokenId];


        land.tokenUri = ""; // TODO
        land.mintDate = s.mintDate[tokenId];
    }

    /// @notice Retrieves all lands owned by a specific address
    /// @param owner The address of the land owner
    /// @return lands An array of Land structs containing the land information
    function _getLandsByOwner(address owner) internal view returns (Land[] memory lands) {
        uint256 balance = IERC721(address(this)).balanceOf(owner);
        lands = new Land[](balance);

        uint256 landCount = 0;
        uint256 totalSupply = IERC721Enumerable(address(this)).totalSupply();

        for (uint256 tokenId = 1; tokenId <= totalSupply && landCount < balance; tokenId++) {
            if (IERC721(address(this)).ownerOf(tokenId) == owner) {
                lands[landCount] = _getLand(tokenId);
                landCount++;
            }
        }
    }

    /// @notice Internal function to access NFT storage
    /// @return data The LibLandStorage.Data struct
    function _sN() internal pure returns (LibLandStorage.Data storage data) {
        data = LibLandStorage.data();
    }

    /// @notice Internal function to access AppStorage
    /// @return data The AppStorage struct
    function _sA() internal pure returns (AppStorage storage data) {
        data = LibAppStorage.diamondStorage();
    }
}

error NFTCoordinateOutOfBounds(int256 coordinate, string axis);
error NFTCoordinateOccupied(int256 x, int256 y);