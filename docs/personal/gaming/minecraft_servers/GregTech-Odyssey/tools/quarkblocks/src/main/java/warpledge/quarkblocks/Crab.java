package warpledge.quarkblocks;

import java.util.EnumSet;
import java.util.function.BiConsumer;
import net.minecraft.core.BlockPos;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.ItemTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.damagesource.DamageSources;
import net.minecraft.world.damagesource.DamageTypes;
import net.minecraft.world.entity.AgeableMob;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityDimensions;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LightningBolt;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import net.minecraft.world.entity.MobType;
import net.minecraft.world.entity.Pose;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.AttributeSupplier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.ai.goal.BreedGoal;
import net.minecraft.world.entity.ai.goal.FollowParentGoal;
import net.minecraft.world.entity.ai.goal.Goal;
import net.minecraft.world.entity.ai.goal.LookAtPlayerGoal;
import net.minecraft.world.entity.ai.goal.PanicGoal;
import net.minecraft.world.entity.ai.goal.RandomLookAroundGoal;
import net.minecraft.world.entity.ai.goal.TemptGoal;
import net.minecraft.world.entity.ai.goal.WaterAvoidingRandomStrollGoal;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.entity.animal.Bucketable;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LevelReader;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.LevelEvent;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.DynamicGameEventListener;
import net.minecraft.world.level.gameevent.EntityPositionSource;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.level.gameevent.GameEventListener;
import net.minecraft.world.level.gameevent.PositionSource;
import net.minecraft.world.level.pathfinder.BlockPathTypes;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.common.ForgeMod;
import net.minecraftforge.entity.IEntityAdditionalSpawnData;
import net.minecraftforge.fluids.FluidType;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's crab (Crab and CrabsModule, CC BY-NC-SA 3.0): a beach animal in three colours,
 * some mouldy; it pricks what bumps it, dances to a jukebox, grows with each lightning
 * strike (and big ones can be ridden), and fits in a bucket. Drops crab legs and shells.
 */
public class Crab extends Animal implements IEntityAdditionalSpawnData, Bucketable {
    static final int COLORS = 3;
    static final TagKey<Block> SPAWNABLE = BlockTags.create(QuarkBlocks.rl("crab_spawnable"));
    private static final EntityDataAccessor<Float> SIZE = SynchedEntityData.defineId(Crab.class, EntityDataSerializers.FLOAT);
    private static final EntityDataAccessor<Integer> VARIANT = SynchedEntityData.defineId(Crab.class, EntityDataSerializers.INT);
    private static final EntityDataAccessor<Boolean> RAVING = SynchedEntityData.defineId(Crab.class, EntityDataSerializers.BOOLEAN);
    private static final EntityDataAccessor<Boolean> FROM_BUCKET = SynchedEntityData.defineId(Crab.class,
            EntityDataSerializers.BOOLEAN);
    private int lightningCooldown;
    private Ingredient tempt;
    private boolean noSpike;
    private BlockPos jukebox;
    private final DynamicGameEventListener<Listener> listener;

    public Crab(EntityType<? extends Crab> type, Level level) {
        super(type, level);
        setPathfindingMalus(BlockPathTypes.LAVA, -1F);
        PositionSource source = new EntityPositionSource(this, getEyeHeight());
        listener = new DynamicGameEventListener<>(new Listener(source, GameEvent.JUKEBOX_PLAY.getNotificationRadius()));
    }

    static AttributeSupplier.Builder attributes() {
        return Mob.createMobAttributes().add(Attributes.MAX_HEALTH, 20).add(Attributes.MOVEMENT_SPEED, 0.25)
                .add(Attributes.ARMOR, 3).add(Attributes.ARMOR_TOUGHNESS, 2).add(Attributes.KNOCKBACK_RESISTANCE, 0.5);
    }

    @Override
    public boolean fromBucket() {
        return entityData.get(FROM_BUCKET);
    }

    @Override
    public void setFromBucket(boolean b) {
        entityData.set(FROM_BUCKET, b);
    }

    @Override
    @SuppressWarnings("deprecation")
    public void saveToBucketTag(ItemStack stack) {
        Bucketable.saveDefaultDataToBucketTag(this, stack);
        if (noSpike) stack.getOrCreateTag().putBoolean("NoSpike", true);
        stack.getOrCreateTag().putInt("Variant", variant());
    }

    @Override
    @SuppressWarnings("deprecation")
    public void loadFromBucketTag(CompoundTag tag) {
        Bucketable.loadDefaultDataFromBucketTag(this, tag);
        if (tag.contains("NoSpike")) noSpike = tag.getBoolean("NoSpike");
        entityData.set(VARIANT, tag.getInt("Variant"));
    }

    @Override
    public ItemStack getBucketItemStack() {
        var bucket = QuarkBlocks.ALL_ITEMS.get("crab_bucket");
        return bucket == null ? ItemStack.EMPTY : new ItemStack(bucket.get());
    }

    @Override
    public SoundEvent getPickupSound() {
        return QuarkBlocks.SOUND_BY_NAME.get("item.bucket.fill_crab").get();
    }

    @Override
    public boolean requiresCustomPersistence() {
        return super.requiresCustomPersistence() || fromBucket();
    }

    @Override
    public void updateDynamicGameEventListener(BiConsumer<DynamicGameEventListener<?>, ServerLevel> acceptor) {
        if (level() instanceof ServerLevel server) acceptor.accept(listener, server);
    }

    @Override
    public float getWalkTargetValue(BlockPos pos, LevelReader level) {
        return level.getBlockState(pos.below()).is(SPAWNABLE) ? 10F : level.getRawBrightness(pos, 0) - 0.5F;
    }

    @Override
    public boolean canBreatheUnderwater() {
        return true;
    }

    @Override
    public MobType getMobType() {
        return MobType.ARTHROPOD;
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(SIZE, 1F);
        entityData.define(VARIANT, -1);
        entityData.define(RAVING, false);
        entityData.define(FROM_BUCKET, false);
    }

    @Override
    public InteractionResult mobInteract(Player player, InteractionHand hand) {
        if (size() >= 2) {
            if (!isFood(player.getItemInHand(hand)) && !isVehicle() && !player.isSecondaryUseActive()) {
                if (!level().isClientSide) player.startRiding(this);
                return InteractionResult.sidedSuccess(level().isClientSide);
            }
        } else if (QuarkItems.has("crab_bucket")) {
            var r = Bucketable.bucketMobPickup(player, hand, this);
            if (r.isPresent()) return r.get();
        }
        return super.mobInteract(player, hand);
    }

    @Override
    public double getPassengersRidingOffset() {
        return super.getPassengersRidingOffset() / 0.75 * 0.9;
    }

    @Override
    protected SoundEvent getAmbientSound() {
        return QuarkBlocks.SOUND_BY_NAME.get("entity.crab.idle").get();
    }

    @Override
    protected SoundEvent getDeathSound() {
        return QuarkBlocks.SOUND_BY_NAME.get("entity.crab.die").get();
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return QuarkBlocks.SOUND_BY_NAME.get("entity.crab.hurt").get();
    }

    @Override
    protected float getStandingEyeHeight(Pose pose, EntityDimensions size) {
        return 0.2F * size.height;
    }

    float size() {
        return entityData.get(SIZE);
    }

    @Override
    protected void registerGoals() {
        goalSelector.addGoal(1, new PanicGoal(this, 1.25));
        goalSelector.addGoal(2, new Goal() {
            {
                setFlags(EnumSet.of(Flag.MOVE, Flag.JUMP));
            }

            @Override
            public boolean canUse() {
                return raving();
            }

            @Override
            public void start() {
                getNavigation().stop();
            }
        });
        goalSelector.addGoal(3, new BreedGoal(this, 1.0));
        goalSelector.addGoal(4, new TemptGoal(this, 1.2, temptItems(), false));
        goalSelector.addGoal(5, new FollowParentGoal(this, 1.1));
        goalSelector.addGoal(6, new WaterAvoidingRandomStrollGoal(this, 1.0));
        goalSelector.addGoal(7, new LookAtPlayerGoal(this, Player.class, 6F));
        goalSelector.addGoal(8, new RandomLookAroundGoal(this));
    }

    @Override
    public void tick() {
        super.tick();
        if (!level().isClientSide && entityData.get(VARIANT) == -1) {
            int v = random.nextBoolean() ? random.nextInt(COLORS - 1) + 1 : 0;
            if (random.nextInt(3) == 0) v += COLORS; // mould
            entityData.set(VARIANT, v);
        }
        if (lightningCooldown > 0) {
            lightningCooldown--;
            clearFire();
        }
        if (raving() && level().isClientSide && tickCount % 10 == 0) {
            BlockPos below = blockPosition().below();
            BlockState s = level().getBlockState(below);
            if (s.is(BlockTags.SAND)) level().levelEvent(LevelEvent.PARTICLES_DESTROY_BLOCK, below, Block.getId(s));
        }
        if (raving() && !level().isClientSide && tickCount % 20 == 0 && (jukebox == null
                || !jukebox.closerToCenterThan(position(), GameEvent.JUKEBOX_PLAY.getNotificationRadius())
                || !level().getBlockState(jukebox).is(Blocks.JUKEBOX))) {
            entityData.set(RAVING, false);
            jukebox = null;
        }
    }

    @Override
    public float getStepHeight() {
        float base = wasTouchingWater ? 1F : 0.6F;
        var attr = getAttribute(ForgeMod.STEP_HEIGHT_ADDITION.get());
        return attr == null ? base : (float) Math.max(0, base + attr.getValue());
    }

    @Override
    public EntityDimensions getDimensions(Pose pose) {
        return super.getDimensions(pose).scale(size());
    }

    @Override
    public boolean isPushedByFluid(FluidType type) {
        return false;
    }

    @Override
    protected int decreaseAirSupply(int air) {
        return air;
    }

    @Override
    public boolean isInvulnerableTo(DamageSource source) {
        DamageSources s = level().damageSources();
        return super.isInvulnerableTo(source) || source == s.cactus() || source == s.sweetBerryBush()
                || source == s.lightningBolt() || size() > 1 && source.is(DamageTypes.IN_FIRE)
                || source.is(DamageTypes.ON_FIRE);
    }

    @Override
    public boolean fireImmune() {
        return super.fireImmune() || size() > 1;
    }

    @Override
    public void thunderHit(ServerLevel level, LightningBolt bolt) {
        if (lightningCooldown > 0 || size() > 15) return;
        var hp = getAttribute(Attributes.MAX_HEALTH);
        if (hp != null) hp.addPermanentModifier(new AttributeModifier("Lightning Bonus", 0.5, AttributeModifier.Operation.ADDITION));
        var speed = getAttribute(Attributes.MOVEMENT_SPEED);
        if (speed != null) speed.addPermanentModifier(new AttributeModifier("Lightning Debuff", -0.05, AttributeModifier.Operation.ADDITION));
        var armor = getAttribute(Attributes.ARMOR);
        if (armor != null) armor.addPermanentModifier(new AttributeModifier("Lightning Bonus", 0.125, AttributeModifier.Operation.ADDITION));
        entityData.set(SIZE, Math.min(size() + 1, 16));
        refreshDimensions();
        lightningCooldown = 150;
    }

    @Override
    public void push(Entity e) {
        if (size() <= 1) super.push(e);
    }

    @Override
    protected void doPush(Entity e) {
        super.doPush(e);
        if (level().getDifficulty() != net.minecraft.world.Difficulty.PEACEFUL && !noSpike && !hasPassenger(e)
                && e instanceof LivingEntity && !(e instanceof Crab)) {
            e.hurt(level().damageSources().cactus(), 1F);
        }
    }

    @Override
    public boolean isFood(ItemStack stack) {
        return !stack.isEmpty() && temptItems().test(stack);
    }

    private Ingredient temptItems() {
        if (tempt == null) tempt = Ingredient.of(ItemTags.create(QuarkBlocks.rl("crab_tempt_items")));
        return tempt;
    }

    @Override
    public AgeableMob getBreedOffspring(ServerLevel level, AgeableMob other) {
        return new Crab(QuarkBlocks.CRAB.get(), level);
    }

    @Override
    protected ResourceLocation getDefaultLootTable() {
        return QuarkBlocks.rl("entities/crab");
    }

    int variant() {
        return Math.max(0, entityData.get(VARIANT));
    }

    boolean raving() {
        return entityData.get(RAVING);
    }

    @Override
    public void onSyncedDataUpdated(EntityDataAccessor<?> key) {
        if (key.equals(SIZE)) refreshDimensions();
        super.onSyncedDataUpdated(key);
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }

    @Override
    public void writeSpawnData(FriendlyByteBuf buf) {
        buf.writeFloat(size());
    }

    @Override
    public void readSpawnData(FriendlyByteBuf buf) {
        entityData.set(SIZE, buf.readFloat());
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        lightningCooldown = tag.getInt("LightningCooldown");
        noSpike = tag.getBoolean("NoSpike");
        if (tag.contains("EnemyCrabRating")) entityData.set(SIZE, tag.getFloat("EnemyCrabRating"));
        if (tag.contains("Variant")) entityData.set(VARIANT, tag.getInt("Variant"));
        setFromBucket(tag.getBoolean("FromBucket"));
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putFloat("EnemyCrabRating", size());
        tag.putInt("LightningCooldown", lightningCooldown);
        tag.putInt("Variant", entityData.get(VARIANT));
        tag.putBoolean("NoSpike", noSpike);
        tag.putBoolean("FromBucket", fromBucket());
    }

    /** Hears jukeboxes start and stop. */
    private final class Listener implements GameEventListener {
        private final PositionSource source;
        private final int radius;

        Listener(PositionSource source, int radius) {
            this.source = source;
            this.radius = radius;
        }

        @Override
        public PositionSource getListenerSource() {
            return source;
        }

        @Override
        public int getListenerRadius() {
            return radius;
        }

        @Override
        public boolean handleGameEvent(ServerLevel level, GameEvent event, GameEvent.Context ctx, Vec3 at) {
            BlockPos pos = BlockPos.containing(at);
            if (event == GameEvent.JUKEBOX_PLAY) {
                if (!raving()) {
                    jukebox = pos;
                    entityData.set(RAVING, true);
                }
                return true;
            }
            if (event == GameEvent.JUKEBOX_STOP_PLAY) {
                if (pos.equals(jukebox) || jukebox == null) {
                    jukebox = null;
                    entityData.set(RAVING, false);
                }
                return true;
            }
            return false;
        }
    }
}
