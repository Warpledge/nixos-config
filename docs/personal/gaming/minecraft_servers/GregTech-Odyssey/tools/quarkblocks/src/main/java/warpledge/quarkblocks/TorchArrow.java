package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.Position;
import net.minecraft.core.dispenser.AbstractProjectileDispenseBehavior;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.projectile.AbstractArrow;
import net.minecraft.world.entity.projectile.Projectile;
import net.minecraft.world.item.ArrowItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.DispenserBlock;
import net.minecraft.world.level.block.WallTorchBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.Vec3;

/**
 * Quark's torch arrow (TorchArrow and TorchArrowModule, CC BY-NC-SA 3.0): places a torch
 * where it lands, sets what it hits alight for a second, and trails flame.
 */
public class TorchArrow extends AbstractArrow {
    public TorchArrow(EntityType<TorchArrow> type, Level level) {
        super(type, level);
    }

    TorchArrow(Level level, double x, double y, double z) {
        super(QuarkBlocks.TORCH_ARROW.get(), x, y, z, level);
    }

    TorchArrow(Level level, LivingEntity shooter) {
        super(QuarkBlocks.TORCH_ARROW.get(), shooter, level);
    }

    @Override
    public void tick() {
        super.tick();
        if (inGround || !level().isClientSide || tickCount <= 2) return;
        Vec3 m = getDeltaMovement();
        for (int i = 0; i < 6; i++) {
            level().addParticle(ParticleTypes.FLAME, getX() - m.x * (i / 6F) + (Math.random() - 0.5) * 0.1,
                    getY() - m.y * (i / 6F) + (Math.random() - 0.5) * 0.1, getZ() - m.z * (i / 6F) + (Math.random() - 0.5) * 0.1,
                    (Math.random() - 0.5) * 0.03 - m.x * 0.08, (Math.random() - 0.5) * 0.03 - m.y * 0.08,
                    (Math.random() - 0.5) * 0.03 - m.z * 0.08);
        }
    }

    @Override
    protected void onHitBlock(BlockHitResult result) {
        if (!level().isClientSide) {
            Direction dir = result.getDirection();
            BlockPos pos = result.getBlockPos().relative(dir);
            BlockState there = level().getBlockState(pos);
            if ((there.isAir() || there.canBeReplaced()) && dir != Direction.DOWN) {
                BlockState torch = dir == Direction.UP ? Blocks.TORCH.defaultBlockState()
                        : Blocks.WALL_TORCH.defaultBlockState().setValue(WallTorchBlock.FACING, dir);
                if (torch.canSurvive(level(), pos)) {
                    level().setBlock(pos, torch, 2);
                    playSound(torch.getSoundType().getPlaceSound());
                    discard();
                    return;
                }
            }
        }
        super.onHitBlock(result);
    }

    @Override
    protected void onHitEntity(EntityHitResult result) {
        setSecondsOnFire(1);
        super.onHitEntity(result);
        setSecondsOnFire(0);
    }

    @Override
    protected ItemStack getPickupItem() {
        return new ItemStack(QuarkBlocks.ALL_ITEMS.get("torch_arrow").get());
    }

    /** The torch arrow item; dispensers fire it too (registerDispenser). */
    public static class Item extends ArrowItem {
        public Item(Properties p) {
            super(p);
        }

        @Override
        public AbstractArrow createArrow(Level level, ItemStack stack, LivingEntity shooter) {
            return new TorchArrow(level, shooter);
        }
    }

    static void registerDispenser() {
        if (!QuarkItems.has("torch_arrow")) return;
        DispenserBlock.registerBehavior(QuarkBlocks.ALL_ITEMS.get("torch_arrow").get(), new AbstractProjectileDispenseBehavior() {
            @Override
            protected Projectile getProjectile(Level level, Position pos, ItemStack stack) {
                TorchArrow arrow = new TorchArrow(level, pos.x(), pos.y(), pos.z());
                arrow.pickup = Pickup.ALLOWED;
                return arrow;
            }
        });
    }
}
