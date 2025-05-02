// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ILegendaryForge
/// @notice Interface for the LegendaryForge contract
interface ILegendaryForge {
    struct LegendaryRecipe {
        uint256[] baseEquipmentIds;
        uint256[] materialIds;
        address[] lpTokens;
        uint256[] lpAmounts;
        uint256 forgingTime;
        uint256 minCombatScore;
        uint256 resultingItemId;
        bool active;
    }

    struct ForgingProcess {
        address owner;
        uint256 recipeId;
        uint256 startTime;
        bool materialsLocked;
        bool completed;
    }

    event RecipeCreated(uint256 indexed recipeId, uint256 indexed resultingItemId);
    event ForgingStarted(uint256 indexed forgingId, address indexed player, uint256 indexed recipeId);
    event MaterialsLocked(uint256 indexed forgingId, address indexed player);
    event ForgingCompleted(uint256 indexed forgingId, address indexed player, uint256 indexed itemId);
    event RecipeActivated(uint256 indexed recipeId, bool active);

    function createRecipe(
        uint256[] calldata baseEquipmentIds,
        uint256[] calldata materialIds,
        address[] calldata lpTokens,
        uint256[] calldata lpAmounts,
        uint256 forgingTime,
        uint256 minCombatScore,
        uint256 resultingItemId
    ) external;

    function startForging(uint256 recipeId) external;
    function lockMaterials(uint256 forgingId) external;
    function completeForging(uint256 forgingId) external;
    function getPlayerForgings(address player) external view returns (uint256[] memory);
    function setRecipeActive(uint256 recipeId, bool active) external;
} 