package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.CeilingHangingSignBlock;
import net.minecraft.world.level.block.ChainBlock;
import net.minecraft.world.level.block.LanternBlock;
import net.minecraft.world.level.block.SimpleWaterloggedBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * Quark's wooden post (WoodPostBlock, CC BY-NC-SA 3.0): a thin log on any axis whose sides
 * join chains, hanging lanterns and signs below, and posts lying on the same axis.
 */
public class WoodPostBlock extends Block implements SimpleWaterloggedBlock {
    public static final BooleanProperty WATERLOGGED = BlockStateProperties.WATERLOGGED;
    public static final EnumProperty<Direction.Axis> AXIS = BlockStateProperties.AXIS;
    @SuppressWarnings("unchecked")
    public static final EnumProperty<Side>[] SIDES = new EnumProperty[6];
    private static final VoxelShape CENTER = box(6, 6, 6, 10, 10, 10);
    private static final VoxelShape[] SIDE_BOXES = {
        box(6, 0, 6, 10, 10, 10), box(6, 6, 6, 10, 16, 10), box(6, 6, 0, 10, 10, 10),
        box(6, 6, 6, 10, 10, 16), box(0, 6, 6, 10, 10, 10), box(6, 6, 6, 16, 10, 10)
    };
    private static final VoxelShape[] SHAPES = new VoxelShape[64 * 3];

    static {
        for (Direction d : Direction.values()) {
            SIDES[d.ordinal()] = EnumProperty.create("connect_" + d.getSerializedName(), Side.class);
        }
    }

    public WoodPostBlock(Properties props) {
        super(props);
        BlockState s = stateDefinition.any().setValue(WATERLOGGED, false).setValue(AXIS, Direction.Axis.Y);
        for (EnumProperty<Side> p : SIDES) s = s.setValue(p, Side.NONE);
        registerDefaultState(s);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        int i = 64 * state.getValue(AXIS).ordinal();
        for (Direction d : Direction.values()) {
            if (state.getValue(SIDES[d.ordinal()]).solid()) i += 1 << d.ordinal();
        }
        VoxelShape shape = SHAPES[i];
        if (shape == null) {
            shape = CENTER;
            for (Direction d : Direction.values()) {
                if (state.getValue(AXIS) == d.getAxis() || state.getValue(SIDES[d.ordinal()]).solid()) {
                    shape = Shapes.or(shape, SIDE_BOXES[d.ordinal()]);
                }
            }
            SHAPES[i] = shape;
        }
        return shape;
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
        Direction.Axis axis = ctx.getClickedFace().getAxis();
        BlockPos pos = ctx.getClickedPos();
        BlockState s = defaultBlockState()
                .setValue(WATERLOGGED, ctx.getLevel().getFluidState(pos).getType() == Fluids.WATER)
                .setValue(AXIS, axis);
        for (Direction d : Direction.values()) {
            if (d.getAxis() != axis) s = s.setValue(SIDES[d.ordinal()], Side.of(ctx.getLevel(), pos, d));
        }
        return s;
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        if (state.getValue(WATERLOGGED)) level.scheduleTick(pos, Fluids.WATER, Fluids.WATER.getTickDelay(level));
        state = state.setValue(SIDES[facing.ordinal()], Side.of(level, pos, facing));
        return super.updateShape(state, facing, facingState, level, pos, facingPos);
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(WATERLOGGED, AXIS);
        b.add(SIDES);
    }

    public enum Side implements StringRepresentable {
        NONE("none"), CHAIN("chain"), OTHER_POST("other_post");

        private final String name;

        Side(String name) {
            this.name = name;
        }

        @Override
        public String getSerializedName() {
            return name;
        }

        boolean solid() {
            return this != NONE;
        }

        static Side of(LevelAccessor level, BlockPos pos, Direction d) {
            BlockState s = level.getBlockState(pos.relative(d));
            if ((s.getBlock() instanceof ChainBlock && s.getValue(BlockStateProperties.AXIS) == d.getAxis())
                    || (d == Direction.DOWN && s.getBlock() instanceof LanternBlock && s.getValue(LanternBlock.HANGING))
                    || (d == Direction.DOWN && s.getBlock() instanceof CeilingHangingSignBlock)) {
                return CHAIN;
            }
            if (s.getBlock() instanceof WoodPostBlock && s.getValue(AXIS) == d.getAxis()) return OTHER_POST;
            return NONE;
        }
    }
}
