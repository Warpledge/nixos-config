package warpledge.quarkblocks;

import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.Difficulty;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.MobSpawnType;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.SpawnEggItem;
import net.minecraft.world.level.GameRules;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.LevelEvent;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.level.storage.loot.LootParams;
import net.minecraft.world.level.storage.loot.LootTable;
import net.minecraft.world.level.storage.loot.parameters.LootContextParamSets;
import net.minecraft.world.level.storage.loot.parameters.LootContextParams;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.event.entity.living.LivingDropsEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Quark's monster box, reimplemented with its defaults: a player within 2.5 blocks wakes
 * it, it smokes for 2 seconds, spawns 5 to 8 mobs from misc/monster_box_spawns and
 * breaks. Mobs it spawned drop misc/monster_box when a player kills them.
 */
public class MonsterBoxBlockEntity extends BlockEntity {
    static final double RANGE = 2.5;
    static final int MIN_MOBS = 5, MAX_MOBS = 8, FUSE_TICKS = 40;
    static final String SPAWNED = QuarkBlocks.ID + ":monster_box_spawned";

    private int breakProgress;

    public MonsterBoxBlockEntity(BlockPos pos, BlockState state) {
        super(QuarkBlocks.MONSTER_BOX_BE.get(), pos, state);
    }

    static void tick(Level level, BlockPos pos, BlockState state, MonsterBoxBlockEntity be) {
        if (level.getDifficulty() == Difficulty.PEACEFUL) return;
        double x = pos.getX(), y = pos.getY(), z = pos.getZ();
        if (level.isClientSide) {
            level.addParticle(be.breakProgress == 0 ? ParticleTypes.FLAME : ParticleTypes.LARGE_SMOKE,
                    x + Math.random(), y + Math.random(), z + Math.random(), 0, 0, 0);
        }
        boolean waking = be.breakProgress > 0;
        if (!waking) {
            for (Player p : level.players()) {
                if (!p.isSpectator() && p.distanceToSqr(x + 0.5, y + 0.5, z + 0.5) < RANGE * RANGE) {
                    waking = true;
                    break;
                }
            }
        }
        if (!waking) return;
        if (be.breakProgress == 0) {
            level.playSound(null, pos, QuarkBlocks.MONSTER_BOX_GROWL.get(), SoundSource.BLOCKS, 0.5F, 1F);
        }
        if (++be.breakProgress > FUSE_TICKS && level instanceof ServerLevel server) {
            be.spawnMobs(server);
            level.levelEvent(LevelEvent.PARTICLES_DESTROY_BLOCK, pos, Block.getId(state));
            level.removeBlock(pos, false);
        }
    }

    private void spawnMobs(ServerLevel level) {
        BlockPos pos = getBlockPos();
        LootTable table = level.getServer().getLootData().getLootTable(QuarkBlocks.rl("misc/monster_box_spawns"));
        LootParams params = new LootParams.Builder(level)
                .withParameter(LootContextParams.ORIGIN, Vec3.atCenterOf(pos))
                .withParameter(LootContextParams.BLOCK_STATE, getBlockState())
                .withParameter(LootContextParams.TOOL, ItemStack.EMPTY)
                .withParameter(LootContextParams.BLOCK_ENTITY, this)
                .create(LootContextParamSets.BLOCK);
        int count = MIN_MOBS + level.random.nextInt(MAX_MOBS - MIN_MOBS + 1);
        for (int i = 0; i < count; i++) {
            table.getRandomItemsRaw(params, stack -> {
                if (!(stack.getItem() instanceof SpawnEggItem egg)) return;
                Entity e = egg.getType(stack.getTag())
                        .spawn(level, stack, null, pos, MobSpawnType.SPAWNER, true, true);
                if (e == null) return;
                e.setPos(pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5);
                e.setDeltaMovement((level.random.nextFloat() - 0.5) * 0.4,
                        (level.random.nextFloat() - 0.5) * 0.4, (level.random.nextFloat() - 0.5) * 0.4);
                e.getPersistentData().putBoolean(SPAWNED, true);
            });
        }
        level.gameEvent(null, GameEvent.ENTITY_PLACE, pos);
    }

    /** The extra loot from mobs a monster box spawned. */
    public static final class Drops {
        private Drops() {}

        @SubscribeEvent
        public static void onDrops(LivingDropsEvent event) {
            LivingEntity entity = event.getEntity();
            if (!(entity.level() instanceof ServerLevel level)
                    || !entity.getPersistentData().getBoolean(SPAWNED)
                    || !event.isRecentlyHit()
                    || !level.getGameRules().getBoolean(GameRules.RULE_DOMOBLOOT)) {
                return;
            }
            LootTable table = level.getServer().getLootData().getLootTable(QuarkBlocks.rl("misc/monster_box"));
            LootParams.Builder b = new LootParams.Builder(level)
                    .withParameter(LootContextParams.THIS_ENTITY, entity)
                    .withParameter(LootContextParams.ORIGIN, entity.position())
                    .withParameter(LootContextParams.DAMAGE_SOURCE, event.getSource())
                    .withOptionalParameter(LootContextParams.KILLER_ENTITY, event.getSource().getEntity())
                    .withOptionalParameter(LootContextParams.DIRECT_KILLER_ENTITY,
                            event.getSource().getDirectEntity());
            if (event.getSource().getEntity() instanceof Player p) {
                b = b.withParameter(LootContextParams.LAST_DAMAGE_PLAYER, p).withLuck(p.getLuck());
            }
            for (ItemStack stack : table.getRandomItems(b.create(LootContextParamSets.ENTITY))) {
                event.getDrops().add(new ItemEntity(level, entity.getX(), entity.getY(), entity.getZ(), stack));
            }
        }
    }
}
