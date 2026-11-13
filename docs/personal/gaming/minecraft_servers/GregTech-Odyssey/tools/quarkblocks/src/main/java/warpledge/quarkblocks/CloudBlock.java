package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.protocol.game.ClientboundBlockEntityDataPacket;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.RenderShape;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.level.material.PushReaction;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;

/**
 * Quark's cloud (CloudBlock and its block entity, CC BY-NC-SA 3.0): a bottled cloud's
 * mid-air block. It fades over 10 seconds; a block placed against it takes its place, and a
 * glass bottle takes it back.
 */
public class CloudBlock extends Block implements EntityBlock {
    public CloudBlock() {
        super(Properties.of().mapColor(MapColor.CLAY).sound(SoundType.WOOL).strength(0).noOcclusion()
                .noCollission().pushReaction(PushReaction.BLOCK));
    }

    @Override
    public RenderShape getRenderShape(BlockState state) {
        return RenderShape.INVISIBLE; // ClientSetup's renderer draws it shrinking
    }

    @Override
    public InteractionResult use(BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand,
            BlockHitResult hit) {
        ItemStack stack = player.getItemInHand(hand);
        if (stack.is(Items.GLASS_BOTTLE)) {
            fillBottle(player, player.getInventory().selected);
            level.removeBlock(pos, false);
            return InteractionResult.sidedSuccess(level.isClientSide);
        }
        if (stack.getItem() instanceof BlockItem item) {
            BlockPlaceContext ctx = new BlockPlaceContext(new UseOnContext(player, hand,
                    new BlockHitResult(new Vec3(0.5, 1, 0.5), hit.getDirection(), pos, false)));
            BlockState place = item.getBlock().getStateForPlacement(ctx);
            if (place != null && place.canSurvive(level, pos)) {
                level.setBlockAndUpdate(pos, place);
                level.playSound(player, pos, place.getSoundType().getPlaceSound(), SoundSource.BLOCKS, 1F, 1F);
                if (!player.getAbilities().instabuild) {
                    stack.shrink(1);
                    fillBottle(player, 0);
                }
                return InteractionResult.sidedSuccess(level.isClientSide);
            }
        }
        return InteractionResult.PASS;
    }

    @Override
    public ItemStack getCloneItemStack(BlockGetter level, BlockPos pos, BlockState state) {
        return new ItemStack(QuarkBlocks.ALL_ITEMS.get("bottled_cloud").get());
    }

    private static void fillBottle(Player player, int start) {
        Inventory inv = player.getInventory();
        for (int i = start; i < inv.getContainerSize(); i++) {
            ItemStack s = inv.getItem(i);
            if (s.is(Items.GLASS_BOTTLE)) {
                s.shrink(1);
                ItemStack cloud = new ItemStack(QuarkBlocks.ALL_ITEMS.get("bottled_cloud").get());
                if (!player.addItem(cloud)) player.drop(cloud, false);
                return;
            }
        }
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new Entity(pos, state);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        return type == QuarkBlocks.CLOUD_BE.get() ? (l, p, s, be) -> ((Entity) be).tick() : null;
    }

    /** quarkblocks:cloud; liveTime counts down from 200 ticks. */
    public static class Entity extends BlockEntity {
        int liveTime = -10000;

        public Entity(BlockPos pos, BlockState state) {
            super(QuarkBlocks.CLOUD_BE.get(), pos, state);
        }

        void tick() {
            if (liveTime < -1000) liveTime = 200;
            if (liveTime > 0) {
                liveTime--;
                if (level.isClientSide && liveTime % 20 == 0) {
                    for (int i = 0; i < 10 - (200 - liveTime) / 20; i++) {
                        level.addParticle(ParticleTypes.CLOUD, worldPosition.getX() + Math.random(),
                                worldPosition.getY() + Math.random(), worldPosition.getZ() + Math.random(), 0, 0, 0);
                    }
                }
            } else if (!level.isClientSide) {
                level.removeBlock(worldPosition, false);
            }
        }

        @Override
        protected void saveAdditional(CompoundTag tag) {
            super.saveAdditional(tag);
            tag.putInt("liveTime", liveTime);
        }

        @Override
        public void load(CompoundTag tag) {
            super.load(tag);
            liveTime = tag.getInt("liveTime");
        }

        @Override
        public CompoundTag getUpdateTag() {
            return saveWithoutMetadata();
        }

        @Override
        public Packet<ClientGamePacketListener> getUpdatePacket() {
            return ClientboundBlockEntityDataPacket.create(this);
        }
    }
}
