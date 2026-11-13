package warpledge.quarkblocks;

import java.util.ArrayList;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.NonNullList;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.util.Mth;
import net.minecraft.world.Containers;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraftforge.items.ItemStackHandler;

/**
 * The crate's contents (Quark's CrateItemHandler, CC BY-NC-SA 3.0): 640 one-item-type
 * slots sharing a 640-item total, kept packed at the front, saved as a "stacks" list.
 */
public class CrateItemHandler extends ItemStackHandler {
    static final int MAX_ITEMS = 640;

    private boolean needsUpdate;
    int displayTotal;
    int displaySlots;
    private int cachedTotal = -1;

    public CrateItemHandler() {
        super(MAX_ITEMS);
    }

    private int total() {
        if (cachedTotal == -1) {
            cachedTotal = 0;
            for (ItemStack s : stacks) cachedTotal += s.getCount();
        }
        return cachedTotal;
    }

    private void changeTotal(ItemStack before, ItemStack after) {
        int diff = after.getCount() - before.getCount();
        if (diff != 0) cachedTotal = total() + diff;
    }

    void recalculate() {
        if (!needsUpdate) return;
        needsUpdate = false;
        displayTotal = 0;
        displaySlots = 0;
        NonNullList<ItemStack> packed = NonNullList.withSize(MAX_ITEMS, ItemStack.EMPTY);
        for (ItemStack s : stacks) {
            if (s.isEmpty()) continue;
            packed.set(displaySlots++, s);
            displayTotal += s.getCount();
        }
        stacks = packed;
        cachedTotal = -1;
    }

    void clear() {
        needsUpdate = false;
        stacks = NonNullList.withSize(MAX_ITEMS, ItemStack.EMPTY);
        displayTotal = 0;
        displaySlots = 0;
    }

    boolean isEmpty() {
        for (ItemStack s : stacks) if (!s.isEmpty()) return false;
        return true;
    }

    /** Drops the contents, merged into full stacks (Quark's SortingHandler.mergeStacks). */
    void spill(Level level, BlockPos pos) {
        List<ItemStack> merged = new ArrayList<>();
        for (ItemStack s : stacks) {
            ItemStack left = s.copy();
            for (ItemStack m : merged) {
                if (left.isEmpty()) break;
                if (ItemStack.isSameItemSameTags(m, left) && m.getCount() < m.getMaxStackSize()) {
                    int move = Math.min(left.getCount(), m.getMaxStackSize() - m.getCount());
                    m.grow(move);
                    left.shrink(move);
                }
            }
            if (!left.isEmpty()) merged.add(left);
        }
        for (ItemStack s : merged) Containers.dropItemStack(level, pos.getX(), pos.getY(), pos.getZ(), s);
    }

    @Override
    public int getSlotLimit(int slot) {
        return Mth.clamp(getStackInSlot(slot).getCount() + MAX_ITEMS - total(), 0, 64);
    }

    @Override
    public void setStackInSlot(int slot, ItemStack stack) {
        ItemStack before = stacks.get(slot).copy();
        super.setStackInSlot(slot, stack);
        changeTotal(before, stacks.get(slot));
    }

    @Override
    public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) {
        ItemStack before = stacks.get(slot).copy();
        ItemStack rest = super.insertItem(slot, stack, simulate);
        if (!simulate) changeTotal(before, stacks.get(slot));
        return rest;
    }

    @Override
    public ItemStack extractItem(int slot, int amount, boolean simulate) {
        ItemStack before = stacks.get(slot).copy();
        ItemStack out = super.extractItem(slot, amount, simulate);
        if (!simulate) changeTotal(before, stacks.get(slot));
        return out;
    }

    @Override
    public void onContentsChanged(int slot) {
        needsUpdate = true;
    }

    @Override
    protected void onLoad() {
        needsUpdate = true;
        recalculate();
    }

    @Override
    public CompoundTag serializeNBT() {
        ListTag items = new ListTag();
        for (ItemStack s : stacks) if (!s.isEmpty()) items.add(s.save(new CompoundTag()));
        CompoundTag tag = new CompoundTag();
        tag.put("stacks", items);
        return tag;
    }

    @Override
    public void deserializeNBT(CompoundTag tag) {
        stacks = NonNullList.withSize(MAX_ITEMS, ItemStack.EMPTY);
        ListTag items = tag.getList("stacks", Tag.TAG_COMPOUND);
        for (int i = 0; i < items.size() && i < MAX_ITEMS; i++) stacks.set(i, ItemStack.of(items.getCompound(i)));
        onLoad();
    }
}
