package warpledge.quarkblocks;

import java.util.EnumSet;
import java.util.Locale;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.particles.DustParticleOptions;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.RedStoneWireBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraft.world.ticks.TickPriority;
import net.minecraftforge.event.ForgeEventFactory;

/**
 * Quark's redstone randomizer (RedstoneRandomizerBlock, CC BY-NC-SA 3.0): a diode that, each
 * time its input turns on, powers its left or right side at random.
 */
public class RedstoneRandomizerBlock extends Block {
    private static final VoxelShape SHAPE = box(0, 0, 0, 16, 2, 16);
    public static final DirectionProperty FACING = BlockStateProperties.HORIZONTAL_FACING;
    public static final EnumProperty<Power> POWERED = EnumProperty.create("powered", Power.class);

    public enum Power implements StringRepresentable {
        OFF, LEFT, RIGHT;

        @Override
        public String getSerializedName() {
            return name().toLowerCase(Locale.ROOT);
        }
    }

    public RedstoneRandomizerBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(FACING, Direction.NORTH).setValue(POWERED, Power.OFF));
    }

    @Override
    public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource rand) {
        boolean on = state.getValue(POWERED) != Power.OFF;
        boolean shouldBe = input(level, pos, state) > 0;
        if (on == shouldBe) return;
        Power old = state.getValue(POWERED);
        Power next = !shouldBe ? Power.OFF : rand.nextBoolean() ? Power.LEFT : Power.RIGHT;
        level.setBlockAndUpdate(pos, state.setValue(POWERED, next));
        Power side = old == Power.OFF ? next : old;
        Direction rel = side == Power.LEFT ? state.getValue(FACING).getClockWise()
                : state.getValue(FACING).getCounterClockWise();
        level.updateNeighborsAtExceptFromFacing(pos.relative(rel), this, rel.getOpposite());
    }

    private void updateState(Level level, BlockPos pos, BlockState state) {
        boolean on = state.getValue(POWERED) != Power.OFF;
        if (on != input(level, pos, state) > 0 && !level.getBlockTicks().willTickThisTick(pos, this)) {
            level.scheduleTick(pos, this, 2, on ? TickPriority.VERY_HIGH : TickPriority.HIGH);
        }
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(FACING, POWERED);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return SHAPE;
    }

    @Override
    public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return canSupportRigidBlock(level, pos.below());
    }

    @Override
    public int getDirectSignal(BlockState state, BlockGetter level, BlockPos pos, Direction side) {
        return state.getSignal(level, pos, side);
    }

    @Override
    public int getSignal(BlockState state, BlockGetter level, BlockPos pos, Direction side) {
        return switch (state.getValue(POWERED)) {
            case RIGHT -> state.getValue(FACING).getClockWise() == side ? 15 : 0;
            case LEFT -> state.getValue(FACING).getCounterClockWise() == side ? 15 : 0;
            default -> 0;
        };
    }

    @Override
    public void neighborChanged(BlockState state, Level level, BlockPos pos, Block block, BlockPos from, boolean moving) {
        if (state.canSurvive(level, pos)) {
            updateState(level, pos, state);
            return;
        }
        dropResources(state, level, pos, null);
        level.removeBlock(pos, false);
        for (Direction d : Direction.values()) level.updateNeighborsAt(pos.relative(d), this);
    }

    private int input(Level level, BlockPos pos, BlockState state) {
        Direction face = state.getValue(FACING);
        BlockPos at = pos.relative(face);
        int strength = level.getSignal(at, face);
        if (strength >= 15) return strength;
        BlockState s = level.getBlockState(at);
        return Math.max(strength, s.is(Blocks.REDSTONE_WIRE) ? s.getValue(RedStoneWireBlock.POWER) : 0);
    }

    @Override
    public boolean isSignalSource(BlockState state) {
        return true;
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        return defaultBlockState().setValue(FACING, ctx.getHorizontalDirection().getOpposite());
    }

    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        if (input(level, pos, state) > 0) level.scheduleTick(pos, this, 1);
    }

    @Override
    public void onPlace(BlockState state, Level level, BlockPos pos, BlockState old, boolean moving) {
        notifyNeighbors(level, pos, state);
    }

    @Override
    public void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean moving) {
        if (!moving && state.getBlock() != newState.getBlock()) {
            super.onRemove(state, level, pos, newState, false);
            notifyNeighbors(level, pos, state);
        }
    }

    private void notifyNeighbors(Level level, BlockPos pos, BlockState state) {
        Direction face = state.getValue(FACING);
        BlockPos behind = pos.relative(face.getOpposite());
        if (ForgeEventFactory.onNeighborNotify(level, pos, level.getBlockState(pos), EnumSet.of(face.getOpposite()),
                false).isCanceled()) {
            return;
        }
        level.neighborChanged(behind, this, pos);
        level.updateNeighborsAtExceptFromFacing(behind, this, face);
    }

    @Override
    public void animateTick(BlockState state, Level level, BlockPos pos, RandomSource rand) {
        if (state.getValue(POWERED) == Power.OFF) return;
        level.addParticle(DustParticleOptions.REDSTONE, pos.getX() + 0.5 + (rand.nextFloat() - 0.5) * 0.2,
                pos.getY() + 0.4 + (rand.nextFloat() - 0.5) * 0.2, pos.getZ() + 0.5 + (rand.nextFloat() - 0.5) * 0.2,
                0, 0, 0);
    }
}
