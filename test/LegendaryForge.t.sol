// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/forge/LegendaryForge.sol";
import "../src/Equipment.sol";
import "../src/CombatQuest.sol";
import "../src/amm/ArcaneCrafting.sol";
import "./mocks/MockLPToken.sol";

contract LegendaryForgeTest is Test {
    LegendaryForge public forge;
    Equipment public equipment;
    CombatQuest public combatQuest;
    ArcaneCrafting public arcaneCrafting;
    MockLPToken public lpToken;

    address owner;
    address player;

    function setUp() public {
        owner = address(this);
        player = makeAddr("player");

        // Deploy mock LP token
        lpToken = new MockLPToken();

        // Deploy core contracts
        equipment = new Equipment(address(this));
        combatQuest = new CombatQuest(
            address(this),
            address(0), // character mock not needed for these tests
            address(0), // gameToken mock not needed for these tests
            address(0), // abilities mock not needed for these tests
            address(0), // itemDrop mock not needed for these tests
            address(0)  // damageCalculator mock not needed for these tests
        );
        arcaneCrafting = new ArcaneCrafting(
            address(0), // factory mock not needed for these tests
            address(equipment),
            address(0)  // itemDrop mock not needed for these tests
        );

        // Deploy LegendaryForge
        forge = new LegendaryForge(
            address(equipment),
            address(arcaneCrafting),
            address(combatQuest)
        );

        // Setup permissions
        equipment.grantRole(equipment.MINTER_ROLE(), address(forge));

        // Create test equipment
        equipment.createEquipment(
            "Test Base Equipment",
            "A test piece of equipment",
            5, // strength bonus
            0, // agility bonus
            0, // magic bonus
            Types.Alignment.STRENGTH,
            1 // amount
        );

        // Setup initial token balances
        lpToken.transfer(player, 1000 * 10 ** 18);

        // Setup approvals
        vm.startPrank(player);
        lpToken.approve(address(forge), type(uint256).max);
        equipment.setApprovalForAll(address(forge), true);
        vm.stopPrank();
    }

    function testCreateRecipe() public {
        uint256[] memory baseEquipmentIds = new uint256[](1);
        baseEquipmentIds[0] = 1;

        uint256[] memory materialIds = new uint256[](0);

        address[] memory lpTokens = new address[](1);
        lpTokens[0] = address(lpToken);

        uint256[] memory lpAmounts = new uint256[](1);
        lpAmounts[0] = 100 * 10 ** 18;

        forge.createRecipe(
            baseEquipmentIds,
            materialIds,
            lpTokens,
            lpAmounts,
            1 hours, // forgingTime
            100, // minCombatScore
            2 // resultingItemId
        );

        // Create the legendary equipment that will be forged
        equipment.createEquipment(
            "Legendary Sword",
            "A legendary sword",
            10, // strength bonus
            5, // agility bonus
            5, // magic bonus
            Types.Alignment.STRENGTH,
            0 // amount (will be minted through forging)
        );

        LegendaryForge.LegendaryRecipe memory recipe = forge.recipes(0);
        assertEq(recipe.baseEquipmentIds[0], 1);
        assertEq(recipe.lpTokens[0], address(lpToken));
        assertEq(recipe.lpAmounts[0], 100 * 10 ** 18);
        assertEq(recipe.forgingTime, 1 hours);
        assertEq(recipe.minCombatScore, 100);
        assertEq(recipe.resultingItemId, 2);
        assertTrue(recipe.active);
    }

    function testFullForgingProcess() public {
        // Create recipe first
        uint256[] memory baseEquipmentIds = new uint256[](1);
        baseEquipmentIds[0] = 1;

        uint256[] memory materialIds = new uint256[](0);

        address[] memory lpTokens = new address[](1);
        lpTokens[0] = address(lpToken);

        uint256[] memory lpAmounts = new uint256[](1);
        lpAmounts[0] = 100 * 10 ** 18;

        forge.createRecipe(
            baseEquipmentIds,
            materialIds,
            lpTokens,
            lpAmounts,
            1 hours, // forgingTime
            100, // minCombatScore
            2 // resultingItemId
        );

        // Create the legendary equipment that will be forged
        equipment.createEquipment(
            "Legendary Sword",
            "A legendary sword",
            10, // strength bonus
            5, // agility bonus
            5, // magic bonus
            Types.Alignment.STRENGTH,
            0 // amount (will be minted through forging)
        );

        // Mint base equipment to player
        equipment.mint(player, 1, 1, "");

        vm.startPrank(player);

        // Start forging
        forge.startForging(0);

        // Lock materials
        forge.lockMaterials(0);

        // Try to complete before time (should fail)
        vm.expectRevert(abi.encodeWithSignature("ForgingTimePending()"));
        forge.completeForging(0);

        // Wait for forging time
        vm.warp(block.timestamp + 1 hours);

        // Complete forging
        forge.completeForging(0);

        vm.stopPrank();

        // Check if player received the legendary item
        assertEq(equipment.balanceOf(player, 2), 1);
    }

    function testCannotForgeWithoutMaterials() public {
        // Create recipe
        uint256[] memory baseEquipmentIds = new uint256[](1);
        baseEquipmentIds[0] = 1;

        uint256[] memory materialIds = new uint256[](0);

        address[] memory lpTokens = new address[](1);
        lpTokens[0] = address(lpToken);

        uint256[] memory lpAmounts = new uint256[](1);
        lpAmounts[0] = 2000 * 10 ** 18; // More than player has

        forge.createRecipe(
            baseEquipmentIds,
            materialIds,
            lpTokens,
            lpAmounts,
            1 hours,
            100,
            2
        );

        vm.startPrank(player);
        
        // Start forging
        forge.startForging(0);

        // Try to lock materials (should fail)
        vm.expectRevert(abi.encodeWithSignature("InsufficientMaterials()"));
        forge.lockMaterials(0);

        vm.stopPrank();
    }
} 