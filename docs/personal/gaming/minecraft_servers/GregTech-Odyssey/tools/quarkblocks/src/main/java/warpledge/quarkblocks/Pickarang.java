package warpledge.quarkblocks;

import com.google.common.collect.ImmutableMultimap;
import com.google.common.collect.Multimap;
import it.unimi.dsi.fastutil.ints.IntOpenHashSet;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.BlockParticleOption;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundSource;
import net.minecraft.stats.Stats;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.effect.MobEffectUtil;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.ExperienceOrb;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.Attribute;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.entity.projectile.Projectile;
import net.minecraft.world.entity.projectile.ProjectileUtil;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.enchantment.Enchantment;
import net.minecraft.world.item.enchantment.EnchantmentHelper;
import net.minecraft.world.item.enchantment.Enchantments;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.LevelEvent;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.common.ForgeHooks;
import net.minecraftforge.common.ForgeMod;
import net.minecraftforge.event.ForgeEventFactory;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's pickarang (AbstractPickarang, Pickarang, PickarangItem, CC BY-NC-SA 3.0, with the
 * diamond pickarang's defaults): thrown, it mines what a diamond pickaxe can up to hardness
 * 20, hits mobs, and flies back carrying the drops. Efficiency speeds it, piercing lets it
 * go through more. The netherite flamerang isn't in any structure, so it's left out.
 */
public class Pickarang extends Projectile {
    private static final EntityDataAccessor<ItemStack> STACK = SynchedEntityData.defineId(Pickarang.class,
            EntityDataSerializers.ITEM_STACK);
    private static final EntityDataAccessor<Boolean> RETURNING = SynchedEntityData.defineId(Pickarang.class,
            EntityDataSerializers.BOOLEAN);
    static final int TIMEOUT = 20;
    static final double MAX_HARDNESS = 20;

    private int liveTime;
    private int slot;
    private int blockHits;
    private IntOpenHashSet entitiesHit;

    public Pickarang(EntityType<Pickarang> type, Level level) {
        super(type, level);
    }

    Pickarang(Level level, LivingEntity thrower) {
        this(QuarkBlocks.PICKARANG.get(), level);
        setPos(thrower.getX(), thrower.getY() + thrower.getEyeHeight(), thrower.getZ());
        setOwner(thrower);
    }

    @Override
    protected void defineSynchedData() {
        entityData.define(STACK, ItemStack.EMPTY);
        entityData.define(RETURNING, false);
    }

    ItemStack stack() {
        return entityData.get(STACK);
    }

    private void setStack(ItemStack s) {
        entityData.set(STACK, s);
    }

    boolean returning() {
        return entityData.get(RETURNING);
    }

    private void setReturning() {
        entityData.set(RETURNING, true);
    }

    private int level(Enchantment e) {
        return EnchantmentHelper.getItemEnchantmentLevel(e, stack());
    }

    void throwFrom(Player player, int slot, ItemStack stack, float velocity) {
        this.slot = slot;
        setStack(stack.copy());
        float yaw = player.getYRot() * ((float) Math.PI / 180F), pitch = player.getXRot() * ((float) Math.PI / 180F);
        shoot(-Mth.sin(yaw) * Mth.cos(pitch), -Mth.sin(pitch), Mth.cos(yaw) * Mth.cos(pitch), velocity, 0F);
        Vec3 m = player.getDeltaMovement();
        setDeltaMovement(getDeltaMovement().add(m.x, player.onGround() ? 0 : m.y, m.z));
    }

    @Override
    public void shoot(double x, double y, double z, float velocity, float inaccuracy) {
        Vec3 v = new Vec3(x, y, z).normalize().scale(velocity);
        setDeltaMovement(v);
        setYRot((float) (Mth.atan2(v.x, v.z) * (180F / Math.PI)));
        setXRot((float) (Mth.atan2(v.y, v.horizontalDistance()) * (180F / Math.PI)));
        yRotO = getYRot();
        xRotO = getXRot();
    }

    @Override
    public boolean shouldRenderAtSqrDistance(double d) {
        double size = getBoundingBox().getSize() * 4 * 64;
        return d < size * size;
    }

    private void checkImpact() {
        if (level().isClientSide) return;
        Vec3 from = position(), to = from.add(getDeltaMovement());
        boolean entities = true;
        for (int tries = 100; isAlive() && !returning() && tries > 0; tries--) {
            if (entities) {
                EntityHitResult hit = ProjectileUtil.getEntityHitResult(level(), this, from, to,
                        getBoundingBox().expandTowards(getDeltaMovement()).inflate(1), e -> !e.isSpectator() && e.isAlive()
                                && (e.isPickable() || e instanceof Pickarang) && e != getOwner()
                                && (entitiesHit == null || !entitiesHit.contains(e.getId())));
                if (hit != null) onHit(hit);
                else entities = false;
            } else {
                HitResult hit = level().clip(new ClipContext(from, to, ClipContext.Block.COLLIDER, ClipContext.Fluid.NONE, this));
                if (hit.getType() == HitResult.Type.MISS) return;
                onHit(hit);
            }
        }
    }

    @Override
    protected void onHitBlock(BlockHitResult result) {
        super.onHitBlock(result);
        BlockPos pos = result.getBlockPos();
        BlockState state = level().getBlockState(pos);
        if (level(Enchantments.PIERCING) == 0 || state.isSolid()) addHit();
        if (!(getOwner() instanceof ServerPlayer player)) return;
        ItemStack prev = player.getMainHandItem();
        try {
            player.getInventory().setItem(player.getInventory().selected, stack());
            player.setItemInHand(InteractionHand.MAIN_HAND, stack());
            float progress = destroyProgress(state, player, pos);
            if (progress == 0) return;
            float hardness = 1 / progress / 100 * (100 / 30F);
            if (player.getAbilities().instabuild || hardness <= MAX_HARDNESS && hardness >= 0
                    && !state.is(PickarangItem.IMMUNE)) {
                if (player.gameMode.destroyBlock(pos)) {
                    level().levelEvent(null, LevelEvent.PARTICLES_DESTROY_BLOCK, pos, Block.getId(state));
                } else {
                    clank(result);
                }
                setStack(player.getInventory().getSelected());
            } else {
                clank(result);
            }
        } finally {
            player.setItemInHand(InteractionHand.MAIN_HAND, prev);
            player.getInventory().setItem(player.getInventory().selected, prev);
        }
    }

    private float destroyProgress(BlockState state, Player player, BlockPos pos) {
        float hardness = state.getDestroySpeed(level(), pos);
        if (hardness == -1) return 0;
        float speed = 1;
        if (MobEffectUtil.hasDigSpeed(player)) speed *= 1 + (MobEffectUtil.getDigSpeedAmplification(player) + 1) * 0.2F;
        if (player.hasEffect(MobEffects.DIG_SLOWDOWN)) {
            speed *= switch (player.getEffect(MobEffects.DIG_SLOWDOWN).getAmplifier()) {
                case 0 -> 0.3F;
                case 1 -> 0.09F;
                case 2 -> 0.0027F;
                default -> 8.1E-4F;
            };
        }
        if (isEyeInFluidType(ForgeMod.WATER_TYPE.get())) speed /= 5;
        speed = ForgeEventFactory.getBreakSpeed(player, state, speed, pos);
        return speed / (hardness * (ForgeHooks.isCorrectToolForDrops(state, player) ? 30 : 100));
    }

    @Override
    protected void onHitEntity(EntityHitResult result) {
        super.onHitEntity(result);
        Entity owner = getOwner();
        Entity hit = result.getEntity();
        if (hit == owner) return;
        addHit(hit);
        if (hit instanceof Pickarang other) {
            other.setReturning();
            clank(result);
            return;
        }
        ItemStack pick = stack();
        Multimap<Attribute, AttributeModifier> mods = pick.getAttributeModifiers(EquipmentSlot.MAINHAND);
        if (owner instanceof LivingEntity living) {
            ItemStack prev = living.getMainHandItem();
            living.setItemInHand(InteractionHand.MAIN_HAND, pick);
            living.getAttributes().addTransientAttributeModifiers(mods);
            int swing = living.attackStrengthTicker;
            living.attackStrengthTicker = (int) (1.0 / living.getAttributeValue(Attributes.ATTACK_SPEED) * 20.0) + 1;
            float before = hit instanceof LivingEntity l ? l.getHealth() : 0;
            if (!(hit instanceof PickarangTarget t && t.pickarangHit(this, pick, owner))) {
                if (owner instanceof Player p) p.attack(hit);
                else living.doHurtTarget(hit);
                if (hit instanceof LivingEntity l && l.getHealth() == before) clank(result);
            }
            living.attackStrengthTicker = swing;
            setStack(living.getMainHandItem());
            living.setItemInHand(InteractionHand.MAIN_HAND, prev);
            living.getAttributes().removeAttributeModifiers(mods);
        } else {
            pick.hurt(1, level().random, null);
            setStack(pick);
            hit.hurt(damageSources().thrown(this, owner), PickarangItem.DAMAGE + 1);
        }
    }

    /** A mob a pickarang does something special to (Quark: a toretoise drops its ore). */
    interface PickarangTarget {
        boolean pickarangHit(Pickarang rang, ItemStack pick, Entity owner);
    }

    private void spark() {
        playSound(QuarkBlocks.SOUND_BY_NAME.get("entity.pickarang.spark").get(), 1, 1);
        setReturning();
    }

    private void clank(HitResult hit) {
        if (hit instanceof BlockHitResult b && level() instanceof ServerLevel server) {
            Vec3 at = b.getLocation();
            server.sendParticles(new BlockParticleOption(ParticleTypes.BLOCK, level().getBlockState(b.getBlockPos())),
                    at.x, at.y, at.z, 2, 0, 0, 0, 0);
        }
        playSound(QuarkBlocks.SOUND_BY_NAME.get("entity.pickarang.clank").get(), 1, 1);
        setReturning();
    }

    private void addHit(Entity e) {
        if (entitiesHit == null) entitiesHit = new IntOpenHashSet(5);
        entitiesHit.add(e.getId());
        postHit();
    }

    private void addHit() {
        blockHits++;
        postHit();
    }

    private void postHit() {
        int pierce = level(Enchantments.PIERCING);
        if ((entitiesHit == null ? 0 : entitiesHit.size()) + blockHits > pierce) setReturning();
        else if (pierce > 0) setDeltaMovement(getDeltaMovement().scale(0.8));
    }

    @Override
    public boolean isPushedByFluid() {
        return false;
    }

    @Override
    public void tick() {
        Vec3 pos = position();
        xOld = pos.x;
        yOld = pos.y;
        zOld = pos.z;
        super.tick();
        if (!returning()) checkImpact();
        Vec3 m = getDeltaMovement();
        setPos(pos.x + m.x, pos.y + m.y, pos.z + m.z);
        setYRot((float) (Mth.atan2(m.x, m.z) * (180F / Math.PI)));
        setXRot((float) (Mth.atan2(m.y, m.horizontalDistance()) * (180F / Math.PI)));
        while (getXRot() - xRotO < -180) xRotO -= 360;
        while (getXRot() - xRotO >= 180) xRotO += 360;
        while (getYRot() - yRotO < -180) yRotO -= 360;
        while (getYRot() - yRotO >= 180) yRotO += 360;
        setXRot(Mth.lerp(0.2F, xRotO, getXRot()));
        setYRot(Mth.lerp(0.2F, yRotO, getYRot()));
        float drag = 0.99F;
        if (isInWater()) {
            for (int i = 0; i < 4; i++) {
                level().addParticle(ParticleTypes.BUBBLE, pos.x - m.x * 0.25, pos.y - m.y * 0.25, pos.z - m.z * 0.25,
                        m.x, m.y, m.z);
            }
            drag = 0.8F;
        }
        setDeltaMovement(m.scale(drag));
        if (!isAlive()) return;
        liveTime++;
        Entity owner = getOwner();
        if (!(owner instanceof Player player) || !owner.isAlive()) {
            if (!level().isClientSide) {
                while (isInWall()) setPos(getX(), getY() + 1, getZ());
                spawnAtLocation(stack(), 0);
                discard();
            }
            return;
        }
        if (!returning()) {
            if (liveTime > TIMEOUT) setReturning();
            if (!level().getWorldBorder().isWithinBounds(getBoundingBox())) spark();
            return;
        }
        noPhysics = true;
        int eff = level(Enchantments.BLOCK_EFFICIENCY);
        List<ItemEntity> items = level().getEntitiesOfClass(ItemEntity.class, getBoundingBox().inflate(2));
        List<ExperienceOrb> xp = level().getEntitiesOfClass(ExperienceOrb.class, getBoundingBox().inflate(2));
        for (ItemEntity item : items) {
            if (!item.isPassenger()) {
                item.startRiding(this);
                item.setPickUpDelay(5);
            }
        }
        for (ExperienceOrb orb : xp) if (!orb.isPassenger()) orb.startRiding(this);
        Vec3 toOwner = owner.position().add(0, 1, 0).subtract(position());
        if (toOwner.lengthSqr() >= 3.25 + eff * 0.25) {
            setDeltaMovement(toOwner.normalize().scale(0.7 + eff * 0.325F));
            return;
        }
        if (level().isClientSide) return;
        playSound(QuarkBlocks.SOUND_BY_NAME.get("entity.pickarang.pickup").get(), 1, 1);
        Inventory inv = player.getInventory();
        ItemStack stack = stack();
        if (!stack.isEmpty()) {
            if (player.isAlive() && inv.getItem(slot).isEmpty()) inv.setItem(slot, stack);
            else if (!player.isAlive() || !inv.add(stack)) player.drop(stack, false);
        }
        if (player.isAlive()) {
            for (ItemEntity item : items) if (item.isAlive()) give(player, item);
            for (ExperienceOrb orb : xp) if (orb.isAlive()) orb.playerTouch(player);
            for (Entity rider : getPassengers()) {
                if (!rider.isAlive()) continue;
                if (rider instanceof ItemEntity item) give(player, item);
                else if (rider instanceof ExperienceOrb) rider.playerTouch(player);
            }
        }
        discard();
    }

    private static void give(Player player, ItemEntity item) {
        item.setPickUpDelay(0);
        item.playerTouch(player);
        if (item.isAlive()) {
            player.drop(item.getItem(), false);
            item.discard();
        }
    }

    @Override
    protected boolean canAddPassenger(Entity e) {
        return super.canAddPassenger(e) || e instanceof ItemEntity || e instanceof ExperienceOrb;
    }

    @Override
    public double getPassengersRidingOffset() {
        return 0;
    }

    @Override
    public SoundSource getSoundSource() {
        return SoundSource.PLAYERS;
    }

    @Override
    protected void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        entityData.set(RETURNING, tag.getBoolean("returning"));
        liveTime = tag.getInt("liveTime");
        blockHits = tag.getInt("hitCount");
        slot = tag.getInt("returnSlot");
        setStack(tag.contains("itemStack") ? ItemStack.of(tag.getCompound("itemStack")) : ItemStack.EMPTY);
    }

    @Override
    protected void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putBoolean("returning", returning());
        tag.putInt("liveTime", liveTime);
        tag.putInt("hitCount", blockHits);
        tag.putInt("returnSlot", slot);
        tag.put("itemStack", stack().serializeNBT());
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }

    /** The diamond pickarang item (PickarangItem with Quark's pickarang type). */
    public static class PickarangItem extends Item {
        static final net.minecraft.tags.TagKey<Block> IMMUNE =
                net.minecraft.tags.BlockTags.create(QuarkBlocks.rl("pickarang_immune"));
        static final int DAMAGE = 2;
        private static final int COOLDOWN = 10;
        private Multimap<Attribute, AttributeModifier> attributes;

        public PickarangItem(Properties p) {
            super(p.durability(800));
        }

        @Override
        public boolean hurtEnemy(ItemStack stack, LivingEntity target, LivingEntity attacker) {
            stack.hurtAndBreak(2, attacker, e -> e.broadcastBreakEvent(InteractionHand.MAIN_HAND));
            return true;
        }

        @Override
        public boolean isCorrectToolForDrops(BlockState state) {
            return Items.DIAMOND_PICKAXE.isCorrectToolForDrops(state) || Items.DIAMOND_AXE.isCorrectToolForDrops(state)
                    || Items.DIAMOND_SHOVEL.isCorrectToolForDrops(state);
        }

        @Override
        public boolean mineBlock(ItemStack stack, Level level, BlockState state, BlockPos pos, LivingEntity miner) {
            if (state.getDestroySpeed(level, pos) != 0) {
                stack.hurtAndBreak(1, miner, e -> e.broadcastBreakEvent(InteractionHand.MAIN_HAND));
            }
            return true;
        }

        @Override
        public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
            ItemStack stack = player.getItemInHand(hand);
            player.setItemInHand(hand, ItemStack.EMPTY);
            int eff = EnchantmentHelper.getItemEnchantmentLevel(Enchantments.BLOCK_EFFICIENCY, stack);
            level.playSound(null, player.getX(), player.getY(), player.getZ(),
                    QuarkBlocks.SOUND_BY_NAME.get("entity.pickarang.throw").get(), SoundSource.NEUTRAL,
                    0.5F + eff * 0.14F, 0.4F / (level.random.nextFloat() * 0.4F + 0.8F));
            if (!level.isClientSide) {
                Inventory inv = player.getInventory();
                int slot = hand == InteractionHand.OFF_HAND ? inv.getContainerSize() - 1 : inv.selected;
                Pickarang rang = new Pickarang(level, player);
                rang.throwFrom(player, slot, stack, 1.5F + eff * 0.325F);
                level.addFreshEntity(rang);
            }
            if (!player.getAbilities().instabuild && COOLDOWN - eff > 0) {
                player.getCooldowns().addCooldown(this, COOLDOWN - eff);
            }
            player.awardStat(Stats.ITEM_USED.get(this));
            return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
        }

        @Override
        @SuppressWarnings("deprecation")
        public Multimap<Attribute, AttributeModifier> getDefaultAttributeModifiers(EquipmentSlot slot) {
            if (slot != EquipmentSlot.MAINHAND) return ImmutableMultimap.of();
            if (attributes == null) {
                attributes = ImmutableMultimap.of(
                        Attributes.ATTACK_DAMAGE, new AttributeModifier(BASE_ATTACK_DAMAGE_UUID, "Weapon modifier", DAMAGE,
                                AttributeModifier.Operation.ADDITION),
                        Attributes.ATTACK_SPEED, new AttributeModifier(BASE_ATTACK_SPEED_UUID, "Weapon modifier", -2.8,
                                AttributeModifier.Operation.ADDITION));
            }
            return attributes;
        }

        @Override
        public float getDestroySpeed(ItemStack stack, BlockState state) {
            return 0F;
        }

        @Override
        public boolean isRepairable(ItemStack stack) {
            return true;
        }

        @Override
        public boolean isValidRepairItem(ItemStack stack, ItemStack repair) {
            return repair.is(Items.DIAMOND);
        }

        @Override
        public int getEnchantmentValue() {
            return Items.DIAMOND_PICKAXE.getEnchantmentValue();
        }

        @Override
        public boolean canApplyAtEnchantingTable(ItemStack stack, Enchantment e) {
            return super.canApplyAtEnchantingTable(stack, e) || e == Enchantments.BLOCK_FORTUNE
                    || e == Enchantments.SILK_TOUCH || e == Enchantments.BLOCK_EFFICIENCY;
        }
    }
}
