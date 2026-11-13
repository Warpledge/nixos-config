package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.material.MapColor;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * Quark's leaf carpet (LeafCarpetBlock, CC BY-NC-SA 3.0): a walk-through layer of leaves
 * that breaks when the block under it goes, and that any other block replaces.
 */
public class LeafCarpetBlock extends Block {
    private static final VoxelShape SHAPE = box(0, 0, 0, 16, 1, 16);

    public LeafCarpetBlock(MapColor color) {
        super(Properties.of().mapColor(color).noCollission().strength(0F).sound(SoundType.GRASS)
                .noOcclusion().ignitedByLava());
    }

    @Override
    public boolean canBeReplaced(BlockState state, BlockPlaceContext ctx) {
        return ctx.getItemInHand().isEmpty() || ctx.getItemInHand().getItem() != asItem();
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return SHAPE;
    }

    @Override
    public VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return Shapes.empty();
    }

    @Override
    public BlockState updateShape(BlockState state, Direction facing, BlockState facingState,
            LevelAccessor level, BlockPos pos, BlockPos facingPos) {
        return state.canSurvive(level, pos) ? super.updateShape(state, facing, facingState, level, pos, facingPos)
                : Blocks.AIR.defaultBlockState();
    }

    @Override
    public boolean canSurvive(BlockState state, LevelReader level, BlockPos pos) {
        return !level.isEmptyBlock(pos.below());
    }
}
