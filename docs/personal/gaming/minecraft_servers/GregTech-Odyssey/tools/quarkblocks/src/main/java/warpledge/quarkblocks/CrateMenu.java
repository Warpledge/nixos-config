package warpledge.quarkblocks;

import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ContainerData;
import net.minecraft.world.inventory.SimpleContainerData;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.items.IItemHandler;
import net.minecraftforge.items.SlotItemHandler;

/**
 * The crate's screen contents (Quark's CrateMenu, CC BY-NC-SA 3.0): 54 of the crate's slots
 * visible at a time, scrolled a row at a time; the client tells the server with a
 * ScrollCrate packet (Network).
 */
public class CrateMenu extends AbstractContainerMenu {
    static final int ROWS = 6;
    static final int COLS = 9;
    static final int SHOWN = ROWS * COLS;

    final CrateBlockEntity crate;
    final int totalSlots;
    int scroll;
    private final ContainerData data;

    public CrateMenu(int id, Inventory inv, CrateBlockEntity crate, ContainerData data) {
        super(QuarkBlocks.CRATE_MENU.get(), id);
        crate.startOpen(inv.player);
        this.crate = crate;
        this.data = data;
        int shift = (ROWS - 4) * 18;
        CrateItemHandler h = crate.itemHandler();
        totalSlots = h.getSlots();
        for (int j = 0; j < totalSlots; j++) addSlot(new CrateSlot(h, j, 8 + (j % COLS) * 18, 18 + (j / COLS) * 18));
        for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 9; col++) addSlot(new Slot(inv, col + row * 9 + 9, 8 + col * 18, 103 + row * 18 + shift));
        }
        for (int col = 0; col < 9; col++) addSlot(new Slot(inv, col, 8 + col * 18, 161 + shift));
        addDataSlots(data);
    }

    static CrateMenu fromNetwork(int id, Inventory inv, FriendlyByteBuf buf) {
        var be = inv.player.level().getBlockEntity(buf.readBlockPos());
        return new CrateMenu(id, inv, (CrateBlockEntity) be, new SimpleContainerData(2));
    }

    int total() {
        return data.get(0);
    }

    int stackCount() {
        return data.get(1);
    }

    @Override
    public ItemStack quickMoveStack(Player player, int index) {
        Slot slot = slots.get(index);
        if (slot == null || !slot.hasItem()) return ItemStack.EMPTY;
        ItemStack stack = slot.getItem();
        ItemStack copy = stack.copy();
        boolean moved = index < totalSlots
                ? moveItemStackTo(stack, totalSlots, slots.size(), true)
                : moveItemStackTo(stack, 0, totalSlots, false);
        if (!moved) return ItemStack.EMPTY;
        if (stack.isEmpty()) slot.set(ItemStack.EMPTY);
        else slot.setChanged();
        return copy;
    }

    /** Merge first, then fill empty slots, minding each slot's own limit (CoFH Core's). */
    @Override
    protected boolean moveItemStackTo(ItemStack stack, int start, int end, boolean reverse) {
        boolean moved = false;
        if (stack.isStackable()) {
            for (int i = reverse ? end - 1 : start; stack.getCount() > 0 && (reverse ? i >= start : i < end);
                    i += reverse ? -1 : 1) {
                Slot slot = slots.get(i);
                ItemStack there = slot.getItem();
                if (there.isEmpty()) continue;
                int max = Math.min(stack.getMaxStackSize(), slot.getMaxStackSize());
                if (!slot.mayPlace(stack.copyWithCount(Math.min(max, stack.getCount())))
                        || !ItemStack.isSameItemSameTags(stack, there)) {
                    continue;
                }
                int sum = there.getCount() + stack.getCount();
                ItemStack merged = there.copy();
                if (sum <= max) {
                    stack.setCount(0);
                    merged.setCount(sum);
                    slot.set(merged);
                    moved = true;
                } else if (merged.getCount() < max) {
                    stack.shrink(max - merged.getCount());
                    merged.setCount(max);
                    slot.set(merged);
                    moved = true;
                }
            }
        }
        for (int i = reverse ? end - 1 : start; stack.getCount() > 0 && (reverse ? i >= start : i < end);
                i += reverse ? -1 : 1) {
            Slot slot = slots.get(i);
            if (!slot.getItem().isEmpty()) continue;
            int n = Math.min(Math.min(stack.getMaxStackSize(), slot.getMaxStackSize()), stack.getCount());
            if (slot.mayPlace(stack.copyWithCount(n))) {
                slot.set(stack.split(n));
                moved = true;
            }
        }
        return moved;
    }

    @Override
    public boolean stillValid(Player player) {
        return crate.stillValid(player);
    }

    @Override
    public void removed(Player player) {
        super.removed(player);
        crate.stopOpen(player);
    }

    void scroll(boolean down, boolean sendToServer) {
        int target = scroll + (down ? COLS : -COLS);
        if (target < 0 || target > (stackCount() / COLS) * COLS) return;
        scroll = target;
        for (Slot s : slots) if (s instanceof CrateSlot) s.y += down ? -18 : 18;
        broadcastChanges();
        if (sendToServer) Network.scrollCrate(down);
    }

    private class CrateSlot extends SlotItemHandler {
        CrateSlot(IItemHandler h, int index, int x, int y) {
            super(h, index, x, y);
        }

        @Override
        public void setChanged() {
            crate.itemHandler().onContentsChanged(getSlotIndex());
        }

        @Override
        public boolean isActive() {
            return getSlotIndex() >= scroll && getSlotIndex() < scroll + SHOWN;
        }
    }
}
