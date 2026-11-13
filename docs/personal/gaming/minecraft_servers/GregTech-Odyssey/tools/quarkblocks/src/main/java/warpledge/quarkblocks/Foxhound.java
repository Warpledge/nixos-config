package warpledge.quarkblocks;

import java.util.EnumSet;
import java.util.List;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.core.particles.SimpleParticleType;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.Difficulty;
import net.minecraft.world.DifficultyInstance;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.AgeableMob;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.MobSpawnType;
import net.minecraft.world.entity.Pose;
import net.minecraft.world.entity.SpawnGroupData;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.ai.goal.BegGoal;
import net.minecraft.world.entity.ai.goal.BreedGoal;
import net.minecraft.world.entity.ai.goal.FloatGoal;
import net.minecraft.world.entity.ai.goal.FollowOwnerGoal;
import net.minecraft.world.entity.ai.goal.Goal;
import net.minecraft.world.entity.ai.goal.LeapAtTargetGoal;
import net.minecraft.world.entity.ai.goal.LookAtPlayerGoal;
import net.minecraft.world.entity.ai.goal.MeleeAttackGoal;
import net.minecraft.world.entity.ai.goal.MoveToBlockGoal;
import net.minecraft.world.entity.ai.goal.RandomLookAroundGoal;
import net.minecraft.world.entity.ai.goal.SitWhenOrderedToGoal;
import net.minecraft.world.entity.ai.goal.WaterAvoidingRandomStrollGoal;
import net.minecraft.world.entity.ai.goal.target.HurtByTargetGoal;
import net.minecraft.world.entity.ai.goal.target.NonTameRandomTargetGoal;
import net.minecraft.world.entity.ai.goal.target.OwnerHurtTargetGoal;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.entity.animal.Rabbit;
import net.minecraft.world.entity.animal.Sheep;
import net.minecraft.world.entity.animal.Wolf;
import net.minecraft.world.entity.monster.Enemy;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.DyeColor;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.ServerLevelAccessor;
import net.minecraft.world.level.biome.Biomes;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.AbstractFurnaceBlockEntity;
import net.minecraft.world.level.block.entity.FurnaceBlockEntity;
import net.minecraft.world.level.pathfinder.BlockPathTypes;
import net.minecraft.world.phys.AABB;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's foxhound (Foxhound, FoxhoundModule, SleepGoal, FindPlaceToSleepGoal, CC BY-NC-SA
 * 3.0): a fire hound of the nether that burns what it bites. Hostile until tamed with
 * coal (5% a try, needs fire resistance); a tame one naps on furnaces and other lit blocks
 * and speeds up the furnace it sits on. Blue ones come from soul sand valleys. Quark's
 * tiny potato trick and pet-me nudges are left out.
 */
public class Foxhound extends Wolf implements Enemy {
    private static final EntityDataAccessor<Boolean> BLUE = SynchedEntityData.defineId(Foxhound.class, EntityDataSerializers.BOOLEAN);
    static final TagKey<Block> SPAWNABLE = BlockTags.create(QuarkBlocks.rl("foxhound_spawnable"));
    private static final double TAME_CHANCE = 0.05;
    private Sleep sleep;

    public Foxhound(EntityType<? extends Foxhound> type, Level level) {
        super(type, level);
        setPathfindingMalus(BlockPathTypes.WATER, -1F);
        setPathfindingMalus(BlockPathTypes.LAVA, 1F);
        setPathfindingMalus(BlockPathTypes.DANGER_FIRE, 1F);
        setPathfindingMalus(BlockPathTypes.DAMAGE_FIRE, 1F);
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        setCollarColor(DyeColor.ORANGE);
        entityData.define(BLUE, false);
    }

    @Override
    public int getMaxSpawnClusterSize() {
        return 4;
    }

    @Override
    public boolean requiresCustomPersistence() {
        return isTame();
    }

    @Override
    public boolean removeWhenFarAway(double distance) {
        return !isTame();
    }

    @Override
    public SpawnGroupData finalizeSpawn(ServerLevelAccessor level, DifficultyInstance difficulty, MobSpawnType reason,
            SpawnGroupData data, CompoundTag tag) {
        if (level.getBiome(blockPosition()).is(Biomes.SOUL_SAND_VALLEY)) setBlue(true);
        return super.finalizeSpawn(level, difficulty, reason, data, tag);
    }

    @Override
    public void tick() {
        super.tick();
        if (isSleeping() ? getPose() != Pose.SLEEPING : getPose() == Pose.SLEEPING) {
            setPose(isSleeping() ? Pose.SLEEPING : Pose.STANDING);
        }
        Level level = level();
        if (!level.isClientSide && level.getDifficulty() == Difficulty.PEACEFUL && !isTame()) {
            discard();
            return;
        }
        if (isSleeping()) {
            getSleepingPos().ifPresent(p -> {
                if (distanceToSqr(p.getX() + 0.5, p.getY() + 0.5, p.getZ() + 0.5) > 1) stopSleeping();
            });
            AABB box = getBoundingBox();
            if (box.getYsize() < 0.21) {
                setBoundingBox(new AABB(box.minX - 0.2, box.minY, box.minZ - 0.2, box.maxX + 0.2, box.maxY + 0.5, box.maxZ + 0.2));
            }
        }
        if (level.isClientSide && (!isBaby() ^ random.nextBoolean())) {
            SimpleParticleType p = isSleeping() ? ParticleTypes.SMOKE : isBlue() ? ParticleTypes.SOUL_FIRE_FLAME : ParticleTypes.FLAME;
            level.addParticle(p, getRandomX(0.5), getRandomY(), getRandomZ(0.5), 0, 0, 0);
        }
        if (isTame() && level.getBlockEntity(blockPosition().below()) instanceof AbstractFurnaceBlockEntity furnace) {
            int cook = furnace.cookingProgress;
            if (cook > 0 && cook % 3 == 0) {
                List<Foxhound> here = level.getEntitiesOfClass(Foxhound.class, new AABB(blockPosition()), f -> f.isTame());
                if (!here.isEmpty() && here.get(0) == this) {
                    furnace.cookingProgress = cook == 3 ? 5 : Math.min(furnace.cookingTotalTime - 1, cook + 1);
                }
            }
        }
    }

    @Override
    public boolean isInWaterOrRain() {
        return false;
    }

    @Override
    protected ResourceLocation getDefaultLootTable() {
        return QuarkBlocks.rl("entities/foxhound");
    }

    @Override
    protected void registerGoals() {
        sleep = new Sleep();
        goalSelector.addGoal(1, new FloatGoal(this));
        goalSelector.addGoal(2, sleep);
        goalSelector.addGoal(3, new SitWhenOrderedToGoal(this));
        goalSelector.addGoal(4, new LeapAtTargetGoal(this, 0.4F));
        goalSelector.addGoal(5, new MeleeAttackGoal(this, 1.0, true));
        goalSelector.addGoal(6, new FollowOwnerGoal(this, 1.0, 10F, 2F, false));
        goalSelector.addGoal(7, new BreedGoal(this, 1.0));
        goalSelector.addGoal(8, new FindBed(0));
        goalSelector.addGoal(9, new FindBed(1));
        goalSelector.addGoal(10, new FindBed(2));
        goalSelector.addGoal(11, new WaterAvoidingRandomStrollGoal(this, 1.0));
        goalSelector.addGoal(12, new BegGoal(this, 8F));
        goalSelector.addGoal(13, new LookAtPlayerGoal(this, Player.class, 8F));
        goalSelector.addGoal(14, new RandomLookAroundGoal(this));
        targetSelector.addGoal(1, new HurtByTargetGoal(this));
        targetSelector.addGoal(2, new OwnerHurtTargetGoal(this));
        targetSelector.addGoal(3, new HurtByTargetGoal(this).setAlertOthers());
        targetSelector.addGoal(4, new NonTameRandomTargetGoal<>(this, Animal.class, false,
                t -> t instanceof Sheep || t instanceof Rabbit));
        targetSelector.addGoal(4, new NonTameRandomTargetGoal<>(this, Player.class, false, t -> !isTame()));
    }

    @Override
    public int getRemainingPersistentAngerTime() {
        return !isTame() && level().getDifficulty() != Difficulty.PEACEFUL ? 0 : super.getRemainingPersistentAngerTime();
    }

    @Override
    public boolean doHurtTarget(Entity target) {
        if (target.getType().fireImmune()) return !(target instanceof Player) && super.doHurtTarget(target);
        boolean hit = target.hurt(level().damageSources().onFire(), (int) getAttributeValue(Attributes.ATTACK_DAMAGE));
        if (hit) {
            target.setSecondsOnFire(5);
            doEnchantDamageEffects(this, target);
        }
        return hit;
    }

    @Override
    public boolean hurt(DamageSource source, float amount) {
        wake();
        return super.hurt(source, amount);
    }

    @Override
    public InteractionResult mobInteract(Player player, InteractionHand hand) {
        ItemStack stack = player.getItemInHand(hand);
        if (stack.is(Items.BONE) && !isTame()) return InteractionResult.PASS;
        Level level = level();
        if (!isTame() && stack.is(Items.COAL) && (level.getDifficulty() == Difficulty.PEACEFUL
                || player.getAbilities().invulnerable || player.getEffect(MobEffects.FIRE_RESISTANCE) != null)
                && !level.isClientSide) {
            if (random.nextDouble() < TAME_CHANCE) {
                tame(player);
                navigation.stop();
                setTarget(null);
                setOrderedToSit(true);
                setHealth(20F);
                level.broadcastEntityEvent(this, (byte) 7);
            } else {
                level.broadcastEntityEvent(this, (byte) 6);
            }
            if (!player.getAbilities().instabuild) stack.shrink(1);
            return InteractionResult.sidedSuccess(level.isClientSide);
        }
        InteractionResult r = super.mobInteract(player, hand);
        if (r.consumesAction() && !level.isClientSide) wake();
        return r;
    }

    @Override
    public boolean canMate(Animal other) {
        return super.canMate(other) && other instanceof Foxhound;
    }

    @Override
    public Wolf getBreedOffspring(ServerLevel level, AgeableMob other) {
        Foxhound kid = new Foxhound(QuarkBlocks.FOXHOUND.get(), level);
        UUID owner = getOwnerUUID();
        if (owner != null) {
            kid.setOwnerUUID(owner);
            kid.setTame(true);
        }
        if (isBlue()) kid.setBlue(true);
        return kid;
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putBoolean("IsSlep", isSleeping());
        tag.putBoolean("IsBlue", isBlue());
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        setInSittingPose(tag.getBoolean("IsSlep"));
        setBlue(tag.getBoolean("IsBlue"));
    }

    private SoundEvent sound(String name) {
        return QuarkBlocks.SOUND_BY_NAME.get("entity.foxhound." + name).get();
    }

    @Override
    protected SoundEvent getAmbientSound() {
        if (isSleeping()) return null;
        if (isAngry()) return sound("growl");
        if (random.nextInt(3) == 0) return isTame() && getHealth() < 10F ? sound("whine") : sound("pant");
        return sound("ambient");
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return sound("hurt");
    }

    @Override
    protected SoundEvent getDeathSound() {
        return sound("death");
    }

    boolean isBlue() {
        return entityData.get(BLUE);
    }

    void setBlue(boolean blue) {
        entityData.set(BLUE, blue);
    }

    @Override
    public float getWalkTargetValue(BlockPos pos, LevelReader level) {
        return level.getBlockState(pos.below()).is(SPAWNABLE) ? 10F : level.getRawBrightness(pos, 0) - 0.5F;
    }

    private void wake() {
        if (sleep != null) {
            setInSittingPose(false);
            sleep.setSleeping(false);
        }
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }

    /** SleepGoal: a tame foxhound naps once it has found a bed. */
    private final class Sleep extends Goal {
        private boolean sleeping;
        private boolean wasSitting;

        Sleep() {
            setFlags(EnumSet.of(Flag.MOVE, Flag.JUMP, Flag.LOOK, Flag.TARGET));
        }

        @Override
        public boolean canUse() {
            if (!isTame() || isInWater() || !onGround()) return false;
            LivingEntity owner = getOwner();
            return owner == null || (distanceToSqr(owner) >= 144 || owner.getLastHurtByMob() == null) && sleeping;
        }

        @Override
        public boolean canContinueToUse() {
            return getPose() == Pose.SLEEPING;
        }

        @Override
        public void start() {
            getNavigation().stop();
            wasSitting = isOrderedToSit();
            setOrderedToSit(true);
            setInSittingPose(true);
        }

        @Override
        public void stop() {
            setOrderedToSit(wasSitting);
            setInSittingPose(false);
            clearSleepingPos();
        }

        void setSleeping(boolean s) {
            sleeping = s;
            setPose(Pose.STANDING);
        }
    }

    /** FindPlaceToSleepGoal: 0 a lit furnace, 1 an unlit one, 2 any glowing block. */
    private final class FindBed extends MoveToBlockGoal {
        private final int target;
        private boolean slept;

        FindBed(int target) {
            super(Foxhound.this, 0.8, 8);
            this.target = target;
        }

        private void sit(boolean s) {
            setOrderedToSit(s);
            sleep.setSleeping(s);
            setInSittingPose(s);
        }

        @Override
        public boolean canUse() {
            return isTame() && !isOrderedToSit() && super.canUse();
        }

        @Override
        public boolean canContinueToUse() {
            return (!slept || isSleeping()) && super.canContinueToUse();
        }

        @Override
        public void start() {
            super.start();
            slept = false;
            sit(false);
        }

        @Override
        public void stop() {
            super.stop();
            slept = false;
            sit(false);
        }

        @Override
        public void tick() {
            super.tick();
            var m = getDeltaMovement();
            if (!isReachedTarget() || m.x > 0 || m.z > 0) {
                sit(false);
            } else if (!isOrderedToSit()) {
                sit(true);
                startSleeping(blockPos.above());
                slept = true;
            }
        }

        @Override
        protected boolean isValidTarget(LevelReader level, BlockPos pos) {
            if (!level.isEmptyBlock(pos.above())) return false;
            int light = level.getBlockState(pos).getLightEmission(level, pos);
            boolean furnace = level.getBlockEntity(pos) instanceof FurnaceBlockEntity;
            return switch (target) {
                case 0 -> furnace && light > 2;
                case 1 -> furnace && light <= 2;
                default -> light > 2;
            };
        }
    }
}
