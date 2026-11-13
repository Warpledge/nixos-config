package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.Container;
import net.minecraft.world.WorldlyContainer;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ContainerData;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.entity.BaseContainerBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.phys.AABB;
import net.minecraftforge.common.capabilities.ForgeCapabilities;
import net.minecraftforge.items.IItemHandler;

/**
 * quarkblocks:crate (Quark's CrateBlockEntity, CC BY-NC-SA 3.0). The templates' "stacks"
 * list loads into its CrateItemHandler; hoppers and pipes see every slot.
 */
public class CrateBlockEntity extends BaseContainerBlockEntity implements WorldlyContainer {
    private int users;
    private int[] faceSlots = new int[0];

    final ContainerData data = new ContainerData() {
        @Override
        public int get(int i) {
            CrateItemHandler h = itemHandler();
            return i == 0 ? h.displayTotal : h.displaySlots;
        }

        @Override
        public void set(int i, int value) {}

        @Override
        public int getCount() {
            return 2;
        }
    };

    public CrateBlockEntity(BlockPos pos, BlockState state) {
        super(QuarkBlocks.CRATE_BE.get(), pos, state);
    }

    @Override
    protected void saveAdditional(CompoundTag tag) {
        super.saveAdditional(tag);
        tag.merge(itemHandler().serializeNBT());
    }

    @Override
    public void load(CompoundTag tag) {
        super.load(tag);
        itemHandler().deserializeNBT(tag);
    }

    CrateItemHandler itemHandler() {
        IItemHandler h = getCapability(ForgeCapabilities.ITEM_HANDLER).orElse(null);
        return h instanceof CrateItemHandler c ? c : new CrateItemHandler();
    }

    @Override
    protected IItemHandler createUnSidedHandler() {
        return new CrateItemHandler();
    }

    @Override
    public ItemStack getItem(int slot) {
        return itemHandler().getStackInSlot(slot);
    }

    @Override
    public ItemStack removeItemNoUpdate(int slot) {
        return itemHandler().extractItem(slot, 64, true);
    }

    @Override
    public void setItem(int slot, ItemStack stack) {
        itemHandler().setStackInSlot(slot, stack);
    }

    @Override
    public ItemStack removeItem(int slot, int count) {
        return itemHandler().extractItem(slot, 64, true);
    }

    @Override
    public int getContainerSize() {
        return itemHandler().getSlots();
    }

    @Override
    public void clearContent() {
        itemHandler().clear();
    }

    @Override
    public boolean isEmpty() {
        return itemHandler().isEmpty();
    }

    @Override
    public boolean canTakeItemThroughFace(int slot, ItemStack stack, Direction dir) {
        return true;
    }

    @Override
    public boolean canPlaceItemThroughFace(int slot, ItemStack stack, Direction dir) {
        return itemHandler().getSlotLimit(slot) > 0;
    }

    @Override
    public int[] getSlotsForFace(Direction dir) {
        int n = itemHandler().getSlots();
        if (faceSlots.length != n) {
            faceSlots = new int[n];
            for (int i = 0; i < n; i++) faceSlots[i] = i;
        }
        return faceSlots;
    }

    @Override
    protected Component getDefaultName() {
        return Component.translatable(getBlockState().getBlock().getDescriptionId());
    }

    @Override
    protected AbstractContainerMenu createMenu(int id, Inventory inv) {
        return new CrateMenu(id, inv, this, data);
    }

    @Override
    public boolean stillValid(Player player) {
        return Container.stillValidBlockEntity(this, player);
    }

    @Override
    public void startOpen(Player player) {
        if (player.isSpectator()) return;
        users = Math.max(users, 0) + 1;
        BlockState state = getBlockState();
        if (!state.getValue(CrateBlock.OPEN)) {
            playSound(SoundEvents.BARREL_OPEN);
            level.gameEvent(player, GameEvent.CONTAINER_OPEN, worldPosition);
            setOpen(state, true);
        }
        level.scheduleTick(worldPosition, state.getBlock(), 5);
    }

    void crateTick() {
        users = 0;
        AABB around = new AABB(worldPosition).inflate(5);
        for (Player p : level.getEntitiesOfClass(Player.class, around)) {
            if (p.containerMenu instanceof CrateMenu m && m.crate == this) users++;
        }
        if (users > 0) level.scheduleTick(worldPosition, getBlockState().getBlock(), 5);
    }

    @Override
    public void stopOpen(Player player) {
        if (!player.isSpectator()) users--;
        if (users > 0) return;
        BlockState state = getBlockState();
        if (!(state.getBlock() instanceof CrateBlock)) {
            setRemoved();
            return;
        }
        if (state.getValue(CrateBlock.OPEN)) {
            playSound(SoundEvents.BARREL_CLOSE);
            level.gameEvent(player, GameEvent.CONTAINER_CLOSE, worldPosition);
            setOpen(state, false);
        }
    }

    private void setOpen(BlockState state, boolean open) {
        if (level.getBlockState(worldPosition).is(state.getBlock())) {
            level.setBlock(worldPosition, state.setValue(CrateBlock.OPEN, open), 3);
        }
    }

    private void playSound(SoundEvent sound) {
        level.playSound(null, worldPosition.getX() + 0.5, worldPosition.getY() + 0.5, worldPosition.getZ() + 0.5,
                sound, SoundSource.BLOCKS, 0.5F, level.random.nextFloat() * 0.1F + 0.9F);
    }
}
