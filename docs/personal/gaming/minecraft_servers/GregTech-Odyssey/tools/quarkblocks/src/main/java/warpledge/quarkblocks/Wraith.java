package warpledge.quarkblocks;

import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.DifficultyInstance;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.MobSpawnType;
import net.minecraft.world.entity.SpawnGroupData;
import net.minecraft.world.entity.ai.attributes.AttributeSupplier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.monster.Monster;
import net.minecraft.world.entity.monster.Zombie;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.ServerLevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

/**
 * Quark's wraith (Wraith and WraithModule, CC BY-NC-SA 3.0): a soul-valley ghost that
 * borrows another mob's voice, ignores you until you hit it, then lunges back after each
 * blow and slows you. Drops soul beads (loot table entities/wraith).
 */
public class Wraith extends Zombie {
    private static final EntityDataAccessor<String> IDLE = SynchedEntityData.defineId(Wraith.class, EntityDataSerializers.STRING);
    private static final EntityDataAccessor<String> HURT = SynchedEntityData.defineId(Wraith.class, EntityDataSerializers.STRING);
    private static final EntityDataAccessor<String> DEATH = SynchedEntityData.defineId(Wraith.class, EntityDataSerializers.STRING);
    static final TagKey<Block> SPAWNABLE = BlockTags.create(QuarkBlocks.rl("wraith_spawnable"));
    // Quark's default voice list, less its own stoneling and frog sounds.
    private static final List<String> VOICES = List.of(
            "entity.sheep.ambient|entity.sheep.hurt|entity.sheep.death",
            "entity.cow.ambient|entity.cow.hurt|entity.cow.death",
            "entity.pig.ambient|entity.pig.hurt|entity.pig.death",
            "entity.chicken.ambient|entity.chicken.hurt|entity.chicken.death",
            "entity.horse.ambient|entity.horse.hurt|entity.horse.death",
            "entity.cat.ambient|entity.cat.hurt|entity.cat.death",
            "entity.wolf.ambient|entity.wolf.hurt|entity.wolf.death",
            "entity.villager.ambient|entity.villager.hurt|entity.villager.death",
            "entity.polar_bear.ambient|entity.polar_bear.hurt|entity.polar_bear.death",
            "entity.zombie.ambient|entity.zombie.hurt|entity.zombie.death",
            "entity.skeleton.ambient|entity.skeleton.hurt|entity.skeleton.death",
            "entity.spider.ambient|entity.spider.hurt|entity.spider.death",
            "entity.enderman.ambient|entity.enderman.hurt|entity.enderman.death",
            "entity.witch.ambient|entity.witch.hurt|entity.witch.death",
            "entity.blaze.ambient|entity.blaze.hurt|entity.blaze.death",
            "entity.llama.ambient|entity.llama.hurt|entity.llama.death");
    private boolean aggroed;

    public Wraith(EntityType<? extends Wraith> type, Level level) {
        super(type, level);
    }

    static AttributeSupplier.Builder attributes() {
        return Monster.createMonsterAttributes().add(Attributes.MAX_HEALTH, 20).add(Attributes.FOLLOW_RANGE, 35)
                .add(Attributes.MOVEMENT_SPEED, 0.28).add(Attributes.ATTACK_DAMAGE, 3)
                .add(Attributes.KNOCKBACK_RESISTANCE, 1).add(Attributes.ARMOR, 0)
                .add(Attributes.SPAWN_REINFORCEMENTS_CHANCE, 0);
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(IDLE, "");
        entityData.define(HURT, "");
        entityData.define(DEATH, "");
    }

    private SoundEvent sound(EntityDataAccessor<String> key) {
        ResourceLocation loc = ResourceLocation.tryParse(entityData.get(key));
        return loc == null ? null : BuiltInRegistries.SOUND_EVENT.get(loc);
    }

    @Override
    protected SoundEvent getAmbientSound() {
        return sound(IDLE);
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return sound(HURT);
    }

    @Override
    protected SoundEvent getDeathSound() {
        return sound(DEATH);
    }

    @Override
    public float getVoicePitch() {
        return random.nextFloat() * 0.1F + 0.75F;
    }

    @Override
    public void tick() {
        super.tick();
        AABB box = getBoundingBox();
        double x = box.minX + Math.random() * (box.maxX - box.minX + 0.4) - 0.2;
        double y = box.minY + Math.random() * (box.maxY - box.minY + 0.4) - 0.2;
        double z = box.minZ + Math.random() * (box.maxZ - box.minZ + 0.4) - 0.2;
        level().addParticle(ParticleTypes.MYCELIUM, x, y, z, 0, 0, 0);
        if (Math.random() < 0.1) level().addParticle(ParticleTypes.SOUL, x, box.minY + 0.1, z, 0, 0, 0);
    }

    @Override
    public boolean doHurtTarget(Entity target) {
        boolean did = super.doHurtTarget(target);
        if (did) {
            if (target instanceof LivingEntity l) l.addEffect(new MobEffectInstance(MobEffects.MOVEMENT_SLOWDOWN, 60, 1));
            setDeltaMovement(new Vec3(getX() - target.getX(), 0, getZ() - target.getZ()).normalize().add(0, 0.5, 0)
                    .normalize().scale(0.85));
        }
        return did;
    }

    @Override
    public SpawnGroupData finalizeSpawn(ServerLevelAccessor level, DifficultyInstance difficulty, MobSpawnType reason,
            SpawnGroupData data, CompoundTag tag) {
        String[] voice = VOICES.get(random.nextInt(VOICES.size())).split("\\|");
        entityData.set(IDLE, voice[0]);
        entityData.set(HURT, voice[1]);
        entityData.set(DEATH, voice[2]);
        return super.finalizeSpawn(level, difficulty, reason, data, tag);
    }

    @Override
    protected boolean isSunSensitive() {
        return false;
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putString("IdleSound", entityData.get(IDLE));
        tag.putString("HurtSound", entityData.get(HURT));
        tag.putString("DeathSound", entityData.get(DEATH));
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        entityData.set(IDLE, tag.getString("IdleSound"));
        entityData.set(HURT, tag.getString("HurtSound"));
        entityData.set(DEATH, tag.getString("DeathSound"));
    }

    @Override
    protected ResourceLocation getDefaultLootTable() {
        return QuarkBlocks.rl("entities/wraith");
    }

    @Override
    public void setBaby(boolean baby) {}

    @Override
    public boolean isBaby() {
        return false;
    }

    @Override
    public float getWalkTargetValue(BlockPos pos, LevelReader level) {
        return level.getBlockState(pos).is(SPAWNABLE) ? 1F : 0F;
    }

    @Override
    public boolean hurt(DamageSource source, float amount) {
        if (!super.hurt(source, amount)) return false;
        if (source.getDirectEntity() instanceof Player) aggroed = true;
        return level() instanceof ServerLevel;
    }

    @Override
    public void setTarget(LivingEntity target) {
        if (aggroed) super.setTarget(target);
    }

    @Override
    protected void handleAttributes(float difficulty) {}

    @Override
    protected boolean convertsInWater() {
        return false;
    }
}
