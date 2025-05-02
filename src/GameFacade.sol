// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Types } from "./interfaces/Types.sol";
import { Character } from "./Character.sol";
import { Equipment } from "./Equipment.sol";
import { GameToken } from "./GameToken.sol";
import { ItemDrop } from "./ItemDrop.sol";
import { Marketplace } from "./Marketplace.sol";
import { Quest } from "./Quest.sol";
import { CharacterWallet } from "./CharacterWallet.sol";
import { Pet } from "./pets/Pet.sol";
import { Mount } from "./pets/Mount.sol";
import { Title } from "./titles/Title.sol";
import { AttributeCalculator } from "./attributes/AttributeCalculator.sol";
import { ArcaneStaking } from "./amm/ArcaneStaking.sol";
import { ArcaneCrafting } from "./amm/ArcaneCrafting.sol";
import { ArcaneFactory } from "./amm/ArcaneFactory.sol";
import { ArcanePair } from "./amm/ArcanePair.sol";
import { ArcaneQuestIntegration } from "./amm/ArcaneQuestIntegration.sol";
import { ArcaneRouter } from "./amm/ArcaneRouter.sol";
import { ILegendaryForge } from "./interfaces/ILegendaryForge.sol";

/**
 * @title GameFacade
 * @notice A facade contract that simplifies interactions with the game protocol
 * @dev This contract provides a clean interface to the complex game protocol
 */
contract GameFacade {
    Character public immutable character;
    Equipment public immutable equipment;
    GameToken public immutable gameToken;
    ItemDrop public immutable itemDrop;
    Marketplace public immutable marketplace;
    Quest public immutable quest;
    Pet public immutable pet;
    Mount public immutable mount;
    Title public immutable title;
    AttributeCalculator public immutable attributeCalculator;
    ArcaneStaking public immutable arcaneStaking;
    ArcaneCrafting public immutable arcaneCrafting;
    ArcaneFactory public immutable arcaneFactory;
    ArcanePair public immutable arcanePair;
    ArcaneQuestIntegration public immutable arcaneQuestIntegration;
    ArcaneRouter public immutable arcaneRouter;
    ILegendaryForge public immutable legendaryForge;

    // Events
    event CharacterCreated(address indexed player, uint256 characterId);
    event EquipmentEquipped(address indexed player, uint256 characterId, uint256 weaponId, uint256 armorId);
    event EquipmentUnequipped(address indexed player, uint256 characterId, bool weapon, bool armor);
    event QuestStarted(address indexed player, uint256 questId);
    event QuestCompleted(address indexed player, uint256 questId, uint256 reward);
    event ItemDropped(address indexed player, uint256 itemId, uint256 dropRateBonus);
    event ItemClaimed(address indexed player, uint256 itemId);
    event ItemListed(address indexed player, uint256 itemId, uint256 price);
    event ItemPurchased(address indexed player, uint256 itemId, uint256 listingId);
    event TokensTransferred(address indexed player, uint256 characterId, uint256 amount);
    event TokensWithdrawn(address indexed player, uint256 characterId, uint256 amount);
    event PetSummoned(address indexed player, uint256 characterId, uint256 petId);
    event PetDismissed(address indexed player, uint256 characterId, uint256 petId);
    event MountEquipped(address indexed player, uint256 characterId, uint256 mountId);
    event MountUnequipped(address indexed player, uint256 characterId, uint256 mountId);
    event TitleAwarded(address indexed player, uint256 characterId, uint256 titleId);
    event TitleRevoked(address indexed player, uint256 characterId, uint256 titleId);
    event ArcaneStaked(address indexed player, uint256 amount);
    event ArcaneUnstaked(address indexed player, uint256 amount);
    event ArcaneCrafted(address indexed player, uint256 itemId);
    event ArcaneQuestStarted(address indexed player, uint256 questId);
    event ArcaneQuestCompleted(address indexed player, uint256 questId);
    event LegendaryForgingStarted(address indexed player, uint256 indexed recipeId);
    event LegendaryMaterialsLocked(address indexed player, uint256 indexed forgingId);
    event LegendaryForgingCompleted(address indexed player, uint256 indexed forgingId);

    constructor(
        address _character,
        address _equipment,
        address _gameToken,
        address _itemDrop,
        address _marketplace,
        address _quest,
        address _pet,
        address _mount,
        address _title,
        address _attributeCalculator,
        address _arcaneStaking,
        address _arcaneCrafting,
        address _arcaneFactory,
        address _arcanePair,
        address _arcaneQuestIntegration,
        address _arcaneRouter,
        address _legendaryForge
    ) {
        character = Character(_character);
        equipment = Equipment(_equipment);
        gameToken = GameToken(_gameToken);
        itemDrop = ItemDrop(_itemDrop);
        marketplace = Marketplace(_marketplace);
        quest = Quest(_quest);
        pet = Pet(_pet);
        mount = Mount(_mount);
        title = Title(_title);
        attributeCalculator = AttributeCalculator(_attributeCalculator);
        arcaneStaking = ArcaneStaking(_arcaneStaking);
        arcaneCrafting = ArcaneCrafting(_arcaneCrafting);
        arcaneFactory = ArcaneFactory(_arcaneFactory);
        arcanePair = ArcanePair(_arcanePair);
        arcaneQuestIntegration = ArcaneQuestIntegration(_arcaneQuestIntegration);
        arcaneRouter = ArcaneRouter(_arcaneRouter);
        legendaryForge = ILegendaryForge(_legendaryForge);
    }

    // Character Management
    /**
     * @notice Creates a new character for the player
     * @param alignment Character alignment
     * @return characterId The ID of the newly created character
     */
    function createCharacter(Types.Alignment alignment) external returns (uint256 characterId) {
        characterId = character.mintCharacter(msg.sender, alignment);
        emit CharacterCreated(msg.sender, characterId);
        return characterId;
    }

    /**
     * @notice Gets character details
     * @param characterId The ID of the character
     * @return stats Character stats
     * @return equipmentSlots Equipped items
     * @return state Character state
     */
    function getCharacterDetails(uint256 characterId)
        external
        view
        returns (
            Types.Stats memory stats,
            Types.EquipmentSlots memory equipmentSlots,
            Types.CharacterState memory state
        )
    {
        return character.getCharacter(characterId);
    }

    // Equipment Management
    /**
     * @notice Equips items to a character
     * @param characterId The ID of the character
     * @param weaponId The ID of the weapon to equip
     * @param armorId The ID of the armor to equip
     */
    function equipItems(uint256 characterId, uint256 weaponId, uint256 armorId) external {
        character.equip(characterId, weaponId, armorId);
        emit EquipmentEquipped(msg.sender, characterId, weaponId, armorId);
    }

    /**
     * @notice Unequips items from a character
     * @param characterId The ID of the character
     * @param weapon Whether to unequip weapon
     * @param armor Whether to unequip armor
     */
    function unequipItems(uint256 characterId, bool weapon, bool armor) external {
        character.unequip(characterId, weapon, armor);
        emit EquipmentUnequipped(msg.sender, characterId, weapon, armor);
    }

    /**
     * @notice Gets equipment stats
     * @param equipmentId The ID of the equipment
     * @return stats Equipment stats
     * @return exists Whether the equipment exists
     */
    function getEquipmentDetails(uint256 equipmentId)
        external
        view
        returns (Types.EquipmentStats memory stats, bool exists)
    {
        return equipment.getEquipmentStats(equipmentId);
    }

    /**
     * @notice Gets special abilities of equipment
     * @param equipmentId The ID of the equipment
     * @return abilities Array of special abilities
     */
    function getEquipmentAbilities(uint256 equipmentId)
        external
        view
        returns (Types.SpecialAbility[] memory abilities)
    {
        return equipment.getSpecialAbilities(equipmentId);
    }

    // Quest System
    /**
     * @notice Starts a quest for a character
     * @param characterId The ID of the character
     * @param questId The ID of the quest to start
     */
    function startQuest(uint256 characterId, uint256 questId) external {
        quest.startQuest(characterId, questId, bytes32(0)); // Pass empty party ID
    }

    /**
     * @notice Completes a quest for a character
     * @param characterId The ID of the character
     * @param questId The ID of the quest to complete
     */
    function completeQuest(uint256 characterId, uint256 questId) external {
        quest.completeQuest(characterId, questId);

        uint256 dropRateBonus = calculateDropRateBonus(msg.sender);
        if (dropRateBonus > 0) {
            uint256 requestId = itemDrop.requestRandomDrop(msg.sender, uint32(dropRateBonus));
            emit QuestCompleted(msg.sender, questId, requestId);
        }
    }

    // Item Drop System
    /**
     * @notice Requests a random item drop
     * @param dropRateBonus Bonus to the drop rate
     * @return requestId The ID of the drop request
     */
    function requestRandomDrop(uint256 dropRateBonus) external returns (uint256 requestId) {
        requestId = itemDrop.requestRandomDrop(msg.sender, uint32(dropRateBonus));
        emit ItemDropped(msg.sender, requestId, dropRateBonus);
        return requestId;
    }

    // Marketplace
    /**
     * @notice Lists an item on the marketplace
     * @param equipmentId The ID of the equipment to list
     * @param price The price in game tokens
     * @param amount The amount of items to list
     */
    function listItem(uint256 equipmentId, uint256 price, uint256 amount) external {
        marketplace.listItem(equipmentId, price, amount);
        emit ItemListed(msg.sender, equipmentId, price);
    }

    /**
     * @notice Purchases an item from the marketplace
     * @param equipmentId The ID of the equipment to purchase
     * @param listingId The ID of the listing to purchase from
     * @param amount The amount of items to purchase
     */
    function purchaseItem(uint256 equipmentId, uint256 listingId, uint256 amount) external {
        marketplace.purchaseItem(equipmentId, listingId, amount);
        emit ItemPurchased(msg.sender, equipmentId, listingId);
    }

    /**
     * @notice Cancels a marketplace listing
     * @param equipmentId The ID of the equipment
     * @param listingId The ID of the listing to cancel
     */
    function cancelListing(uint256 equipmentId, uint256 listingId) external {
        marketplace.cancelListing(equipmentId, listingId);
    }

    // Character Wallet
    /**
     * @notice Transfers game tokens to a character's wallet
     * @param characterId The ID of the character
     * @param amount The amount of tokens to transfer
     */
    function transferToCharacterWallet(uint256 characterId, uint256 amount) external {
        CharacterWallet wallet = character.characterWallets(characterId);
        gameToken.transfer(address(wallet), amount);
        emit TokensTransferred(msg.sender, characterId, amount);
    }

    /**
     * @notice Gets character wallet balance
     * @param characterId The ID of the character
     * @return balance The current balance of the character's wallet
     */
    function getCharacterWalletBalance(uint256 characterId) external view returns (uint256 balance) {
        CharacterWallet wallet = character.characterWallets(characterId);
        return gameToken.balanceOf(address(wallet));
    }

    /**
     * @notice Gets equipped items for a character
     * @param characterId The ID of the character
     * @return equipmentSlots The equipped items
     */
    function getEquippedItems(uint256 characterId) external view returns (Types.EquipmentSlots memory equipmentSlots) {
        CharacterWallet wallet = character.characterWallets(characterId);
        return wallet.getEquippedItems();
    }

    // Pet System
    /**
     * @notice Summons a pet for a character
     * @param characterId The ID of the character
     * @param petId The ID of the pet to summon
     */
    function summonPet(uint256 characterId, uint256 petId) external {
        pet.mintPet(characterId, petId);
        emit PetSummoned(msg.sender, characterId, petId);
    }

    /**
     * @notice Dismisses a pet from a character
     * @param characterId The ID of the character
     * @param petId The ID of the pet to dismiss
     */
    function dismissPet(uint256 characterId, uint256 petId) external {
        pet.unassignPet(characterId);
        emit PetDismissed(msg.sender, characterId, petId);
    }

    // Mount System
    /**
     * @notice Equips a mount for a character
     * @param characterId The ID of the character
     * @param mountId The ID of the mount to equip
     */
    function equipMount(uint256 characterId, uint256 mountId) external {
        mount.mintMount(characterId, mountId);
        emit MountEquipped(msg.sender, characterId, mountId);
    }

    /**
     * @notice Unequips a mount from a character
     * @param characterId The ID of the character
     * @param mountId The ID of the mount to unequip
     */
    function unequipMount(uint256 characterId, uint256 mountId) external {
        mount.unassignMount(characterId);
        emit MountUnequipped(msg.sender, characterId, mountId);
    }

    // Title System
    /**
     * @notice Awards a title to a character
     * @param characterId The ID of the character
     * @param titleId The ID of the title to award
     */
    function awardTitle(uint256 characterId, uint256 titleId) external {
        title.assignTitle(characterId, titleId);
        emit TitleAwarded(msg.sender, characterId, titleId);
    }

    /**
     * @notice Revokes a title from a character
     * @param characterId The ID of the character
     * @param titleId The ID of the title to revoke
     */
    function revokeTitle(uint256 characterId, uint256 titleId) external {
        title.revokeTitle(characterId);
        emit TitleRevoked(msg.sender, characterId, titleId);
    }

    // Attribute System
    /**
     * @notice Calculates total attributes for a character
     * @param characterId The ID of the character
     * @return totalStats The total calculated stats
     * @return bonusMultiplier The total bonus multiplier
     */
    function calculateTotalAttributes(uint256 characterId)
        external
        returns (Types.Stats memory totalStats, uint256 bonusMultiplier)
    {
        return attributeCalculator.calculateTotalAttributes(characterId);
    }

    // Arcane Systems
    /**
     * @notice Stakes tokens in the Arcane system
     * @param amount The amount of tokens to stake
     */
    function stakeArcane(uint256 amount) external {
        arcaneStaking.deposit(0, amount); // Using pool 0 as default
        emit ArcaneStaked(msg.sender, amount);
    }

    /**
     * @notice Unstakes tokens from the Arcane system
     * @param amount The amount of tokens to unstake
     */
    function unstakeArcane(uint256 amount) external {
        arcaneStaking.withdraw(0, amount); // Using pool 0 as default
        emit ArcaneUnstaked(msg.sender, amount);
    }

    /**
     * @notice Crafts an item using the Arcane system
     * @param recipeId The ID of the recipe to use
     * @return itemId The ID of the crafted item
     */
    function craftArcaneItem(uint256 recipeId) external returns (uint256 itemId) {
        arcaneCrafting.craftItem(recipeId);
        itemId = recipeId; // The crafted item ID is the same as the recipe ID
        emit ArcaneCrafted(msg.sender, itemId);
        return itemId;
    }

    /**
     * @notice Starts an Arcane quest
     * @param characterId The ID of the character
     * @param questId The ID of the quest to start
     */
    function startArcaneQuest(uint256 characterId, uint256 questId) external {
        arcaneQuestIntegration.startQuest(characterId, questId);
        emit ArcaneQuestStarted(msg.sender, questId);
    }

    /**
     * @notice Completes an Arcane quest
     * @param characterId The ID of the character
     * @param questId The ID of the quest to complete
     */
    function completeArcaneQuest(uint256 characterId, uint256 questId) external {
        arcaneQuestIntegration.completeQuest(characterId, questId);
        emit ArcaneQuestCompleted(msg.sender, questId);
    }

    /**
     * @notice Adds liquidity to an Arcane pair
     * @param tokenA The first token address
     * @param tokenB The second token address
     * @param amountA The amount of token A
     * @param amountB The amount of token B
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @param to The recipient address
     */
    function addArcaneLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external {
        arcaneRouter.addLiquidity(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin, to);
    }

    /**
     * @notice Removes liquidity from an Arcane pair
     * @param tokenA The first token address
     * @param tokenB The second token address
     * @param liquidity The amount of liquidity to remove
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @param to The recipient address
     */
    function removeArcaneLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external {
        arcaneRouter.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
    }

    function calculateDropRateBonus(address player) internal view returns (uint256) {
        // For now, return a fixed bonus. This can be expanded based on player stats, achievements, etc.
        return 100; // 1% bonus
    }

    /**
     * @notice Starts the forging process for a legendary item
     * @param recipeId The ID of the recipe to forge
     * @return forgingId The ID of the forging process
     */
    function startLegendaryForging(uint256 recipeId) external returns (uint256 forgingId) {
        legendaryForge.startForging(recipeId);
        emit LegendaryForgingStarted(msg.sender, recipeId);
        return forgingId;
    }

    /**
     * @notice Locks materials for a legendary forging process
     * @param forgingId The ID of the forging process
     */
    function lockLegendaryMaterials(uint256 forgingId) external {
        legendaryForge.lockMaterials(forgingId);
        emit LegendaryMaterialsLocked(msg.sender, forgingId);
    }

    /**
     * @notice Completes a legendary forging process
     * @param forgingId The ID of the forging process
     */
    function completeLegendaryForging(uint256 forgingId) external {
        legendaryForge.completeForging(forgingId);
        emit LegendaryForgingCompleted(msg.sender, forgingId);
    }
}
