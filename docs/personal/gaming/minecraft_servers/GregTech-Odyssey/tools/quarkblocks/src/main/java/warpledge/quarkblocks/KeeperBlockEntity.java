package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.NonNullList;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.world.ContainerHelper;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;

/**
 * For Quark machines kept for their look (crafter, tiny potato): holds whatever data the
 * template gave it, unchanged, and drops its "Items" when the block breaks, so a crafter's
 * ingredients aren't lost.
 */
public class KeeperBlockEntity extends BlockEntity {
    private CompoundTag data = new CompoundTag();

    public KeeperBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
        super(type, pos, state);
    }

    @Override
    public void load(CompoundTag tag) {
        super.load(tag);
        data = tag.copy();
        for (String k : new String[] {"id", "x", "y", "z", "ForgeData", "ForgeCaps"}) data.remove(k);
    }

    @Override
    protected void saveAdditional(CompoundTag tag) {
        super.saveAdditional(tag);
        tag.merge(data);
    }

    void dropItems(Level level, BlockPos pos) {
        if (!data.contains("Items")) return;
        NonNullList<ItemStack> items = NonNullList.withSize(256, ItemStack.EMPTY); // any Slot byte
        ContainerHelper.loadAllItems(data, items);
        for (ItemStack s : items) if (!s.isEmpty()) Containers.dropItemStack(level, pos.getX(), pos.getY(), pos.getZ(), s);
        data.remove("Items");
    }
}
