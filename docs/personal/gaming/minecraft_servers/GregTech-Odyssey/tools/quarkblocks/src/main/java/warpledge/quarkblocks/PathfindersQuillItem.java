package warpledge.quarkblocks;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import net.minecraft.ChatFormatting;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.GlobalPos;
import net.minecraft.core.QuartPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceKey;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.MapItem;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.biome.Biome;
import net.minecraft.world.level.saveddata.maps.MapDecoration;
import net.minecraft.world.level.saveddata.maps.MapItemSavedData;
import net.minecraft.core.registries.Registries;

/**
 * Quark's pathfinder's quill (PathfindersQuillItem, CC BY-NC-SA 3.0, with
 * PathfinderMapsModule's defaults): use it and it searches outward in a square spiral, up to
 * 6400 blocks, for the biome written in it ("targetBiome"), off the server thread, then turns
 * into a map marked with the spot.
 */
public class PathfindersQuillItem extends Item {
    private static final Direction[] DIRECTIONS = {Direction.EAST, Direction.SOUTH, Direction.WEST, Direction.NORTH};
    private static final int RADIUS = 6400;
    private static final int STEP = 32;
    private record Key(GlobalPos pos, ResourceLocation biome) {}
    private static final Map<Key, BlockPos> RESULTS = new ConcurrentHashMap<>();
    private static final Set<Key> COMPUTING = ConcurrentHashMap.newKeySet();
    private static final ExecutorService EXECUTOR = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "quarkblocks quill search");
        t.setDaemon(true);
        return t;
    });
    // A search that found nothing.
    private static final BlockPos NONE = new BlockPos(0, Integer.MIN_VALUE, 0);

    public PathfindersQuillItem(Properties p) {
        super(p);
    }

    static ResourceLocation target(ItemStack stack) {
        CompoundTag tag = stack.getTag();
        return tag == null || tag.getString("targetBiome").isEmpty() ? null : new ResourceLocation(tag.getString("targetBiome"));
    }

    static int color(ItemStack stack) {
        CompoundTag tag = stack.getTag();
        return tag != null && tag.contains("targetBiomeColor") ? tag.getInt("targetBiomeColor") : 0xFFFFFF;
    }

    private static boolean searching(ItemStack stack) {
        return stack.hasTag() && stack.getTag().getBoolean("isSearchingForBiome");
    }

    private static ItemStack activeQuill(Player player) {
        for (List<ItemStack> list : List.of(player.getInventory().items, player.getInventory().offhand,
                player.getInventory().armor)) {
            for (ItemStack s : list) if (s.getItem() instanceof PathfindersQuillItem && searching(s)) return s;
        }
        return null;
    }

    @Override
    public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
        ItemStack stack = player.getItemInHand(hand);
        if (target(stack) == null) return InteractionResultHolder.pass(stack);
        if (activeQuill(player) != null) {
            player.displayClientMessage(Component.translatable("quarkblocks.misc.only_one_quill"), true);
            return InteractionResultHolder.fail(stack);
        }
        level.playSound(null, player.getX(), player.getY(), player.getZ(), SoundEvents.BOOK_PAGE_TURN, SoundSource.PLAYERS,
                0.5F, 1F);
        CompoundTag tag = stack.getOrCreateTag();
        tag.putBoolean("isSearchingForBiome", true);
        tag.putInt("searchSourceX", player.getBlockX());
        tag.putInt("searchSourceZ", player.getBlockZ());
        return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
    }

    @Override
    public boolean shouldCauseReequipAnimation(ItemStack old, ItemStack now, boolean slotChanged) {
        return slotChanged || old.getItem() != now.getItem();
    }

    @Override
    public void inventoryTick(ItemStack stack, Level level, Entity entity, int slot, boolean held) {
        if (!(level instanceof ServerLevel server) || !searching(stack) || !(entity instanceof Player player)
                || activeQuill(player) != stack) {
            return;
        }
        ResourceLocation biome = target(stack);
        if (biome == null) return;
        CompoundTag tag = stack.getTag();
        Key key = new Key(GlobalPos.of(level.dimension(),
                new BlockPos(tag.getInt("searchSourceX"), 64, tag.getInt("searchSourceZ"))), biome);
        BlockPos found = RESULTS.get(key);
        if (found == null) {
            if (COMPUTING.add(key)) {
                ItemStack copy = stack.copy();
                int y = player.getBlockY();
                EXECUTOR.submit(() -> {
                    RESULTS.put(key, search(biome, copy, server, y));
                    COMPUTING.remove(key);
                });
            }
            return;
        }
        RESULTS.remove(key);
        ItemStack result;
        String msg;
        if (found == NONE) {
            // Quark's allowRetrying: the quill stays, ready to try from somewhere else.
            for (String k : new String[] {"searchSourceX", "searchSourceZ", "isSearchingForBiome", "searchPosX",
                    "searchPosZ", "searchPosLeg", "searchPosLegIndex"}) {
                tag.remove(k);
            }
            result = stack;
            msg = "quarkblocks.misc.quill_retry";
        } else {
            result = map(server, found, biome, stack);
            msg = "quarkblocks.misc.quill_finished";
        }
        player.displayClientMessage(Component.translatable(msg), true);
        level.playSound(null, player.getX(), player.getY(), player.getZ(), SoundEvents.NOTE_BLOCK_CHIME.get(),
                SoundSource.PLAYERS, 0.5F, 1F);
        if (player.getOffhandItem() == stack) player.setItemInHand(InteractionHand.OFF_HAND, result);
        else player.getInventory().setItem(slot, result);
    }

    private static BlockPos search(ResourceLocation biome, ItemStack stack, ServerLevel level, int y) {
        ResourceKey<Biome> key = ResourceKey.create(Registries.BIOME, biome);
        var source = level.getChunkSource().getGenerator().getBiomeSource();
        var sampler = level.getChunkSource().randomState().sampler();
        while (true) {
            BlockPos next = nextPos(stack);
            if (next == null) return NONE;
            for (int testY : Mth.outFromOrigin(y, level.getMinBuildHeight() + 1, level.getMaxBuildHeight(), 64).toArray()) {
                if (source.getNoiseBiome(QuartPos.fromBlock(next.getX()), QuartPos.fromBlock(testY),
                        QuartPos.fromBlock(next.getZ()), sampler).is(key)) {
                    return new BlockPos(next.getX(), testY, next.getZ());
                }
            }
        }
    }

    /** The next point of the square spiral, 32 blocks apart, kept in the stack's NBT. */
    private static BlockPos nextPos(ItemStack stack) {
        CompoundTag tag = stack.getOrCreateTag();
        int leg = tag.contains("searchPosLeg") ? tag.getInt("searchPosLeg") : -1;
        int legIndex = tag.getInt("searchPosLegIndex");
        BlockPos cursor = new BlockPos(tag.getInt("searchPosX"), 0, tag.getInt("searchPosZ"))
                .relative(DIRECTIONS[(leg + 4) % 4]);
        if (legIndex >= leg / 2 + 1) {
            if (leg > 4 * Math.floorDiv(RADIUS, STEP)) return null;
            leg++;
            legIndex = 0;
        }
        legIndex++;
        tag.putInt("searchPosX", cursor.getX());
        tag.putInt("searchPosZ", cursor.getZ());
        tag.putInt("searchPosLeg", leg);
        tag.putInt("searchPosLegIndex", legIndex);
        return new BlockPos(tag.getInt("searchSourceX") + cursor.getX() * STEP, 0,
                tag.getInt("searchSourceZ") + cursor.getZ() * STEP);
    }

    private static ItemStack map(ServerLevel level, BlockPos pos, ResourceLocation biome, ItemStack quill) {
        ItemStack stack = MapItem.create(level, pos.getX(), pos.getZ(), (byte) 2, true, true);
        MapItem.renderBiomePreviewMap(level, stack);
        MapItemSavedData.addTargetDecoration(stack, pos, "+", MapDecoration.Type.RED_X);
        stack.setHoverName(Component.translatable("item.quarkblocks.biome_map",
                Component.translatable("biome." + biome.getNamespace() + "." + biome.getPath())));
        stack.getOrCreateTagElement("display").putInt("MapColor", color(quill));
        stack.getOrCreateTag().putBoolean("quarkblocks:pathfinder", true);
        return stack;
    }

    @Override
    public void appendHoverText(ItemStack stack, Level level, List<Component> lines, TooltipFlag flag) {
        ResourceLocation biome = target(stack);
        if (biome == null) {
            lines.add(Component.translatable("quarkblocks.misc.quill_blank").withStyle(ChatFormatting.GRAY));
            return;
        }
        if (searching(stack)) {
            lines.add(Component.translatable("quarkblocks.misc.quill_searching").withStyle(ChatFormatting.BLUE));
        }
        lines.add(Component.translatable("biome." + biome.getNamespace() + "." + biome.getPath())
                .withStyle(ChatFormatting.GRAY));
    }
}
