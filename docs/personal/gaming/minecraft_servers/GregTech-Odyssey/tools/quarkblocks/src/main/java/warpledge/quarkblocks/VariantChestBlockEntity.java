package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.entity.ChestBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.AABB;

/**
 * quarkblocks:variant_chest, the id the templates' chest data names once libgate renames
 * quark: (Quark's VariantChestBlockEntity, CC BY-NC-SA 3.0). Loot tables and items load
 * as in a vanilla chest.
 */
public class VariantChestBlockEntity extends ChestBlockEntity {
    protected VariantChestBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
        super(type, pos, state);
    }

    public VariantChestBlockEntity(BlockPos pos, BlockState state) {
        this(QuarkBlocks.CHEST_BE.get(), pos, state);
    }

    @Override
    public AABB getRenderBoundingBox() {
        return new AABB(worldPosition.offset(-1, 0, -1), worldPosition.offset(2, 2, 2));
    }

    /** quarkblocks:variant_trapped_chest; tells redstone when the open count changes. */
    public static class Trapped extends VariantChestBlockEntity {
        public Trapped(BlockPos pos, BlockState state) {
            super(QuarkBlocks.TRAPPED_CHEST_BE.get(), pos, state);
        }

        @Override
        protected void signalOpenCount(Level level, BlockPos pos, BlockState state, int prev, int now) {
            super.signalOpenCount(level, pos, state, prev, now);
            if (prev != now) {
                Block block = state.getBlock();
                level.updateNeighborsAt(pos, block);
                level.updateNeighborsAt(pos.below(), block);
            }
        }
    }
}
