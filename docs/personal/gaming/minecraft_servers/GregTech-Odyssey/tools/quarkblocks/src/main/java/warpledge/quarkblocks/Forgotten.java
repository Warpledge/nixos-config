package warpledge.quarkblocks;

import com.google.common.collect.ImmutableSet;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.RandomSource;
import net.minecraft.world.DifficultyInstance;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.EntityDimensions;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.MobSpawnType;
import net.minecraft.world.entity.Pose;
import net.minecraft.world.entity.SpawnGroupData;
import net.minecraft.world.entity.ai.attributes.AttributeSupplier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.ai.goal.Goal;
import net.minecraft.world.entity.ai.goal.MeleeAttackGoal;
import net.minecraft.world.entity.ai.goal.RangedBowAttackGoal;
import net.minecraft.world.entity.ai.goal.WrappedGoal;
import net.minecraft.world.entity.monster.Monster;
import net.minecraft.world.entity.monster.Skeleton;
import net.minecraft.world.entity.projectile.AbstractArrow;
import net.minecraft.world.entity.projectile.Arrow;
import net.minecraft.world.item.BowItem;
import net.minecraft.world.item.DyeColor;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.alchemy.PotionUtils;
import net.minecraft.world.item.enchantment.EnchantmentHelper;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.ServerLevelAccessor;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's forgotten (Forgotten, ForgottenModule, CC BY-NC-SA 3.0): a big skeleton with an
 * enchanted bow whose arrows blind, which draws its sheathed sword while you're blinded.
 * Wears the forgotten hat. Quark also swaps some deep skeleton spawns for it; that's left
 * out, so it comes from structures and their spawners.
 */
public class Forgotten extends Skeleton {
    static final EntityDataAccessor<ItemStack> SHEATHED = SynchedEntityData.defineId(Forgotten.class,
            EntityDataSerializers.ITEM_STACK);

    public Forgotten(EntityType<? extends Forgotten> type, Level level) {
        super(type, level);
    }

    static AttributeSupplier.Builder attributes() {
        return Monster.createMonsterAttributes().add(Attributes.MOVEMENT_SPEED, 0.3).add(Attributes.MAX_HEALTH, 60)
                .add(Attributes.KNOCKBACK_RESISTANCE, 1);
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(SHEATHED, ItemStack.EMPTY);
    }

    @Override
    public SpawnGroupData finalizeSpawn(ServerLevelAccessor level, DifficultyInstance difficulty, MobSpawnType reason,
            SpawnGroupData data, CompoundTag tag) {
        SpawnGroupData out = super.finalizeSpawn(level, difficulty, reason, data, tag);
        reassessWeaponGoal();
        return out;
    }

    @Override
    public void tick() {
        super.tick();
        if (!level().isClientSide) {
            LivingEntity target = getTarget();
            MobEffectInstance blind = target == null ? null : target.getEffect(MobEffects.BLINDNESS);
            boolean bow = target == null || blind == null || blind.getDuration() < 20;
            if (bow != getMainHandItem().getItem() instanceof BowItem) swap();
        }
        double w = getBbWidth() * 2, h = getBbHeight();
        level().addParticle(ParticleTypes.AMBIENT_ENTITY_EFFECT, getX() + Math.random() * w - w / 2,
                getY() + Math.random() * h, getZ() + Math.random() * w - w / 2, 0, 0, 0);
    }

    private void swap() {
        ItemStack held = getMainHandItem();
        setItemInHand(InteractionHand.MAIN_HAND, entityData.get(SHEATHED));
        entityData.set(SHEATHED, held);
        goalSelector.getRunningGoals().map(WrappedGoal::getGoal)
                .filter(g -> g instanceof MeleeAttackGoal || g instanceof RangedBowAttackGoal<?>).forEach(Goal::stop);
        reassessWeaponGoal();
    }

    @Override
    protected ResourceLocation getDefaultLootTable() {
        return QuarkBlocks.rl("entities/forgotten");
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.put("sheathed", entityData.get(SHEATHED).save(new CompoundTag()));
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        entityData.set(SHEATHED, ItemStack.of(tag.getCompound("sheathed")));
    }

    @Override
    protected float getStandingEyeHeight(Pose pose, EntityDimensions size) {
        return 2.1F;
    }

    @Override
    protected void dropCustomDeathLoot(net.minecraft.world.damagesource.DamageSource source, int looting, boolean hit) {
        // Its bow, sword and hat stay with it; the loot table gives the hat.
    }

    @Override
    public boolean canPickUpLoot() {
        return false;
    }

    @Override
    protected void populateDefaultEquipmentSlots(RandomSource rand, DifficultyInstance difficulty) {
        super.populateDefaultEquipmentSlots(rand, difficulty);
        prepareEquipment();
    }

    void prepareEquipment() {
        ItemStack bow = new ItemStack(Items.BOW), sword = new ItemStack(Items.IRON_SWORD);
        EnchantmentHelper.enchantItem(random, bow, 20, false);
        EnchantmentHelper.enchantItem(random, sword, 20, false);
        if (random.nextBoolean()) {
            String rune = DyeColor.values()[random.nextInt(DyeColor.values().length)].getName();
            bow.getOrCreateTag().putString(Runes.TAG, rune);
            sword.getOrCreateTag().putString(Runes.TAG, rune);
        }
        setItemSlot(EquipmentSlot.MAINHAND, bow);
        entityData.set(SHEATHED, sword);
        if (QuarkItems.has("forgotten_hat")) {
            setItemSlot(EquipmentSlot.HEAD, new ItemStack(QuarkBlocks.ALL_ITEMS.get("forgotten_hat").get()));
        }
    }

    @Override
    protected AbstractArrow getArrow(ItemStack arrowStack, float distance) {
        AbstractArrow arrow = super.getArrow(arrowStack, distance);
        if (arrow instanceof Arrow a) {
            ItemStack tipped = new ItemStack(Items.TIPPED_ARROW);
            PotionUtils.setCustomEffects(tipped, ImmutableSet.of(new MobEffectInstance(MobEffects.BLINDNESS, 100, 0)));
            a.setEffectsFromItem(tipped);
        }
        return arrow;
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }
}
