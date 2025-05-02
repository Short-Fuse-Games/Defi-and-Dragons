// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Equipment.sol";
import "../interfaces/Types.sol";
import "../amm/ArcaneCrafting.sol";
import "../CombatQuest.sol";

/// @title LegendaryForge
/// @notice Handles the creation of legendary equipment through a complex forging process
contract LegendaryForge is Ownable, ReentrancyGuard {
    // Core contracts
    Equipment public immutable equipment;
    ArcaneCrafting public immutable arcaneCrafting;
    CombatQuest public immutable combatQuest;

    // Structs
    struct LegendaryRecipe {
        uint256[] baseEquipmentIds;     // Required base equipment
        uint256[] materialIds;          // Required special materials
        address[] lpTokens;             // Required LP tokens
        uint256[] lpAmounts;            // Required LP amounts
        uint256 forgingTime;            // Time required to forge (in seconds)
        uint256 minCombatScore;         // Minimum combat achievements needed
        uint256 resultingItemId;        // The legendary item that will be created
        bool active;                    // Whether this recipe is currently active
    }

    struct ForgingProcess {
        address owner;
        uint256 recipeId;
        uint256 startTime;
        bool materialsLocked;
        bool completed;
    }

    // State variables
    mapping(uint256 => LegendaryRecipe) public recipes;
    mapping(uint256 => ForgingProcess) public forgingProcesses;
    mapping(address => uint256[]) public playerForgings;
    uint256 private nextRecipeId;
    uint256 private nextForgingId;

    // Events
    event RecipeCreated(uint256 indexed recipeId, uint256 indexed resultingItemId);
    event ForgingStarted(uint256 indexed forgingId, address indexed player, uint256 indexed recipeId);
    event MaterialsLocked(uint256 indexed forgingId, address indexed player);
    event ForgingCompleted(uint256 indexed forgingId, address indexed player, uint256 indexed itemId);
    event RecipeActivated(uint256 indexed recipeId, bool active);

    // Errors
    error InvalidRecipe();
    error InsufficientMaterials();
    error InsufficientCombatScore();
    error ForgingNotStarted();
    error ForgingAlreadyCompleted();
    error MaterialsNotLocked();
    error ForgingInProgress();
    error ForgingTimePending();
    error InvalidArrayLengths();
    error NotForgingOwner();
    error RecipeNotActive();

    constructor(
        address _equipment,
        address _arcaneCrafting,
        address _combatQuest
    ) Ownable() {
        equipment = Equipment(_equipment);
        arcaneCrafting = ArcaneCrafting(_arcaneCrafting);
        combatQuest = CombatQuest(_combatQuest);
        _transferOwnership(msg.sender);
    }

    /// @notice Create a new legendary recipe
    /// @param baseEquipmentIds Required base equipment IDs
    /// @param materialIds Required material IDs
    /// @param lpTokens Required LP token addresses
    /// @param lpAmounts Required LP token amounts
    /// @param forgingTime Time required to forge in seconds
    /// @param minCombatScore Minimum combat score required
    /// @param resultingItemId The legendary item ID that will be created
    function createRecipe(
        uint256[] calldata baseEquipmentIds,
        uint256[] calldata materialIds,
        address[] calldata lpTokens,
        uint256[] calldata lpAmounts,
        uint256 forgingTime,
        uint256 minCombatScore,
        uint256 resultingItemId
    ) external onlyOwner {
        if (lpTokens.length != lpAmounts.length) revert InvalidArrayLengths();

        uint256 recipeId = nextRecipeId++;
        
        recipes[recipeId] = LegendaryRecipe({
            baseEquipmentIds: baseEquipmentIds,
            materialIds: materialIds,
            lpTokens: lpTokens,
            lpAmounts: lpAmounts,
            forgingTime: forgingTime,
            minCombatScore: minCombatScore,
            resultingItemId: resultingItemId,
            active: true
        });

        emit RecipeCreated(recipeId, resultingItemId);
    }

    /// @notice Start the forging process for a legendary item
    /// @param recipeId The ID of the recipe to forge
    function startForging(uint256 recipeId) external nonReentrant {
        LegendaryRecipe memory recipe = recipes[recipeId];
        if (!recipe.active) revert RecipeNotActive();

        // Check combat score requirement
        if (!_checkCombatScore(msg.sender, recipe.minCombatScore)) {
            revert InsufficientCombatScore();
        }

        uint256 forgingId = nextForgingId++;
        
        forgingProcesses[forgingId] = ForgingProcess({
            owner: msg.sender,
            recipeId: recipeId,
            startTime: block.timestamp,
            materialsLocked: false,
            completed: false
        });

        playerForgings[msg.sender].push(forgingId);
        
        emit ForgingStarted(forgingId, msg.sender, recipeId);
    }

    /// @notice Lock materials for an ongoing forging process
    /// @param forgingId The ID of the forging process
    function lockMaterials(uint256 forgingId) external nonReentrant {
        ForgingProcess storage forging = forgingProcesses[forgingId];
        if (forging.owner != msg.sender) revert NotForgingOwner();
        if (forging.completed) revert ForgingAlreadyCompleted();
        if (forging.materialsLocked) revert ForgingInProgress();

        LegendaryRecipe memory recipe = recipes[forging.recipeId];

        // Check and transfer base equipment
        for (uint256 i = 0; i < recipe.baseEquipmentIds.length; i++) {
            uint256 equipId = recipe.baseEquipmentIds[i];
            if (equipment.balanceOf(msg.sender, equipId) == 0) revert InsufficientMaterials();
            equipment.safeTransferFrom(msg.sender, address(this), equipId, 1, "");
        }

        // Check and transfer LP tokens
        for (uint256 i = 0; i < recipe.lpTokens.length; i++) {
            IERC20 lpToken = IERC20(recipe.lpTokens[i]);
            if (lpToken.balanceOf(msg.sender) < recipe.lpAmounts[i]) revert InsufficientMaterials();
            lpToken.transferFrom(msg.sender, address(this), recipe.lpAmounts[i]);
        }

        forging.materialsLocked = true;
        emit MaterialsLocked(forgingId, msg.sender);
    }

    /// @notice Complete the forging process and receive the legendary item
    /// @param forgingId The ID of the forging process
    function completeForging(uint256 forgingId) external nonReentrant {
        ForgingProcess storage forging = forgingProcesses[forgingId];
        if (forging.owner != msg.sender) revert NotForgingOwner();
        if (forging.completed) revert ForgingAlreadyCompleted();
        if (!forging.materialsLocked) revert MaterialsNotLocked();

        LegendaryRecipe memory recipe = recipes[forging.recipeId];
        
        // Check if enough time has passed
        if (block.timestamp < forging.startTime + recipe.forgingTime) {
            revert ForgingTimePending();
        }

        // Mint the legendary item
        equipment.mint(msg.sender, recipe.resultingItemId, 1, "");
        
        forging.completed = true;
        emit ForgingCompleted(forgingId, msg.sender, recipe.resultingItemId);
    }

    /// @notice Get all forging processes for a player
    /// @param player The address of the player
    /// @return forgingIds Array of forging process IDs
    function getPlayerForgings(address player) external view returns (uint256[] memory) {
        return playerForgings[player];
    }

    /// @notice Set the active status of a recipe
    /// @param recipeId The ID of the recipe
    /// @param active Whether the recipe should be active
    function setRecipeActive(uint256 recipeId, bool active) external onlyOwner {
        recipes[recipeId].active = active;
        emit RecipeActivated(recipeId, active);
    }

    /// @notice Check if a player meets the combat score requirement
    /// @param player The address of the player
    /// @param requiredScore The required combat score
    /// @return bool Whether the player meets the requirement
    function _checkCombatScore(address player, uint256 requiredScore) internal view returns (bool) {
        // TODO: Implement combat score calculation based on CombatQuest achievements
        return true; // Placeholder
    }
} 