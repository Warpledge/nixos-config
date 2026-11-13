package warpledge.quarkblocks;

import com.google.common.collect.ImmutableMultimap;
import com.google.common.collect.Multimap;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.stats.Stats;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.InteractionResultHolder;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.Attribute;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.animal.Parrot;
import net.minecraft.world.entity.monster.Slime;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ArmorItem;
import net.minecraft.world.item.ArmorMaterials;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.ChunkPos;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.level.levelgen.WorldgenRandom;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.common.ForgeMod;
import net.minecraftforge.event.entity.player.PlayerInteractEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Quark's items that work on their own (CC BY-NC-SA 3.0; each names its Quark class), with
 * Quark's default config. The ones that need an entity or a mixin live in their own files.
 */
final class QuarkItems {
    private QuarkItems() {}

    /** AncientFruitItem: food that gives 10 experience points. */
    static final class AncientFruit extends Item {
        AncientFruit(Properties p) {
            super(p);
        }

        @Override
        public ItemStack finishUsingItem(ItemStack stack, Level level, LivingEntity living) {
            ItemStack out = super.finishUsingItem(stack, level, living);
            if (living instanceof Player player) {
                player.giveExperiencePoints(10);
                player.playSound(SoundEvents.EXPERIENCE_ORB_PICKUP, 1F, 1F);
            }
            return out;
        }
    }

    /** ForgottenHatItem: a helmet worth 1 armour, 1 luck and 2 blocks of reach. */
    static final class ForgottenHat extends ArmorItem {
        private static final UUID ID = UUID.fromString("2AD3F246-FEE1-4E67-B886-69FD380BB150");
        private Multimap<Attribute, AttributeModifier> attributes;

        ForgottenHat(Properties p) {
            super(ArmorMaterials.LEATHER, Type.HELMET, p);
        }

        @Override
        public String getArmorTexture(ItemStack stack, Entity entity, EquipmentSlot slot, String type) {
            return QuarkBlocks.ID + ":textures/misc/forgotten_hat_worn.png";
        }

        @Override
        public boolean isEnchantable(ItemStack stack) {
            return false;
        }

        @Override
        public void initializeClient(java.util.function.Consumer<net.minecraftforge.client.extensions.common.IClientItemExtensions> c) {
            c.accept(new net.minecraftforge.client.extensions.common.IClientItemExtensions() {
                @Override
                public net.minecraft.client.model.HumanoidModel<?> getHumanoidArmorModel(LivingEntity e, ItemStack s,
                        EquipmentSlot slot, net.minecraft.client.model.HumanoidModel<?> original) {
                    return ClientMobs.hatModel();
                }
            });
        }

        @Override
        public Multimap<Attribute, AttributeModifier> getDefaultAttributeModifiers(EquipmentSlot slot) {
            if (attributes == null) {
                attributes = ImmutableMultimap.<Attribute, AttributeModifier>builder()
                        .put(Attributes.ARMOR, new AttributeModifier(ID, "Armor modifier", 1, AttributeModifier.Operation.ADDITION))
                        .put(Attributes.LUCK, new AttributeModifier(ID, "Armor luck modifier", 1, AttributeModifier.Operation.ADDITION))
                        .put(ForgeMod.ENTITY_REACH.get(), new AttributeModifier(ID, "Armor entity reach modifier", 2,
                                AttributeModifier.Operation.ADDITION))
                        .put(ForgeMod.BLOCK_REACH.get(), new AttributeModifier(ID, "Armor block reach modifier", 2,
                                AttributeModifier.Operation.ADDITION))
                        .build();
            }
            return slot == getEquipmentSlot() ? attributes : super.getDefaultAttributeModifiers(slot);
        }
    }

    /** ParrotEggItem: thrown, it hatches a baby parrot of its colour. */
    static final class ParrotEggItem extends Item {
        final Parrot.Variant variant;

        ParrotEggItem(Properties p, String variant) {
            super(p);
            Parrot.Variant v = Parrot.Variant.RED_BLUE;
            for (Parrot.Variant x : Parrot.Variant.values()) if (x.getSerializedName().equals(variant)) v = x;
            this.variant = v;
        }

        @Override
        public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
            ItemStack stack = player.getItemInHand(hand);
            level.playSound(null, player.getX(), player.getY(), player.getZ(), SoundEvents.EGG_THROW, SoundSource.PLAYERS,
                    0.5F, 0.4F / (level.getRandom().nextFloat() * 0.4F + 0.8F));
            if (!level.isClientSide) {
                ParrotEgg egg = new ParrotEgg(level, player);
                egg.setItem(stack);
                egg.setVariant(variant);
                egg.shootFromRotation(player, player.getXRot(), player.getYRot(), 0F, 1.5F, 1F);
                level.addFreshEntity(egg);
            }
            player.awardStat(Stats.ITEM_USED.get(this));
            if (!player.getAbilities().instabuild) stack.shrink(1);
            return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
        }
    }

    /**
     * AbacusItem: bind it to a block, then it counts the blocks from there to the one you
     * look at, up to 48 (ClientSetup draws the count and the path).
     */
    static final class Abacus extends Item {
        static final int MAX = 48;

        Abacus(Properties p) {
            super(p);
        }

        @Override
        public InteractionResult useOn(UseOnContext ctx) {
            ItemStack stack = ctx.getItemInHand();
            bind(stack, bound(stack) == null ? ctx.getClickedPos() : null);
            return InteractionResult.sidedSuccess(ctx.getLevel().isClientSide);
        }

        static void bind(ItemStack stack, BlockPos pos) {
            CompoundTag tag = stack.getOrCreateTag();
            if (pos == null) {
                tag.putInt("boundPosY", -999);
                return;
            }
            tag.putInt("boundPosX", pos.getX());
            tag.putInt("boundPosY", pos.getY());
            tag.putInt("boundPosZ", pos.getZ());
        }

        static BlockPos bound(ItemStack stack) {
            CompoundTag tag = stack.getTag();
            if (tag == null || !tag.contains("boundPosY") || tag.getInt("boundPosY") == -999) return null;
            return new BlockPos(tag.getInt("boundPosX"), tag.getInt("boundPosY"), tag.getInt("boundPosZ"));
        }

        static int count(ItemStack stack, BlockPos target, Level level) {
            BlockPos pos = bound(stack);
            return pos != null && !level.isEmptyBlock(target) ? Mth.clamp(target.distManhattan(pos), 0, MAX) : -1;
        }
    }

    /** TrowelItem: places a random block from your hotbar. */
    static final class Trowel extends Item {
        Trowel(Properties p) {
            super(p);
        }

        @Override
        public InteractionResult useOn(UseOnContext ctx) {
            Player player = ctx.getPlayer();
            if (player == null) return InteractionResult.PASS;
            InteractionHand hand = ctx.getHand();
            Inventory inv = player.getInventory();
            List<Integer> targets = new ArrayList<>();
            for (int i = 0; i < Inventory.getSelectionSize(); i++) {
                ItemStack s = inv.getItem(i);
                if (!s.isEmpty() && s.getItem() instanceof BlockItem) targets.add(i);
            }
            if (targets.isEmpty()) return InteractionResult.PASS;
            ItemStack trowel = player.getItemInHand(hand);
            CompoundTag tag = trowel.getOrCreateTag();
            Random rand = new Random(tag.getLong("placing_seed"));
            tag.putLong("placing_seed", rand.nextLong());
            int slot = targets.get(rand.nextInt(targets.size()));
            ItemStack place = inv.getItem(slot);
            player.setItemInHand(hand, place);
            InteractionResult result = place.useOn(new BlockPlaceContext(ctx.getLevel(), player, hand, place,
                    new BlockHitResult(ctx.getClickLocation(), ctx.getClickedFace(), ctx.getClickedPos(), ctx.isInside())));
            ItemStack after = player.getItemInHand(hand);
            player.setItemInHand(hand, trowel);
            inv.setItem(slot, after);
            if (result.consumesAction()) tag.put("last_stack", place.serializeNBT());
            return result;
        }
    }

    /** SlimeInABucketItem: a captured small slime; it wiggles (excited) in slime chunks. */
    static final class SlimeBucket extends Item {
        SlimeBucket(Properties p) {
            super(p);
        }

        @Override
        public void inventoryTick(ItemStack stack, Level level, Entity entity, int slot, boolean selected) {
            if (!(level instanceof ServerLevel server)) return;
            ChunkPos c = new ChunkPos(entity.blockPosition());
            boolean slime = WorldgenRandom.seedSlimeChunk(c.x, c.z, server.getSeed(), 987234911L).nextInt(10) == 0;
            if (stack.getOrCreateTag().getBoolean("excited") != slime) stack.getOrCreateTag().putBoolean("excited", slime);
        }

        @Override
        public InteractionResult useOn(UseOnContext ctx) {
            BlockPos pos = ctx.getClickedPos();
            Direction face = ctx.getClickedFace();
            Level level = ctx.getLevel();
            Player player = ctx.getPlayer();
            if (player == null) return InteractionResult.PASS;
            if (!level.isClientSide) {
                Slime slime = new Slime(EntityType.SLIME, level);
                CompoundTag tag = ctx.getItemInHand().getTag();
                if (tag != null && tag.contains("slime_nbt")) {
                    slime.load(tag.getCompound("slime_nbt"));
                } else {
                    slime.getAttribute(Attributes.MAX_HEALTH).setBaseValue(1.0);
                    slime.getAttribute(Attributes.MOVEMENT_SPEED).setBaseValue(0.3);
                    slime.setHealth(slime.getMaxHealth());
                }
                slime.setPos(pos.getX() + 0.5 + face.getStepX(), pos.getY() + 0.5 + face.getStepY(),
                        pos.getZ() + 0.5 + face.getStepZ());
                level.gameEvent(player, GameEvent.ENTITY_PLACE, slime.position());
                level.addFreshEntity(slime);
                player.swing(ctx.getHand());
            }
            level.playSound(player, pos, SoundEvents.BUCKET_EMPTY, SoundSource.NEUTRAL, 1F, 1F);
            if (!player.getAbilities().instabuild) player.setItemInHand(ctx.getHand(), new ItemStack(Items.BUCKET));
            return InteractionResult.sidedSuccess(level.isClientSide);
        }

        @Override
        public Component getName(ItemStack stack) {
            CompoundTag tag = stack.getTag();
            if (tag != null && tag.getCompound("slime_nbt").contains("CustomName")) {
                Component name = Component.Serializer.fromJson(tag.getCompound("slime_nbt").getString("CustomName"));
                if (name != null) return Component.translatable("item.quarkblocks.slime_in_a_bucket.named", name);
            }
            return super.getName(stack);
        }
    }

    /** SlimeInABucketModule: a bucket used on a small slime picks it up. */
    @SubscribeEvent
    public static void bucketSlime(PlayerInteractEvent.EntityInteract event) {
        if (!has("slime_in_a_bucket") || !(event.getTarget() instanceof Slime slime) || slime.getType() != EntityType.SLIME
                || slime.getSize() != 1 || !slime.isAlive()) {
            return;
        }
        Player player = event.getEntity();
        InteractionHand hand = player.getMainHandItem().is(Items.BUCKET) ? InteractionHand.MAIN_HAND
                : player.getOffhandItem().is(Items.BUCKET) ? InteractionHand.OFF_HAND : null;
        if (hand == null) return;
        if (!event.getLevel().isClientSide) {
            ItemStack out = new ItemStack(QuarkBlocks.ALL_ITEMS.get("slime_in_a_bucket").get());
            out.getOrCreateTag().put("slime_nbt", slime.serializeNBT());
            ItemStack bucket = player.getItemInHand(hand);
            if (bucket.getCount() == 1) {
                player.setItemInHand(hand, out);
            } else {
                bucket.shrink(1);
                if (!player.getInventory().add(out)) player.drop(out, false);
            }
            event.getLevel().gameEvent(player, GameEvent.ENTITY_INTERACT, slime.position());
            slime.discard();
        }
        event.setCanceled(true);
        event.setCancellationResult(InteractionResult.sidedSuccess(event.getLevel().isClientSide));
    }

    /** BottledCloudItem: places a cloud block where you look, even in mid-air. */
    static final class BottledCloud extends Item {
        BottledCloud(Properties p) {
            super(p);
        }

        @Override
        public InteractionResultHolder<ItemStack> use(Level level, Player player, InteractionHand hand) {
            ItemStack stack = player.getItemInHand(hand);
            Vec3 eyes = player.getEyePosition();
            double reach = player.getBlockReach();
            HitResult hit = level.clip(new ClipContext(eyes, eyes.add(player.getViewVector(1F).scale(reach)),
                    ClipContext.Block.OUTLINE, ClipContext.Fluid.ANY, player));
            if (hit instanceof BlockHitResult b) {
                BlockPos pos = b.getBlockPos();
                if (!level.isEmptyBlock(pos)) pos = pos.relative(b.getDirection());
                if (level.isEmptyBlock(pos)) {
                    if (!level.isClientSide) {
                        level.gameEvent(player, GameEvent.BLOCK_PLACE, pos);
                        level.setBlockAndUpdate(pos, QuarkBlocks.ALL.get("cloud").get().defaultBlockState());
                    }
                    stack.shrink(1);
                    if (!player.getAbilities().instabuild) {
                        ItemStack bottle = new ItemStack(Items.GLASS_BOTTLE);
                        if (stack.isEmpty()) stack = bottle;
                        else if (!player.addItem(bottle)) player.drop(bottle, false);
                    }
                    player.getCooldowns().addCooldown(this, 10);
                    return InteractionResultHolder.sidedSuccess(stack, level.isClientSide);
                }
            }
            return InteractionResultHolder.pass(stack);
        }
    }

    /** BottledCloudModule: a glass bottle used at cloud height (y 191 to 196) fills with cloud. */
    @SubscribeEvent
    public static void fillCloud(PlayerInteractEvent.RightClickItem event) {
        Player player = event.getEntity();
        ItemStack stack = event.getItemStack();
        if (!has("bottled_cloud") || !stack.is(Items.GLASS_BOTTLE) || player.getY() <= 191 || player.getY() >= 196) {
            return;
        }
        stack.shrink(1);
        ItemStack cloud = new ItemStack(QuarkBlocks.ALL_ITEMS.get("bottled_cloud").get());
        if (!player.addItem(cloud)) player.drop(cloud, false);
        event.setCanceled(true);
        event.setCancellationResult(InteractionResult.sidedSuccess(player.level().isClientSide));
    }

    /** Whether gen.py listed the item, since the events above run whether it's there or not. */
    static boolean has(String id) {
        return QuarkBlocks.ALL_ITEMS.containsKey(id);
    }
}
