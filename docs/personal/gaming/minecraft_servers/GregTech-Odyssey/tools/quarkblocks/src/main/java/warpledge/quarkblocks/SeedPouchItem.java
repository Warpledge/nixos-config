package warpledge.quarkblocks;

import java.util.function.Function;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.SlotAccess;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.ClickAction;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraftforge.event.entity.player.EntityItemPickupEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Quark's seed pouch (SeedPouchItem and SeedPouchModule, CC BY-NC-SA 3.0): holds up to 640
 * of one kind of seed or bone meal, picks up more while held, and plants it, in a 3x3 area
 * when sneaking. Right-click it in an inventory to put items in or take a stack out. Quark's
 * tooltip preview of the contents is left out; the name shows what it holds.
 */
public class SeedPouchItem extends Item {
    static final int MAX = 640;
    static final TagKey<Item> HOLDABLE = ItemTags.create(QuarkBlocks.rl("seed_pouch_holdable"));
    static final TagKey<Item> FERTILIZERS = ItemTags.create(QuarkBlocks.rl("seed_pouch_fertilizers"));

    public SeedPouchItem(Properties p) {
        super(p);
    }

    /** The pouch's contents, read from and written back to its NBT. */
    static final class Contents {
        ItemStack item = ItemStack.EMPTY;
        int count;

        static Contents of(ItemStack pouch) {
            Contents c = new Contents();
            CompoundTag tag = pouch.getTag();
            if (tag != null && tag.contains("storedItem") && tag.contains("itemCount")) {
                c.item = ItemStack.of(tag.getCompound("storedItem"));
                c.count = tag.getInt("itemCount");
            }
            return c;
        }

        void write(ItemStack pouch) {
            CompoundTag tag = pouch.getTag();
            if (empty()) {
                if (tag != null) {
                    tag.remove("storedItem");
                    tag.remove("itemCount");
                    if (tag.isEmpty()) pouch.setTag(null);
                }
                return;
            }
            pouch.getOrCreateTag().put("storedItem", item.save(new CompoundTag()));
            pouch.getOrCreateTag().putInt("itemCount", count);
        }

        boolean empty() {
            return item.isEmpty() || count == 0;
        }

        void setCount(int n) {
            count = Math.max(n, 0);
            if (count == 0) item = ItemStack.EMPTY;
        }

        boolean canFit(ItemStack other) {
            if (empty()) return other.is(HOLDABLE) || other.is(FERTILIZERS);
            return count < MAX && ItemStack.isSameItemSameTags(item, other);
        }

        boolean absorb(ItemStack other) {
            if (!canFit(other)) return false;
            int move = Math.min(MAX - count, other.getCount());
            if (move == 0) return false;
            if (empty()) item = other.copyWithCount(1);
            setCount(count + move);
            other.shrink(move);
            return true;
        }

        ItemStack splitStack() {
            int n = Math.min(count, item.getMaxStackSize());
            ItemStack out = item.copyWithCount(n);
            setCount(count - n);
            return out;
        }
    }

    static <T> T mutate(ItemStack pouch, Function<Contents, T> f) {
        Contents c = Contents.of(pouch);
        T out = f.apply(c);
        c.write(pouch);
        return out;
    }

    @Override
    public boolean overrideOtherStackedOnMe(ItemStack pouch, ItemStack incoming, Slot slot, ClickAction action,
            Player player, SlotAccess cursor) {
        if (pouch.getCount() != 1 || action != ClickAction.SECONDARY || !slot.allowModification(player)) return false;
        return mutate(pouch, c -> {
            if (incoming.isEmpty()) {
                if (c.empty()) return false;
                cursor.set(c.splitStack());
                removeSound(player);
                return true;
            }
            ItemStack held = cursor.get();
            if (!c.absorb(held)) return false;
            cursor.set(held);
            insertSound(player);
            return true;
        });
    }

    @Override
    public boolean overrideStackedOnOther(ItemStack pouch, Slot slot, ClickAction action, Player player) {
        if (pouch.getCount() != 1 || action != ClickAction.SECONDARY || !slot.allowModification(player)) return false;
        return mutate(pouch, c -> {
            ItemStack there = slot.getItem();
            if (there.isEmpty()) {
                if (c.empty()) return false;
                slot.set(c.splitStack());
                removeSound(player);
                return true;
            }
            if (!c.absorb(there)) return false;
            slot.setChanged();
            insertSound(player);
            return true;
        });
    }

    private static void removeSound(Entity e) {
        e.playSound(SoundEvents.BUNDLE_REMOVE_ONE, 0.8F, 0.8F + e.level().getRandom().nextFloat() * 0.4F);
    }

    private static void insertSound(Entity e) {
        e.playSound(SoundEvents.BUNDLE_INSERT, 0.8F, 0.8F + e.level().getRandom().nextFloat() * 0.4F);
    }

    @Override
    public boolean isBarVisible(ItemStack stack) {
        return true;
    }

    @Override
    public int getBarWidth(ItemStack stack) {
        return Math.round(Contents.of(stack).count * 13F / MAX);
    }

    @Override
    public int getBarColor(ItemStack stack) {
        Contents c = Contents.of(stack);
        return !c.empty() && c.item.is(FERTILIZERS) ? Mth.color(0.85F, 0.85F, 0.85F) : Mth.color(0.4F, 0.4F, 1F);
    }

    @Override
    public Component getName(ItemStack stack) {
        Contents c = Contents.of(stack);
        Component base = super.getName(stack);
        return c.empty() ? base : base.copy().append(" (").append(c.item.getHoverName()).append(")");
    }

    @Override
    public InteractionResult useOn(UseOnContext ctx) {
        return mutate(ctx.getItemInHand(), c -> {
            if (c.empty()) return super.useOn(ctx);
            ItemStack seed = c.item.copyWithCount(Math.min(c.item.getMaxStackSize(), c.count));
            Player player = ctx.getPlayer();
            if (player == null || !player.isShiftKeyDown()) return place(c, ctx, seed, ctx.getClickedPos());
            InteractionResult best = InteractionResult.FAIL;
            for (int i = 0; i < 9 && !c.empty(); i++) {
                InteractionResult r = place(c, ctx, seed, ctx.getClickedPos().offset(-1 + i % 3, 0, -1 + i / 3));
                if (!best.consumesAction()) best = r;
            }
            return best;
        });
    }

    private InteractionResult place(Contents c, UseOnContext ctx, ItemStack seed, BlockPos pos) {
        Player player = ctx.getPlayer();
        UseOnContext at = new UseOnContext(ctx.getLevel(), player, ctx.getHand(), seed,
                new BlockHitResult(ctx.getClickLocation(), ctx.getClickedFace(), pos, ctx.isInside())) {};
        InteractionResult r;
        if (player == null) {
            r = seed.getItem().useOn(at);
        } else {
            ItemStack pouch = player.getItemInHand(ctx.getHand());
            player.setItemInHand(ctx.getHand(), seed);
            r = seed.getItem().useOn(at);
            player.setItemInHand(ctx.getHand(), pouch);
        }
        if (r == InteractionResult.CONSUME && (player == null || !player.getAbilities().instabuild)) {
            c.setCount(c.count - 1);
        }
        return r;
    }

    /** A pouch in either hand takes in matching items as they're picked up. */
    @SubscribeEvent
    public static void pickup(EntityItemPickupEvent event) {
        Player player = event.getEntity();
        ItemStack picked = event.getItem().getItem();
        for (ItemStack pouch : new ItemStack[] {player.getMainHandItem(), player.getOffhandItem()}) {
            if (!(pouch.getItem() instanceof SeedPouchItem) || pouch.getCount() != 1) continue;
            if (mutate(pouch, c -> !c.empty() && c.absorb(picked))) {
                player.level().playSound(null, player.getX(), player.getY(), player.getZ(), SoundEvents.BUNDLE_INSERT,
                        SoundSource.PLAYERS, 0.2F, (player.getRandom().nextFloat() - player.getRandom().nextFloat()) * 1.4F + 2F);
                return;
            }
        }
    }
}
