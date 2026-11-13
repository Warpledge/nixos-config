package warpledge.quarkblocks;

import net.minecraft.core.particles.ItemParticleOption;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.animal.Parrot;
import net.minecraft.world.entity.projectile.ThrowableItemProjectile;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.HitResult;

/** A thrown parrot egg (Quark's ParrotEgg, CC BY-NC-SA 3.0): hatches a baby parrot. */
public class ParrotEgg extends ThrowableItemProjectile {
    private static final EntityDataAccessor<Integer> VARIANT =
            SynchedEntityData.defineId(ParrotEgg.class, EntityDataSerializers.INT);

    public ParrotEgg(EntityType<ParrotEgg> type, Level level) {
        super(type, level);
    }

    ParrotEgg(Level level, LivingEntity owner) {
        super(QuarkBlocks.PARROT_EGG.get(), owner, level);
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(VARIANT, 0);
    }

    Parrot.Variant variant() {
        return Parrot.Variant.byId(entityData.get(VARIANT));
    }

    void setVariant(Parrot.Variant v) {
        entityData.set(VARIANT, v.getId());
    }

    @Override
    protected Item getDefaultItem() {
        var item = QuarkBlocks.ALL_ITEMS.get("egg_parrot_" + variant().getSerializedName());
        return item == null ? Items.EGG : item.get();
    }

    @Override
    public void handleEntityEvent(byte id) {
        if (id != 3) return;
        for (int i = 0; i < 8; i++) {
            level().addParticle(new ItemParticleOption(ParticleTypes.ITEM, getItem()), getX(), getY(), getZ(),
                    (random.nextFloat() - 0.5) * 0.08, (random.nextFloat() - 0.5) * 0.08, (random.nextFloat() - 0.5) * 0.08);
        }
    }

    @Override
    protected void onHitEntity(EntityHitResult hit) {
        super.onHitEntity(hit);
        hit.getEntity().hurt(damageSources().thrown(this, getOwner()), 0F);
    }

    @Override
    protected void onHit(HitResult hit) {
        super.onHit(hit);
        if (level().isClientSide) return;
        Parrot parrot = EntityType.PARROT.create(level());
        if (parrot != null) {
            parrot.setVariant(variant());
            parrot.setAge(-24000);
            parrot.moveTo(getX(), getY(), getZ(), getYRot(), 0F);
            level().addFreshEntity(parrot);
        }
        level().broadcastEntityEvent(this, (byte) 3);
        discard();
    }
}
