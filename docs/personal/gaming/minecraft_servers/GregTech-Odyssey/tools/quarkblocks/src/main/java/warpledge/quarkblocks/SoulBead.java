package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.BlockParticleOption;
import net.minecraft.core.particles.DustParticleOptions;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.core.registries.Registries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundSource;
import net.minecraft.stats.Stats;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.levelgen.structure.Structure;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.network.NetworkHooks;
import org.joml.Vector3f;

/**
 * Quark's soul bead (SoulBeadItem and the SoulBead entity, CC BY-NC-SA 3.0): used, it sends
 * a trail of soul dust spiralling towards the nearest structure tagged
 * quarkblocks:soul_bead_target (Quark's list: nether fortresses).
 */
public class SoulBead extends Entity {
    private static final EntityDataAccessor<Integer> TARGET_X = SynchedEntityData.defineId(SoulBead.class,
            EntityDataSerializers.INT);
    private static final EntityDataAccessor<Integer> TARGET_Z = SynchedEntityData.defineId(SoulBead.class,
            EntityDataSerializers.INT);
    static final TagKey<Structure> TARGETS = TagKey.create(Registries.STRUCTURE, QuarkBlocks.rl("soul_bead_target"));
    private int liveTicks;

    public SoulBead(EntityType<? extends SoulBead> type, Level level) {
        super(type, level);
    }

    @Override
    protected void defineSynchedData() {
        entityData.define(TARGET_X, 0);
        entityData.define(TARGET_Z, 0);
    }

    @Override
    public void tick() {
        super.tick();
        int max = 6000;
        int particles = Math.min(20, max - liveTicks);
        double arg = liveTicks * 0.32;
        Vec3 v = new Vec3(entityData.get(TARGET_X), getY(), entityData.get(TARGET_Z)).subtract(position()).normalize()
                .scale(0.08);
        double bx = getX() + v.x * liveTicks + Math.cos(arg) * 1.5;
        double by = getY() + v.y * liveTicks + liveTicks * 0.025;
        double bz = getZ() + v.z * liveTicks + Math.sin(arg) * 1.5;
        for (int i = 0; i < particles; i++) {
            double px = bx + (Math.random() - 0.5) * 0.4, py = by + (Math.random() - 0.5) * 0.4,
                    pz = bz + (Math.random() - 0.5) * 0.4;
            level().addParticle(new DustParticleOptions(new Vector3f(0.2F, 0.12F, 0.1F), 1F), px, py, pz, 0, 0, 0);
            if (Math.random() < 0.05) {
                level().addParticle(new BlockParticleOption(ParticleTypes.FALLING_DUST, Blocks.SOUL_SAND.defaultBlockState()),
                        px, py, pz, 0, 0, 0);
            }
        }
        if (Math.random() < 0.1) {
            level().playSound(null, bx, by, bz, QuarkBlocks.SOUND_BY_NAME.get("entity.soul_bead.idle").get(),
                    SoundSource.PLAYERS, 0.2F, 1F);
        }
        if (++liveTicks > max) discard();
    }

    @Override
    protected void readAdditionalSaveData(CompoundTag tag) {
        entityData.set(TARGET_X, tag.getInt("targetX"));
        entityData.set(TARGET_Z, tag.getInt("targetZ"));
    }

    @Override
    protected void addAdditionalSaveData(CompoundTag tag) {
        tag.putInt("targetX", entityData.get(TARGET_X));
        tag.putInt("targetZ", entityData.get(TARGET_Z));
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }

    /** The soul bead item. */
    public static class Item extends net.minecraft.world.item.Item {
        public Item(Properties p) {
            super(p);
        }

        @Override
        public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
            ItemStack stack = player.getItemInHand(hand);
            if (level instanceof ServerLevel server) {
                BlockPos found = server.findNearestMapStructure(TARGETS, player.blockPosition(), 100, false);
                if (found != null) {
                    stack.shrink(1);
                    SoulBead bead = new SoulBead(QuarkBlocks.SOUL_BEAD.get(), level);
                    bead.entityData.set(TARGET_X, found.getX());
                    bead.entityData.set(TARGET_Z, found.getZ());
                    Vec3 look = player.getLookAngle();
                    bead.setPos(player.getX() + look.x * 2, player.getY() + 0.25, player.getZ() + look.z * 2);
                    level.addFreshEntity(bead);
                    level.playSound(null, player.getX(), player.getY(), player.getZ(),
                            QuarkBlocks.SOUND_BY_NAME.get("item.soul_powder.spawn").get(), SoundSource.PLAYERS, 1F, 1F);
                }
            } else {
                player.swing(hand);
            }
            player.awardStat(Stats.ITEM_USED.get(this));
            return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
        }
    }
}
