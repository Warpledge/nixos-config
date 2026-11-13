package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MoverType;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.piston.PistonMovingBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.network.NetworkHooks;

/**
 * The invisible seat a stool spawns (Quark's Stool entity, CC BY-NC-SA 3.0). It goes when
 * its rider leaves or the stool is gone, and follows a stool a piston moves.
 */
public class StoolEntity extends Entity {
    public StoolEntity(EntityType<?> type, Level level) {
        super(type, level);
    }

    @Override
    public void tick() {
        super.tick();
        boolean gone = getPassengers().isEmpty();
        BlockPos pos = blockPosition();
        BlockState state = level().getBlockState(pos);
        if (!gone && !(state.getBlock() instanceof StoolBlock)) {
            PistonMovingBlockEntity piston = movingStool(pos);
            for (Direction d : Direction.values()) {
                if (piston == null) piston = movingStool(pos.relative(d));
            }
            if (piston != null) {
                Direction dir = piston.getMovementDirection();
                move(MoverType.PISTON, new Vec3(dir.getStepX() * 0.33, dir.getStepY() * 0.33, dir.getStepZ() * 0.33));
            } else {
                gone = true;
            }
        }
        if (gone && !level().isClientSide) {
            discard();
            if (state.getBlock() instanceof StoolBlock) {
                level().setBlockAndUpdate(pos, state.setValue(StoolBlock.SAT_IN, false));
            }
        }
    }

    private PistonMovingBlockEntity movingStool(BlockPos pos) {
        BlockEntity be = level().getBlockEntity(pos);
        return be instanceof PistonMovingBlockEntity p && p.getMovedState().getBlock() instanceof StoolBlock ? p : null;
    }

    @Override
    public double getPassengersRidingOffset() {
        return -0.3;
    }

    @Override
    protected void defineSynchedData() {}

    @Override
    protected void readAdditionalSaveData(CompoundTag tag) {}

    @Override
    protected void addAdditionalSaveData(CompoundTag tag) {}

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }
}
