package warpledge.quarkblocks;

import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.tags.BlockTags;
import net.minecraft.tags.TagKey;
import net.minecraft.world.DifficultyInstance;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.AgeableMob;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import net.minecraft.world.entity.MobSpawnType;
import net.minecraft.world.entity.SpawnGroupData;
import net.minecraft.world.entity.ai.attributes.AttributeSupplier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.ai.goal.BreedGoal;
import net.minecraft.world.entity.ai.goal.FollowParentGoal;
import net.minecraft.world.entity.ai.goal.LookAtPlayerGoal;
import net.minecraft.world.entity.ai.goal.RandomLookAroundGoal;
import net.minecraft.world.entity.ai.goal.RandomStrollGoal;
import net.minecraft.world.entity.ai.goal.TemptGoal;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.ServerLevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.RodBlock;
import net.minecraft.world.level.block.piston.PistonMovingBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.level.pathfinder.BlockPathTypes;
import net.minecraft.world.level.storage.loot.LootParams;
import net.minecraft.world.level.storage.loot.parameters.LootContextParams;
import net.minecraft.world.phys.AABB;
import net.minecraftforge.common.ToolActions;

/**
 * Quark's toretoise (Toretoise and ToretoiseModule, CC BY-NC-SA 3.0): a slow cave tortoise
 * with an ore on its back. Hit it with a pickaxe (or a pickarang, or an extending piston
 * with an end rod) for the ore's drops; feed it glow berries to tame it and, after a minute,
 * maybe regrow one. Hit it otherwise and it stomps everything within 3 blocks.
 */
public class Toretoise extends Animal implements Pickarang.PickarangTarget {
    private static final TagKey<Block> BREAKS_ORE = BlockTags.create(QuarkBlocks.rl("breaks_toretoise_ore"));
    private static final EntityDataAccessor<Integer> ORE = SynchedEntityData.defineId(Toretoise.class, EntityDataSerializers.INT);
    private static final int ORE_TYPES = 5;
    static final int ANGRY_TIME = 20;
    private static final int COOLDOWN = 20 * 60;
    private static final int REGROW_CHANCE = 3;
    private boolean tamed;
    private int eatCooldown;
    int angryTicks; // and rideTime: the model's stomp and riding animations read them
    int rideTime;
    private LivingEntity lastAggressor;
    private static final Ingredient FOOD = Ingredient.of(Items.GLOW_BERRIES);

    public Toretoise(EntityType<? extends Toretoise> type, Level level) {
        super(type, level);
        setMaxUpStep(1F);
        setPathfindingMalus(BlockPathTypes.WATER, 1F);
    }

    static AttributeSupplier.Builder attributes() {
        return Mob.createMobAttributes().add(Attributes.MAX_HEALTH, 60).add(Attributes.MOVEMENT_SPEED, 0.08)
                .add(Attributes.KNOCKBACK_RESISTANCE, 1);
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(ORE, 0);
    }

    @Override
    protected void registerGoals() {
        goalSelector.addGoal(0, new BreedGoal(this, 1.0));
        goalSelector.addGoal(1, new TemptGoal(this, 1.25, FOOD, false));
        goalSelector.addGoal(2, new FollowParentGoal(this, 1.25));
        goalSelector.addGoal(3, new RandomStrollGoal(this, 1.0));
        goalSelector.addGoal(4, new LookAtPlayerGoal(this, Player.class, 6F));
        goalSelector.addGoal(5, new RandomLookAroundGoal(this));
    }

    @Override
    public SpawnGroupData finalizeSpawn(ServerLevelAccessor level, DifficultyInstance difficulty, MobSpawnType reason,
            SpawnGroupData data, CompoundTag tag) {
        SpawnGroupData out = super.finalizeSpawn(level, difficulty, reason, data, tag);
        popOre(true);
        return out;
    }

    @Override
    public boolean canBreatheUnderwater() {
        return true;
    }

    @Override
    public boolean isPushedByFluid() {
        return false;
    }

    @Override
    protected int decreaseAirSupply(int air) {
        return air;
    }

    @Override
    public boolean canBreed() {
        return ore() == 0 && eatCooldown == 0;
    }

    @Override
    public SoundEvent getEatingSound(ItemStack stack) {
        return sound(eatCooldown == 0 ? "eat" : "eat_satiated");
    }

    @Override
    protected AABB makeBoundingBox() {
        AABB box = super.makeBoundingBox();
        return ore() == 0 ? box : box.setMaxY(box.maxY + 0.4);
    }

    @Override
    public void tick() {
        super.tick();
        rideTime = getVehicle() != null ? rideTime + 1 : 0;
        if (eatCooldown > 0) eatCooldown--;
        if (angryTicks > 0 && isAlive()) {
            angryTicks--;
            if (onGround()) stomp();
        }
        if (level() instanceof ServerLevel server && ore() != 0) pistonHits(server);
    }

    private void stomp() {
        int range = 3;
        double x = getX() + getBbWidth() / 2, y = getY(), z = getZ() + getBbWidth() / 2;
        if (level() instanceof ServerLevel server) {
            if (angryTicks == 3) {
                playSound(sound("angry"), 1F, 0.2F);
            } else if (angryTicks == 0) {
                server.sendParticles(ParticleTypes.CLOUD, x, y, z, 200, range, 0.5, range, 0);
                gameEvent(GameEvent.ENTITY_ROAR);
            }
        }
        if (angryTicks != 0) return;
        List<LivingEntity> hit = level().getEntitiesOfClass(LivingEntity.class,
                new AABB(x - range, y - 1, z - range, x + range, y + 1, z + range), e -> !(e instanceof Toretoise));
        LivingEntity aggressor = lastAggressor == null ? this : lastAggressor;
        for (LivingEntity e : hit) {
            e.hurt(damageSources().mobAttack(e == aggressor ? this : aggressor), 4 + level().getDifficulty().ordinal());
        }
    }

    /** An extending piston pushing an end rod (breaks_toretoise_ore) into it knocks the ore off. */
    private void pistonHits(ServerLevel server) {
        AABB box = getBoundingBox();
        BlockPos min = BlockPos.containing(Math.round(box.minX), Math.round(box.minY), Math.round(box.minZ));
        BlockPos max = BlockPos.containing(Math.round(box.maxX), Math.round(box.maxY), Math.round(box.maxZ));
        for (BlockPos p : BlockPos.betweenClosed(min, max)) {
            if (!level().getBlockState(p).is(Blocks.MOVING_PISTON)) continue;
            if (level().getBlockEntity(p) instanceof PistonMovingBlockEntity piston && piston.isExtending()) {
                BlockState moved = piston.getMovedState();
                if (moved.is(BREAKS_ORE) && (!moved.hasProperty(RodBlock.FACING)
                        || moved.getValue(RodBlock.FACING) == piston.getMovementDirection())) {
                    dropOre(new LootParams.Builder(server).withParameter(LootContextParams.TOOL, new ItemStack(Items.IRON_PICKAXE)));
                    return;
                }
            }
        }
    }

    @Override
    public boolean hurt(DamageSource source, float amount) {
        if (source.getDirectEntity() instanceof LivingEntity living) {
            ItemStack held = living.getMainHandItem();
            if (ore() != 0 && held.canPerformAction(ToolActions.PICKAXE_DIG)) {
                if (level() instanceof ServerLevel server) {
                    if (held.isDamageableItem() && living instanceof Player p) {
                        held.hurtAndBreak(1, p, e -> e.broadcastBreakEvent(InteractionHand.MAIN_HAND));
                    }
                    LootParams.Builder loot = new LootParams.Builder(server).withParameter(LootContextParams.TOOL, held);
                    if (living instanceof Player p) loot.withLuck(p.getLuck());
                    dropOre(loot);
                }
                return false;
            }
            if (angryTicks == 0) {
                angryTicks = ANGRY_TIME;
                lastAggressor = living;
            }
        }
        return super.hurt(source, amount);
    }

    /** A pickarang mines its ore like a pickaxe would. */
    @Override
    public boolean pickarangHit(Pickarang rang, ItemStack pick, Entity owner) {
        if (ore() == 0 || !(level() instanceof ServerLevel server)) return false;
        LootParams.Builder loot = new LootParams.Builder(server).withParameter(LootContextParams.TOOL, pick);
        if (owner instanceof Player p) loot.withLuck(p.getLuck());
        dropOre(loot);
        return true;
    }

    void dropOre(LootParams.Builder loot) {
        loot.withParameter(LootContextParams.ORIGIN, position());
        BlockState drop = switch (ore()) {
            case 1 -> Blocks.DEEPSLATE_COAL_ORE.defaultBlockState();
            case 2 -> Blocks.DEEPSLATE_IRON_ORE.defaultBlockState();
            case 3 -> Blocks.DEEPSLATE_REDSTONE_ORE.defaultBlockState();
            case 4 -> Blocks.DEEPSLATE_LAPIS_ORE.defaultBlockState();
            case 5 -> Blocks.DEEPSLATE_COPPER_ORE.defaultBlockState();
            default -> null;
        };
        if (drop != null) {
            playSound(sound("harvest"), 1F, 0.6F);
            gameEvent(GameEvent.ENTITY_INTERACT);
            for (ItemStack s : drop.getDrops(loot)) spawnAtLocation(s, 1.2F);
        }
        entityData.set(ORE, 0);
        setBoundingBox(makeBoundingBox());
    }

    @Override
    public void setInLove(Player player) {
        setInLoveTime(0);
    }

    @Override
    public void setInLoveTime(int ticks) {
        if (level().isClientSide) return;
        playSound(sound(eatCooldown == 0 ? "eat" : "eat_satiated"), 0.5F + 0.5F * level().random.nextInt(2),
                (level().random.nextFloat() - level().random.nextFloat()) * 0.2F + 1F);
        heal(8);
        if (!tamed) {
            tamed = true;
            if (level() instanceof ServerLevel server) server.sendParticles(ParticleTypes.HEART, getX(), getY(), getZ(), 20, 0.5, 0.5, 0.5, 0);
        } else if (eatCooldown == 0) {
            popOre(false);
        }
    }

    private void popOre(boolean natural) {
        if (ore() != 0 || !natural && level().random.nextInt(REGROW_CHANCE) != 0) return;
        entityData.set(ORE, random.nextInt(ORE_TYPES) + 1);
        setBoundingBox(makeBoundingBox());
        if (!natural) {
            eatCooldown = COOLDOWN;
            if (level() instanceof ServerLevel server) {
                server.sendParticles(ParticleTypes.CLOUD, getX(), getY() + 0.5, getZ(), 100, 0.6, 0.6, 0.6, 0);
                playSound(sound("regrow"), 10F, 0.7F);
            }
        }
    }

    @Override
    public boolean isFood(ItemStack stack) {
        return FOOD.test(stack);
    }

    @Override
    public boolean removeWhenFarAway(double distance) {
        return !tamed;
    }

    @Override
    protected void jumpFromGround() {}

    @Override
    public boolean causeFallDamage(float distance, float mult, DamageSource source) {
        return false;
    }

    @Override
    protected float getWaterSlowDown() {
        return 0.9F;
    }

    @Override
    public boolean canBeLeashed(Player player) {
        return false;
    }

    @Override
    public float getVoicePitch() {
        return (random.nextFloat() - random.nextFloat()) * 0.2F + 0.6F;
    }

    private SoundEvent sound(String name) {
        return QuarkBlocks.SOUND_BY_NAME.get("entity.toretoise." + name).get();
    }

    @Override
    protected SoundEvent getAmbientSound() {
        return sound("idle");
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return sound("hurt");
    }

    @Override
    protected SoundEvent getDeathSound() {
        return sound("die");
    }

    int ore() {
        return entityData.get(ORE);
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putBoolean("tamed", tamed);
        tag.putInt("oreType", ore());
        tag.putInt("eatCooldown", eatCooldown);
        tag.putInt("angeryTicks", angryTicks);
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        tamed = tag.getBoolean("tamed");
        entityData.set(ORE, tag.getInt("oreType"));
        eatCooldown = tag.getInt("eatCooldown");
        angryTicks = tag.getInt("angeryTicks");
    }

    @Override
    public AgeableMob getBreedOffspring(ServerLevel level, AgeableMob other) {
        Toretoise e = new Toretoise(QuarkBlocks.TORETOISE.get(), level);
        e.kill(); // toretoises don't have babies
        return e;
    }
}
