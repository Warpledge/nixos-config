package warpledge.quarkblocks;

import java.util.HashSet;
import java.util.Set;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.Mirror;
import net.minecraft.world.level.block.Rotation;
import net.minecraft.world.level.block.SimpleWaterloggedBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * Quark's copper pipe (BasePipeBlock and CopperPipeBlock, CC BY-NC-SA 3.0): carries items
 * between pipes and inventories, pulls in items thrown into an open end and shoots them
 * out of one; a redstone signal stops it. A stick re-joins a pipe network's sides.
 * Encasing with glass is left out: no structure has encased pipes.
 */
public class PipeBlock extends Block implements EntityBlock, SimpleWaterloggedBlock {
    public static final BooleanProperty WATERLOGGED = BlockStateProperties.WATERLOGGED;
    private static final BooleanProperty[] SIDES = {BlockStateProperties.DOWN, BlockStateProperties.UP,
        BlockStateProperties.NORTH, BlockStateProperties.SOUTH, BlockStateProperties.WEST, BlockStateProperties.EAST};
    private static final VoxelShape CENTER = box(5, 5, 5, 11, 11, 11);
    private static final VoxelShape[] SIDE_BOXES = {box(5, 0, 5, 11, 11, 11), box(5, 5, 5, 11, 16, 11),
        box(5, 5, 0, 11, 11, 11), box(5, 5, 5, 11, 11, 16), box(0, 5, 5, 11, 11, 11), box(5, 5, 5, 16, 11, 11)};
    private static final VoxelShape[] SHAPES = new VoxelShape[64];

    public PipeBlock(Properties props) {
        super(props);
        BlockState s = defaultBlockState().setValue(WATERLOGGED, false);
        for (BooleanProperty p : SIDES) s = s.setValue(p, false);
        registerDefaultState(s);
    }

    static BooleanProperty side(Direction d) {
        return SIDES[d.ordinal()];
    }

    @Override
    public InteractionResult use(BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand,
            BlockHitResult hit) {
        if (!player.getItemInHand(hand).is(Items.STICK)) return super.use(state, level, pos, player, hand, hit);
        Set<BlockPos> seen = new HashSet<>();
        Set<BlockPos> todo = new HashSet<>(Set.of(pos));
        boolean fixed = false;
        while (!todo.isEmpty()) {
            Set<BlockPos> next = new HashSet<>();
            for (BlockPos p : todo) {
                for (Direction d : Direction.values()) {
                    BlockPos o = p.relative(d);
                    if (level.getBlockState(o).getBlock() == this && !todo.contains(o) && !seen.contains(o)) next.add(o);
                }
                BlockState target = targetState(level, p);
                if (!target.equals(level.getBlockState(p))) {
                    fixed = true;
                    level.setBlock(p, target, 2 | 4);
                }
            }
            seen.addAll(todo);
            todo = next;
        }
        return fixed ? InteractionResult.sidedSuccess(level.isClientSide) : super.use(state, level, pos, player, hand, hit);
    }

    @Override
    public BlockState rotate(BlockState state, Rotation rot) {
        BlockState s = state;
        for (Direction d : Direction.values()) s = s.setValue(side(d), state.getValue(side(rot.rotate(d))));
        return s;
    }

    @Override
    public BlockState mirror(BlockState state, Mirror mirror) {
        BlockState s = state;
        for (Direction d : Direction.values()) s = s.setValue(side(d), state.getValue(side(mirror.mirror(d))));
        return s;
    }

    @Override
    public BlockState updateShape(BlockState state, Direction dir, BlockState neighbour, LevelAccessor level,
            BlockPos pos, BlockPos neighbourPos) {
        if (state.getValue(WATERLOGGED)) level.scheduleTick(pos, Fluids.WATER, Fluids.WATER.getTickDelay(level));
        for (Direction d : Direction.values()) {
            state = state.setValue(side(d), PipeBlockEntity.connectionTo(level, pos, d).solid);
        }
        if (level.getBlockEntity(pos) instanceof PipeBlockEntity pipe) pipe.refreshConnections();
        return state;
    }

    @Override
    public void neighborChanged(BlockState state, Level level, BlockPos pos, Block block, BlockPos from, boolean moving) {
        super.neighborChanged(state, level, pos, block, from, moving);
        if (level.getBlockEntity(pos) instanceof PipeBlockEntity pipe) pipe.refreshConnections();
    }

    @Override
    public BlockState getStateForPlacement(BlockPlaceContext ctx) {
        return targetState(ctx.getLevel(), ctx.getClickedPos());
    }

    @Override
    public void setPlacedBy(Level level, BlockPos pos, BlockState state, LivingEntity placer, ItemStack stack) {
        if (level.getBlockEntity(pos) instanceof PipeBlockEntity pipe) pipe.refreshConnections();
    }

    @Override
    public void onPlace(BlockState state, Level level, BlockPos pos, BlockState old, boolean moving) {
        if (level.getBlockEntity(pos) instanceof PipeBlockEntity pipe) pipe.refreshConnections();
    }

    private BlockState targetState(LevelAccessor level, BlockPos pos) {
        BlockState s = defaultBlockState().setValue(WATERLOGGED, level.getFluidState(pos).getType() == Fluids.WATER);
        for (Direction d : Direction.values()) s = s.setValue(side(d), PipeBlockEntity.connectionTo(level, pos, d).solid);
        return s;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(SIDES).add(WATERLOGGED);
    }

    @Override
    public FluidState getFluidState(BlockState state) {
        return state.getValue(WATERLOGGED) ? Fluids.WATER.getSource(false) : super.getFluidState(state);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        int i = 0;
        for (Direction d : Direction.values()) if (state.getValue(side(d))) i |= 1 << d.ordinal();
        VoxelShape shape = SHAPES[i];
        if (shape == null) {
            shape = CENTER;
            for (Direction d : Direction.values()) {
                if (state.getValue(side(d))) shape = Shapes.or(shape, SIDE_BOXES[d.ordinal()]);
            }
            SHAPES[i] = shape;
        }
        return shape;
    }

    @Override
    public boolean hasAnalogOutputSignal(BlockState state) {
        return true;
    }

    @Override
    public int getAnalogOutputSignal(BlockState state, Level level, BlockPos pos) {
        return level.getBlockEntity(pos) instanceof PipeBlockEntity pipe ? pipe.comparatorOutput() : 0;
    }

    @Override
    public void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean moving) {
        if (level.getBlockEntity(pos) instanceof PipeBlockEntity pipe) pipe.dropAll();
        super.onRemove(state, level, pos, newState, moving);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new PipeBlockEntity(pos, state);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        return type == QuarkBlocks.PIPE_BE.get() ? (l, p, s, be) -> ((PipeBlockEntity) be).tick() : null;
    }
}
