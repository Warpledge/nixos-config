package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.pathfinder.PathComputationType;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraftforge.common.capabilities.Capability;
import net.minecraftforge.common.capabilities.ForgeCapabilities;
import net.minecraftforge.common.util.LazyOptional;
import net.minecraftforge.items.IItemHandler;

/**
 * Quark's chute (ChuteBlock and its block entity, CC BY-NC-SA 3.0): items put into it from
 * the top or sides drop out below as item entities, unless it's powered or the space
 * below is blocked.
 */
public class ChuteBlock extends Block implements EntityBlock {
    public static final BooleanProperty ENABLED = BlockStateProperties.ENABLED;
    private static final VoxelShape SHAPE = Shapes.or(box(4, 4, 4, 12, 10, 12), box(0, 10, 0, 16, 16, 16),
            box(6, 0, 6, 10, 4, 10));
    private static final AABB CLEARANCE = new AABB(BlockPos.ZERO).deflate(0.25).move(0, 0.25, 0);

    public ChuteBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(ENABLED, true));
    }

    @Override
    public void neighborChanged(BlockState state, Level level, BlockPos pos, Block block, BlockPos from, boolean moving) {
        boolean enabled = !level.hasNeighborSignal(pos);
        if (enabled != state.getValue(ENABLED)) level.setBlock(pos, state.setValue(ENABLED, enabled), 2 | 4);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return SHAPE;
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(ENABLED);
    }

    @Override
    public boolean isPathfindable(BlockState state, BlockGetter level, BlockPos pos, PathComputationType type) {
        return false;
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new Entity(pos, state);
    }

    /** quarkblocks:chute: an item handler that drops what it's given. */
    public static class Entity extends BlockEntity {
        private final LazyOptional<IItemHandler> handler = LazyOptional.of(() -> new IItemHandler() {
            @Override
            public int getSlots() {
                return 1;
            }

            @Override
            public ItemStack getStackInSlot(int slot) {
                return ItemStack.EMPTY;
            }

            @Override
            public ItemStack insertItem(int slot, ItemStack stack, boolean simulate) {
                if (!canDrop()) return stack;
                if (!simulate && level != null && !stack.isEmpty()) {
                    ItemEntity item = new ItemEntity(level, worldPosition.getX() + 0.5, worldPosition.getY() - 0.5,
                            worldPosition.getZ() + 0.5, stack.copy());
                    item.setDeltaMovement(0, 0, 0);
                    level.addFreshEntity(item);
                }
                return ItemStack.EMPTY;
            }

            @Override
            public ItemStack extractItem(int slot, int amount, boolean simulate) {
                return ItemStack.EMPTY;
            }

            @Override
            public int getSlotLimit(int slot) {
                return 64;
            }

            @Override
            public boolean isItemValid(int slot, ItemStack stack) {
                return true;
            }
        });

        public Entity(BlockPos pos, BlockState state) {
            super(QuarkBlocks.CHUTE_BE.get(), pos, state);
        }

        private boolean canDrop() {
            if (level == null || !level.getBlockState(worldPosition).getValue(ENABLED)) return false;
            BlockPos below = worldPosition.below();
            BlockState state = level.getBlockState(below);
            if (state.isAir() || QuarkBlocks.ALL.containsKey("grate") && state.is(QuarkBlocks.ALL.get("grate").get())) {
                return true;
            }
            VoxelShape shape = state.getCollisionShape(level, below);
            if (shape.isEmpty()) return true;
            if (shape.max(Direction.Axis.Y) > 1) return false;
            for (AABB box : shape.toAabbs()) if (box.intersects(CLEARANCE)) return false;
            return true;
        }

        @Override
        public <T> LazyOptional<T> getCapability(Capability<T> cap, Direction side) {
            if (side != Direction.DOWN && cap == ForgeCapabilities.ITEM_HANDLER) return handler.cast();
            return super.getCapability(cap, side);
        }

        @Override
        public void invalidateCaps() {
            super.invalidateCaps();
            handler.invalidate();
        }
    }
}
