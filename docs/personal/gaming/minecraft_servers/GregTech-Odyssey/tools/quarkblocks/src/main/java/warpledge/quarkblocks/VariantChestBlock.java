package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.stats.Stat;
import net.minecraft.stats.Stats;
import net.minecraft.util.Mth;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.block.ChestBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.ChestBlockEntity;
import net.minecraft.world.level.block.state.BlockState;

/**
 * Quark's wood and stone chests (VariantChestBlock and VariantTrappedChestBlock, CC BY-NC-SA
 * 3.0): vanilla chests with their own textures; a trapped one powers redstone while open.
 */
public class VariantChestBlock extends ChestBlock {
    final String texture;
    final boolean trapped;

    public VariantChestBlock(Properties props, String texture, boolean trapped) {
        super(props, () -> trapped ? QuarkBlocks.TRAPPED_CHEST_BE.get() : QuarkBlocks.CHEST_BE.get());
        this.texture = texture;
        this.trapped = trapped;
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return trapped ? new VariantChestBlockEntity.Trapped(pos, state) : new VariantChestBlockEntity(pos, state);
    }

    @Override
    protected Stat<ResourceLocation> getOpenChestStat() {
        return trapped ? Stats.CUSTOM.get(Stats.TRIGGER_TRAPPED_CHEST) : super.getOpenChestStat();
    }

    @Override
    public boolean isSignalSource(BlockState state) {
        return trapped;
    }

    @Override
    public int getSignal(BlockState state, BlockGetter level, BlockPos pos, Direction side) {
        return trapped ? Mth.clamp(ChestBlockEntity.getOpenCount(level, pos), 0, 15) : 0;
    }

    @Override
    public int getDirectSignal(BlockState state, BlockGetter level, BlockPos pos, Direction side) {
        return trapped && side == Direction.UP ? state.getSignal(level, pos, side) : 0;
    }
}
