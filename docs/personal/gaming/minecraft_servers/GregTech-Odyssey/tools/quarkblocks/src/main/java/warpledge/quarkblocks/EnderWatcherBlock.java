package warpledge.quarkblocks;

import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.particles.DustParticleOptions;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.entity.monster.EnderMan;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityTicker;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import org.joml.Vector3f;

/**
 * Quark's ender watcher (EnderWatcherBlock and its block entity, CC BY-NC-SA 3.0): gives
 * redstone while a player within 80 blocks looks at it, 15 at the centre of a face, less
 * towards the edges. A carved pumpkin or other ender mask hides the player.
 */
public class EnderWatcherBlock extends Block implements EntityBlock {
    public static final BooleanProperty WATCHED = BooleanProperty.create("watched");
    public static final IntegerProperty POWER = BlockStateProperties.POWER;

    public EnderWatcherBlock(Properties props) {
        super(props);
        registerDefaultState(defaultBlockState().setValue(WATCHED, false).setValue(POWER, 0));
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(WATCHED, POWER);
    }

    @Override
    public boolean isSignalSource(BlockState state) {
        return true;
    }

    @Override
    public int getSignal(BlockState state, BlockGetter level, BlockPos pos, Direction side) {
        return state.getValue(POWER);
    }

    @Override
    public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
        return new Entity(pos, state);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T extends BlockEntity> BlockEntityTicker<T> getTicker(Level level, BlockState state, BlockEntityType<T> type) {
        return type == QuarkBlocks.WATCHER_BE.get() ? (l, p, s, be) -> tick(l, p, s) : null;
    }

    private static void tick(Level level, BlockPos pos, BlockState state) {
        int range = 80;
        List<Player> players = level.getEntitiesOfClass(Player.class, new AABB(pos).inflate(range));
        EnderMan fake = new EnderMan(EntityType.ENDERMAN, level);
        fake.setPos(pos.getX() + 0.5, pos.getY() + 0.5 - fake.getEyeHeight(), pos.getZ() + 0.5);
        boolean looking = false;
        int power = 0;
        for (Player player : players) {
            ItemStack helm = player.getItemBySlot(EquipmentSlot.HEAD);
            fake.lookAt(player, 180, 180);
            if (!helm.isEmpty() && helm.isEnderMask(player, fake)) continue;
            Vec3 eyes = player.getEyePosition();
            HitResult hit = level.clip(new ClipContext(eyes, eyes.add(player.getViewVector(1F).scale(64)),
                    ClipContext.Block.OUTLINE, ClipContext.Fluid.NONE, player));
            if (hit instanceof BlockHitResult b && b.getType() == HitResult.Type.BLOCK && b.getBlockPos().equals(pos)) {
                looking = true;
                Vec3 v = b.getLocation();
                Direction d = b.getDirection();
                double x = Math.abs(v.x - pos.getX() - 0.5) * (1 - Math.abs(d.getStepX()));
                double y = Math.abs(v.y - pos.getY() - 0.5) * (1 - Math.abs(d.getStepY()));
                double z = Math.abs(v.z - pos.getZ() - 0.5) * (1 - Math.abs(d.getStepZ()));
                double fract = 1 - Math.sqrt(x * x + y * y + z * z) / 0.7071067811865476;
                power = Math.max(power, (int) Math.ceil(fract * 15));
            }
        }
        if (!level.isClientSide && (looking != state.getValue(WATCHED) || power != state.getValue(POWER))) {
            level.setBlock(pos, state.setValue(WATCHED, looking).setValue(POWER, power), 3);
        }
        if (looking) {
            level.addParticle(new DustParticleOptions(new Vector3f(1F, 0F, 0F), 1F),
                    pos.getX() - 0.1 + Math.random() * 1.2, pos.getY() - 0.1 + Math.random() * 1.2,
                    pos.getZ() - 0.1 + Math.random() * 1.2, 0, 0, 0);
        }
    }

    /** quarkblocks:ender_watcher; only ticks. */
    public static class Entity extends BlockEntity {
        public Entity(BlockPos pos, BlockState state) {
            super(QuarkBlocks.WATCHER_BE.get(), pos, state);
        }
    }
}
