package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.SimpleWaterloggedBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * Quark's stool (StoolBlock, CC BY-NC-SA 3.0): sit on it with a right click, it softens
 * and bounces falls, grows tall (big) when a block sits flush on top or a block is
 * shift-placed on it, and gives a comparator 15 while someone sits.
 */
public class StoolBlock extends Block implements SimpleWaterloggedBlock {
    public static final BooleanProperty WATERLOGGED = BlockStateProperties.WATERLOGGED;
    public static final BooleanProperty BIG = BooleanProperty.create("big");
    public static final BooleanProperty SAT_IN = BooleanProperty.create("sat_in");
    private static final VoxelShape SMALL = legs(box(0, 1, 0, 16, 9, 16), box(0, 0, 0, 4, 1, 4));
    private static final VoxelShape TALL = legs(box(0, 8, 0, 16, 16, 16), box(0, 0, 0, 4, 8, 4));

    private static VoxelShape legs(VoxelShape top, VoxelShape leg) {
        return Shapes.or(top, leg, leg.move(0.75, 0, 0), leg.move(0.75, 0, 0.75), leg.move(0, 0, 0.75));
    }

    public StoolBlock(Properties props) {
        super(props);
        registerDefaultState(stateDefinition.any().setValue(WATERLOGGED, false).setValue(BIG, false)
                .setValue(SAT_IN, false));
    }

    /** A block shift-placed on top makes the stool tall first (QuarkBlocks.stoolClicked). */
    void blockClicked(Level level, BlockPos pos) {
        BlockState state = level.getBlockState(pos);
        if (!state.getValue(BIG)) {
            level.setBlockAndUpdate(pos, state.setValue(BIG, true));
            level.scheduleTick(pos, this, 1);
        }
    }

    @Override
    public void tick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        fixState(level, pos, state);
    }

    @Override
    public InteractionResult use(BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand,
            BlockHitResult hit) {
        if (state.getValue(SAT_IN) || !level.getBlockState(pos.above()).isAir() || player.getVehicle() != null) {
            return super.use(state, level, pos, player, hand, hit);
        }
        if (!level.isClientSide) {
            StoolEntity seat = new StoolEntity(QuarkBlocks.STOOL.get(), level);
            seat.setPos(pos.getX() + 0.5, pos.getY() + 0.6, pos.getZ() + 0.5);
            level.addFreshEntity(seat);
            player.startRiding(seat);
            level.setBlockAndUpdate(pos, state.setValue(SAT_IN, true));
        }
        return InteractionResult.sidedSuccess(level.isClientSide);
    }

    @Override
    public void fallOn(Level level, BlockState state, BlockPos pos, Entity entity, float distance) {
        super.fallOn(level, state, pos, entity, distance * 0.5F);
    }

    @Override
    public void updateEntityAfterFallOn(BlockGetter level, Entity entity) {
        if (entity.isSuppressingBounce()) {
            super.updateEntityAfterFallOn(level, entity);
            return;
        }
        Vec3 v = entity.getDeltaMovement();
        if (v.y < 0) {
            double k = entity instanceof LivingEntity ? 1.0 : 0.8;
            entity.setDeltaMovement(v.x, -v.y * 0.66F * k, v.z);
        }
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return state.getValue(BIG) ? TALL : SMALL;
    }

    @Override
    public boolean propagatesSkylightDown(BlockState state, BlockGetter level, BlockPos pos) {
        return !state.getValue(WATERLOGGED);
    }

    @Override
    public FluidState getFluidState(BlockState state) {
        return state.getValue(WATERLOGGED) ? Fluids.WATER.getSource(false) : super.getFluidState(state);
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        return stateFor(ctx.getLevel(), ctx.getClickedPos());
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        if (state.getValue(WATERLOGGED)) level.scheduleTick(pos, Fluids.WATER, Fluids.WATER.getTickDelay(level));
        return super.updateShape(state, facing, facingState, level, pos, facingPos);
    }

    @Override
    public void neighborChanged(BlockState state, Level level, BlockPos pos, Block block, BlockPos from,
            boolean moving) {
        super.neighborChanged(state, level, pos, block, from, moving);
        fixState(level, pos, state);
    }

    private void fixState(Level level, BlockPos pos, BlockState state) {
        BlockState target = stateFor(level, pos);
        if (!target.equals(state)) level.setBlockAndUpdate(pos, target);
    }

    private BlockState stateFor(Level level, BlockPos pos) {
        BlockPos up = pos.above();
        return defaultBlockState()
                .setValue(WATERLOGGED, level.getFluidState(pos).getType() == Fluids.WATER)
                .setValue(BIG, level.getBlockState(up).getShape(level, up).min(Direction.Axis.Y) == 0)
                .setValue(SAT_IN, !level.getEntitiesOfClass(StoolEntity.class, new AABB(pos, up).inflate(0.4),
                        e -> e.blockPosition().equals(pos)).isEmpty());
    }

    @Override
    public boolean hasAnalogOutputSignal(BlockState state) {
        return true;
    }

    @Override
    public int getAnalogOutputSignal(BlockState state, Level level, BlockPos pos) {
        return state.getValue(SAT_IN) ? 15 : 0;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(WATERLOGGED, BIG, SAT_IN);
    }
}
