package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.stats.Stats;
import net.minecraft.tags.BlockTags;
import net.minecraft.util.RandomSource;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.FurnaceMenu;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.FurnaceBlock;
import net.minecraft.world.level.block.entity.AbstractFurnaceBlockEntity;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;

/**
 * Quark's deepslate and blackstone furnaces (VariantFurnaceBlock, SoulFurnaceBlock, CC
 * BY-NC-SA 3.0): ordinary furnaces; the blackstone one burns with soul flames when it
 * stands on soul fire base blocks (soul=true).
 */
public class VariantFurnaceBlock extends FurnaceBlock {
    public static final BooleanProperty SOUL = BooleanProperty.create("soul");
    // createBlockStateDefinition runs inside the super constructor, before fields are set.
    private static final ThreadLocal<Boolean> PENDING_SOUL = new ThreadLocal<>();
    private final boolean soul;

    static VariantFurnaceBlock create(Properties props, boolean soul) {
        PENDING_SOUL.set(soul);
        try {
            return new VariantFurnaceBlock(props, soul);
        } finally {
            PENDING_SOUL.remove();
        }
    }

    private VariantFurnaceBlock(Properties props, boolean soul) {
        super(props);
        this.soul = soul;
        if (soul) registerDefaultState(defaultBlockState().setValue(SOUL, false));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        super.createBlockStateDefinition(b);
        if (Boolean.TRUE.equals(PENDING_SOUL.get())) b.add(SOUL);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new Entity(pos, state);
    }

    @Override
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        return createFurnaceTicker(level, type, QuarkBlocks.FURNACE_BE.get());
    }

    @Override
    protected void openContainer(Level level, BlockPos pos, Player player) {
        if (level.getBlockEntity(pos) instanceof AbstractFurnaceBlockEntity furnace) {
            player.openMenu(furnace);
            player.awardStat(Stats.INTERACT_WITH_FURNACE);
        }
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        BlockState s = super.getStateForPlacement(ctx);
        return soul ? s.setValue(SOUL, ctx.getLevel().getBlockState(ctx.getClickedPos().below())
                .is(BlockTags.SOUL_FIRE_BASE_BLOCKS)) : s;
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        if (soul && facing == Direction.DOWN) return state.setValue(SOUL, facingState.is(BlockTags.SOUL_FIRE_BASE_BLOCKS));
        return super.updateShape(state, facing, facingState, level, pos, facingPos);
    }

    @Override
    public void animateTick(BlockState state, Level level, BlockPos pos, RandomSource random) {
        if (!(soul && state.getValue(LIT) && state.getValue(SOUL))) {
            super.animateTick(state, level, pos, random);
            return;
        }
        double x = pos.getX() + 0.5, y = pos.getY(), z = pos.getZ() + 0.5;
        if (random.nextDouble() < 0.1) {
            level.playLocalSound(x, y, z, SoundEvents.FURNACE_FIRE_CRACKLE, SoundSource.BLOCKS, 1F, 1F, false);
        }
        Direction dir = state.getValue(FACING);
        double side = random.nextDouble() * 0.6 - 0.3;
        double dx = dir.getAxis() == Direction.Axis.X ? dir.getStepX() * 0.52 : side;
        double dy = random.nextDouble() * 6.0 / 16.0;
        double dz = dir.getAxis() == Direction.Axis.Z ? dir.getStepZ() * 0.52 : side;
        level.addParticle(ParticleTypes.SMOKE, x + dx, y + dy, z + dz, 0, 0, 0);
        level.addParticle(ParticleTypes.SOUL_FIRE_FLAME, x + dx, y + dy, z + dz, 0, 0, 0);
    }

    /** quarkblocks:variant_furnace: a vanilla furnace under its own id. */
    public static class Entity extends AbstractFurnaceBlockEntity {
        public Entity(BlockPos pos, BlockState state) {
            super(QuarkBlocks.FURNACE_BE.get(), pos, state, RecipeType.SMELTING);
        }

        @Override
        protected Component getDefaultName() {
            return Component.translatable("container.furnace");
        }

        @Override
        protected AbstractContainerMenu createMenu(int id, Inventory inv) {
            return new FurnaceMenu(id, inv, this, dataAccess);
        }
    }
}
