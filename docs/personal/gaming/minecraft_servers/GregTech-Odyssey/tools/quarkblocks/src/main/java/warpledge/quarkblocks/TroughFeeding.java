package warpledge.quarkblocks;

import java.util.Map;
import java.util.Optional;
import java.util.WeakHashMap;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.entity.ExperienceOrb;
import net.minecraft.world.entity.ai.village.poi.PoiManager;
import net.minecraft.world.entity.ai.village.poi.PoiType;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.GameRules;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.event.entity.EntityJoinLevelEvent;
import net.minecraftforge.event.entity.living.BabyEntitySpawnEvent;
import net.minecraftforge.event.entity.living.LivingEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Animals going to feeding troughs, with Quark's numbers (FeedingTroughModule, CC BY-NC-SA
 * 3.0). Quark hooks the animals' tempt goal and sensor with mixins so a fake player holding
 * the trough's food lures them; this walks them there from a tick event instead. Breeding
 * from a trough gives no experience.
 */
final class TroughFeeding {
    static final ResourceKey<PoiType> POI = ResourceKey.create(Registries.POINT_OF_INTEREST_TYPE,
            QuarkBlocks.rl("feeding_trough"));
    private static final int COOLDOWN = 30;
    private static final double LOOK_CHANCE = 0.015 * 20;
    private static final int GIVE_UP = 20 * 20;
    private static final Map<Animal, Target> TARGETS = new WeakHashMap<>();
    private static final ThreadLocal<Boolean> BRED = ThreadLocal.withInitial(() -> false);

    private TroughFeeding() {}

    private static final class Target {
        final BlockPos pos;
        int cooldown;
        int giveUp = GIVE_UP;

        Target(BlockPos pos) {
            this.pos = pos;
        }
    }

    @SubscribeEvent
    public static void tick(LivingEvent.LivingTickEvent event) {
        if (!(event.getEntity() instanceof Animal animal) || !(animal.level() instanceof ServerLevel level)) return;
        // Quark asks while the tempt goal runs, about every tick; every 2 ticks is plenty.
        if ((animal.tickCount + animal.getId()) % 2 != 0) return;
        if (!animal.canFallInLove() || animal.getAge() != 0) {
            TARGETS.remove(animal);
            return;
        }
        Target t = TARGETS.get(animal);
        if (t != null && !valid(level, animal, t)) {
            TARGETS.remove(animal);
            t = null;
        }
        if (t == null) {
            if (level.random.nextFloat() > LOOK_CHANCE) return;
            t = find(level, animal);
            if (t == null) return;
            TARGETS.put(animal, t);
        }
        t.giveUp--;
        if (t.cooldown > 0) {
            if (--t.cooldown == 0) TARGETS.remove(animal);
            return;
        }
        float reach = 0.5F + animal.getBbWidth() * 1.8F;
        if (t.pos.distToCenterSqr(animal.position()) < reach * reach
                && level.getBlockEntity(t.pos) instanceof FeedingTroughBlockEntity trough) {
            switch (trough.tryFeeding(animal)) {
                case FED -> t.cooldown = COOLDOWN;
                case LOVE -> TARGETS.remove(animal);
                default -> {}
            }
            animal.getNavigation().stop();
        } else if (animal.getNavigation().isDone() && sees(level, animal, t.pos)) {
            animal.getNavigation().moveTo(t.pos.getX() + 0.5, t.pos.getY(), t.pos.getZ() + 0.5, 1.0);
            animal.getLookControl().setLookAt(Vec3.atCenterOf(t.pos));
        }
    }

    private static boolean valid(ServerLevel level, Animal animal, Target t) {
        if (!animal.isAlive() || t.giveUp <= 0 || t.pos.distSqr(animal.blockPosition())
                > FeedingTroughBlockEntity.RANGE * FeedingTroughBlockEntity.RANGE) {
            return false;
        }
        return t.cooldown > 0 || (level.getBlockEntity(t.pos) instanceof FeedingTroughBlockEntity trough
                && trough.hasFoodFor(animal));
    }

    private static Target find(ServerLevel level, Animal animal) {
        BlockPos at = animal.getOnPos();
        double r = FeedingTroughBlockEntity.RANGE;
        Optional<BlockPos> found = level.getPoiManager().findClosest(h -> h.is(POI), p -> p.distSqr(at) <= r * r,
                at, (int) r, PoiManager.Occupancy.ANY);
        return found.filter(p -> level.getBlockEntity(p) instanceof FeedingTroughBlockEntity trough
                && trough.hasFoodFor(animal)).map(Target::new).orElse(null);
    }

    private static boolean sees(ServerLevel level, Animal animal, BlockPos pos) {
        Vec3 eyes = animal.position().add(0, animal.getEyeHeight(), 0);
        Vec3 target = Vec3.atLowerCornerOf(pos).add(0.5, 0.0625, 0.5);
        BlockHitResult hit = level.clip(new ClipContext(eyes, target, ClipContext.Block.COLLIDER,
                ClipContext.Fluid.NONE, animal));
        return hit.getType() == HitResult.Type.BLOCK && hit.getBlockPos().equals(pos);
    }

    @SubscribeEvent
    public static void bred(BabyEntitySpawnEvent event) {
        if (event.getCausedByPlayer() == null && event.getParentA().level().getGameRules()
                .getBoolean(GameRules.RULE_DOMOBLOOT)) {
            BRED.set(true);
        }
    }

    @SubscribeEvent
    public static void orb(EntityJoinLevelEvent event) {
        if (event.getEntity() instanceof ExperienceOrb && BRED.get()) {
            event.setCanceled(true);
            BRED.remove();
        }
    }
}
