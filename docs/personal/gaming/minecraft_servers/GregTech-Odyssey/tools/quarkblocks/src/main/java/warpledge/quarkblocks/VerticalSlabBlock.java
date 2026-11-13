package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.tags.FluidTags;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Mirror;
import net.minecraft.world.level.block.Rotation;
import net.minecraft.world.level.block.SimpleWaterloggedBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.material.Fluid;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.level.pathfinder.PathComputationType;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * Quark's vertical slab (VerticalSlabBlock, CC BY-NC-SA 3.0): half a block against the
 * face it was placed on; a second one of the same slab fills it to a double.
 */
public class VerticalSlabBlock extends Block implements SimpleWaterloggedBlock {
    public static final EnumProperty<Type> TYPE = EnumProperty.create("type", Type.class);
    public static final BooleanProperty WATERLOGGED = BlockStateProperties.WATERLOGGED;

    public VerticalSlabBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(TYPE, Type.NORTH).setValue(WATERLOGGED, false));
    }

    @Override
    public BlockState rotate(BlockState state, Rotation rot) {
        Type t = state.getValue(TYPE);
        return t == Type.DOUBLE ? state : state.setValue(TYPE, Type.of(rot.rotate(t.direction)));
    }

    @Override
    public BlockState mirror(BlockState state, Mirror mirror) {
        Type t = state.getValue(TYPE);
        if (t == Type.DOUBLE || mirror == Mirror.NONE) return state;
        Direction.Axis flipped = mirror == Mirror.LEFT_RIGHT ? Direction.Axis.Z : Direction.Axis.X;
        return t.direction.getAxis() == flipped ? state.setValue(TYPE, Type.of(t.direction.getOpposite())) : state;
    }

    @Override
    public boolean useShapeForLightOcclusion(BlockState state) {
        return state.getValue(TYPE) != Type.DOUBLE;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(TYPE, WATERLOGGED);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return state.getValue(TYPE).shape;
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        BlockPos pos = ctx.getClickedPos();
        BlockState there = ctx.getLevel().getBlockState(pos);
        if (there.getBlock() == this) return there.setValue(TYPE, Type.DOUBLE).setValue(WATERLOGGED, false);
        return defaultBlockState()
                .setValue(WATERLOGGED, ctx.getLevel().getFluidState(pos).getType() == Fluids.WATER)
                .setValue(TYPE, Type.of(placementDirection(ctx)));
    }

    private static Direction placementDirection(BlockPlaceContext ctx) {
        Direction face = ctx.getClickedFace();
        if (face.getAxis() != Direction.Axis.Y) return face;
        BlockPos pos = ctx.getClickedPos();
        Vec3 v = ctx.getClickLocation().subtract(pos.getX() + 0.5, pos.getY(), pos.getZ() + 0.5);
        return Direction.fromYRot(Math.atan2(v.x, v.z) * -180.0 / Math.PI).getOpposite();
    }

    @Override
    public boolean canBeReplaced(BlockState state, BlockPlaceContext ctx) {
        Type t = state.getValue(TYPE);
        if (t == Type.DOUBLE || ctx.getItemInHand().getItem() != asItem()) return false;
        return ctx.replacingClickedOnBlock()
                ? ctx.getClickedFace() == t.direction && placementDirection(ctx) == t.direction
                : ctx.getClickedFace() != t.direction;
    }

    @Override
    public FluidState getFluidState(BlockState state) {
        return state.getValue(WATERLOGGED) ? Fluids.WATER.getSource(false) : super.getFluidState(state);
    }

    @Override
    public boolean placeLiquid(LevelAccessor level, BlockPos pos, BlockState state, FluidState fluid) {
        return state.getValue(TYPE) != Type.DOUBLE && SimpleWaterloggedBlock.super.placeLiquid(level, pos, state, fluid);
    }

    @Override
    public boolean canPlaceLiquid(BlockGetter level, BlockPos pos, BlockState state, Fluid fluid) {
        return state.getValue(TYPE) != Type.DOUBLE && SimpleWaterloggedBlock.super.canPlaceLiquid(level, pos, state, fluid);
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        if (state.getValue(WATERLOGGED)) level.scheduleTick(pos, Fluids.WATER, Fluids.WATER.getTickDelay(level));
        return super.updateShape(state, facing, facingState, level, pos, facingPos);
    }

    @Override
    public boolean isPathfindable(BlockState state, BlockGetter level, BlockPos pos, PathComputationType type) {
        return type == PathComputationType.WATER && level.getFluidState(pos).is(FluidTags.WATER);
    }

    public enum Type implements StringRepresentable {
        NORTH(Direction.NORTH), SOUTH(Direction.SOUTH), WEST(Direction.WEST), EAST(Direction.EAST), DOUBLE(null);

        final Direction direction;
        final VoxelShape shape;

        Type(Direction d) {
            direction = d;
            if (d == null) {
                shape = Shapes.block();
            } else {
                // The slab sits on the far side from its direction: north is z 8 to 16.
                double min = d.getAxisDirection() == Direction.AxisDirection.NEGATIVE ? 8 : 0;
                shape = d.getAxis() == Direction.Axis.X
                        ? box(min, 0, 0, min + 8, 16, 16)
                        : box(0, 0, min, 16, 16, min + 8);
            }
        }

        @Override
        public String getSerializedName() {
            return direction == null ? "double" : direction.getSerializedName();
        }

        static Type of(Direction d) {
            for (Type t : values()) if (t.direction == d) return t;
            return DOUBLE;
        }
    }
}
