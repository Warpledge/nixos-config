package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.FenceBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraftforge.common.IPlantable;
import net.minecraftforge.common.PlantType;

/**
 * Quark's hedge (HedgeBlock, CC BY-NC-SA 3.0): a fence that joins only other hedges, on a
 * trunk, or with a filled base when it sits on another hedge (extend).
 */
public class HedgeBlock extends FenceBlock {
    public static final BooleanProperty EXTEND = BooleanProperty.create("extend");
    private static final VoxelShape WOOD = box(6, 0, 6, 10, 15, 10);
    private static final VoxelShape CENTER = box(2, 1, 2, 14, 16, 14);
    private static final VoxelShape NORTH_SIDE = box(2, 1, 0, 14, 16, 2);
    private static final VoxelShape SOUTH_SIDE = box(2, 1, 14, 14, 16, 15);
    private static final VoxelShape EAST_SIDE = box(14, 1, 2, 16, 16, 14);
    private static final VoxelShape WEST_SIDE = box(0, 1, 2, 2, 16, 14);
    private static final VoxelShape EXTEND_BASE = box(2, 0, 2, 14, 1, 14);
    private static final VoxelShape[] SHAPES = new VoxelShape[32];

    public HedgeBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(EXTEND, false));
    }

    @Override
    public VoxelShape getShape(BlockState s, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        int i = (s.getValue(NORTH) ? 1 : 0) | (s.getValue(SOUTH) ? 2 : 0) | (s.getValue(EAST) ? 4 : 0)
                | (s.getValue(WEST) ? 8 : 0) | (s.getValue(EXTEND) ? 16 : 0);
        VoxelShape shape = SHAPES[i];
        if (shape == null) {
            shape = Shapes.or(s.getValue(EXTEND) ? EXTEND_BASE : WOOD, CENTER);
            if (s.getValue(NORTH)) shape = Shapes.or(shape, NORTH_SIDE);
            if (s.getValue(SOUTH)) shape = Shapes.or(shape, SOUTH_SIDE);
            if (s.getValue(EAST)) shape = Shapes.or(shape, EAST_SIDE);
            if (s.getValue(WEST)) shape = Shapes.or(shape, WEST_SIDE);
            SHAPES[i] = shape;
        }
        return shape;
    }

    @Override
    public boolean connectsTo(BlockState state, boolean sideSolid, Direction dir) {
        return state.getBlock() instanceof HedgeBlock;
    }

    @Override
    public boolean canSustainPlant(BlockState state, BlockGetter level, BlockPos pos, Direction facing,
            IPlantable plant) {
        return facing == Direction.UP && !state.getValue(WATERLOGGED)
                && plant.getPlantType(level, pos.above()) == PlantType.PLAINS;
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        BlockState below = ctx.getLevel().getBlockState(ctx.getClickedPos().below());
        return super.getStateForPlacement(ctx).setValue(EXTEND, below.getBlock() instanceof HedgeBlock);
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        if (state.getValue(WATERLOGGED)) level.scheduleTick(pos, Fluids.WATER, Fluids.WATER.getTickDelay(level));
        if (facing == Direction.DOWN) return state.setValue(EXTEND, facingState.getBlock() instanceof HedgeBlock);
        return super.updateShape(state, facing, facingState, level, pos, facingPos);
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        super.createBlockStateDefinition(b);
        b.add(EXTEND);
    }
}
