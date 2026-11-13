package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.world.Containers;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.shapes.BooleanOp;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.EntityCollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraftforge.common.util.ForgeSoundType;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's feeding trough (FeedingTroughBlock, CC BY-NC-SA 3.0): nine slots of food that
 * nearby animals walk to, eat from and sometimes breed on (TroughFeeding). Animals can't
 * jump over it; a full trough breaks falls.
 */
public class FeedingTroughBlock extends Block implements EntityBlock {
    private static final SoundType PLANT_STEP = new ForgeSoundType(1F, 1F, () -> SoundEvents.WOOD_BREAK,
            () -> SoundEvents.GRASS_STEP, () -> SoundEvents.WOOD_PLACE, () -> SoundEvents.WOOD_HIT,
            () -> SoundEvents.WOOD_FALL);
    public static final BooleanProperty FULL = BooleanProperty.create("full");
    private static final VoxelShape CUBOID = box(0, 0, 0, 16, 8, 16);
    private static final VoxelShape EMPTY = Shapes.join(CUBOID, box(2, 2, 2, 14, 8, 14), BooleanOp.ONLY_FIRST);
    private static final VoxelShape FILLED = Shapes.join(CUBOID, box(2, 6, 2, 14, 8, 14), BooleanOp.ONLY_FIRST);
    private static final VoxelShape ANIMAL = box(0, 0, 0, 16, 24, 16);

    public FeedingTroughBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(FULL, false));
    }

    @Override
    public VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return ctx instanceof EntityCollisionContext e && e.getEntity() instanceof Animal ? ANIMAL : EMPTY;
    }

    @Override
    public VoxelShape getInteractionShape(BlockState state, BlockGetter level, BlockPos pos) {
        return CUBOID;
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return state.getValue(FULL) ? FILLED : EMPTY;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(FULL);
    }

    @Override
    public SoundType getSoundType(BlockState state) {
        return state.getValue(FULL) ? PLANT_STEP : super.getSoundType(state);
    }

    @Override
    public void fallOn(Level level, BlockState state, BlockPos pos, Entity entity, float distance) {
        if (state.getValue(FULL)) entity.causeFallDamage(distance, 0.2F, level.damageSources().fall());
        else super.fallOn(level, state, pos, entity, distance);
    }

    @Override
    public void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean moving) {
        if (state.getBlock() != newState.getBlock()) {
            if (level.getBlockEntity(pos) instanceof FeedingTroughBlockEntity trough) {
                Containers.dropContents(level, pos, trough);
                level.updateNeighbourForOutputSignal(pos, this);
            }
            super.onRemove(state, level, pos, newState, moving);
        }
    }

    @Override
    public boolean hasAnalogOutputSignal(BlockState state) {
        return true;
    }

    @Override
    public int getAnalogOutputSignal(BlockState state, Level level, BlockPos pos) {
        return AbstractContainerMenu.getRedstoneSignalFromBlockEntity(level.getBlockEntity(pos));
    }

    @Override
    public InteractionResult use(BlockState state, Level level, BlockPos pos, Player player, InteractionHand hand,
            BlockHitResult hit) {
        if (level.isClientSide) return InteractionResult.SUCCESS;
        if (level.getBlockEntity(pos) instanceof MenuProvider menu) NetworkHooks.openScreen((ServerPlayer) player, menu);
        return InteractionResult.CONSUME;
    }

    @Override
    public boolean triggerEvent(BlockState state, Level level, BlockPos pos, int id, int param) {
        super.triggerEvent(state, level, pos, id, param);
        BlockEntity be = level.getBlockEntity(pos);
        return be != null && be.triggerEvent(id, param);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new FeedingTroughBlockEntity(pos, state);
    }
}
