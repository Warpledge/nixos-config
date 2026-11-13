package warpledge.quarkblocks;

import com.mojang.authlib.GameProfile;
import java.util.UUID;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.syncher.EntityDataAccessor;
import net.minecraft.network.syncher.EntityDataSerializers;
import net.minecraft.network.syncher.SynchedEntityData;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.tags.BlockTags;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.decoration.ItemFrame;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.BannerItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.MapItem;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.WallHangingSignBlock;
import net.minecraft.world.level.block.WallSignBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.BlockStateProperties;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.level.saveddata.maps.MapItemSavedData;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.common.capabilities.ForgeCapabilities;
import net.minecraftforge.common.util.FakePlayerFactory;
import net.minecraftforge.entity.IEntityAdditionalSpawnData;
import net.minecraftforge.network.NetworkHooks;

/**
 * Quark's glass item frame (GlassItemFrame and GlassItemFrameModule, CC BY-NC-SA 3.0): an
 * item frame with no frame, showing its item bigger; a shiny one glows. Right-clicked, it
 * opens the inventory behind it. It hangs on signs, and a map in it keeps updating.
 */
public class GlassItemFrame extends ItemFrame implements IEntityAdditionalSpawnData {
    static final EntityDataAccessor<Boolean> SHINY = SynchedEntityData.defineId(GlassItemFrame.class,
            EntityDataSerializers.BOOLEAN);
    private static final GameProfile DUMMY = new GameProfile(UUID.randomUUID(), "ItemFrame");
    private boolean droppedOwnItem;
    int signRotation;
    Attachment attachment = Attachment.NONE;

    enum Attachment { NONE, STANDING_IN_FRONT, STANDING_BEHIND, WALL_SIGN, HANGING_FROM_WALL, HANGING_IN_FRONT, HANGING_BEHIND }

    public GlassItemFrame(EntityType<? extends GlassItemFrame> type, Level level) {
        super(type, level);
    }

    GlassItemFrame(Level level, BlockPos pos, Direction face) {
        super(QuarkBlocks.GLASS_FRAME.get(), level);
        this.pos = pos;
        setDirection(face);
    }

    @Override
    public InteractionResult interact(Player player, InteractionHand hand) {
        ItemStack item = getItem();
        if (!player.isShiftKeyDown() && !item.isEmpty() && !(item.getItem() instanceof BannerItem)) {
            BlockPos behind = behind();
            BlockEntity be = level().getBlockEntity(behind);
            if (be != null && be.getCapability(ForgeCapabilities.ITEM_HANDLER).isPresent()) {
                InteractionResult r = level().getBlockState(behind).use(level(), player, hand,
                        new BlockHitResult(position(), direction, behind, true));
                if (r.consumesAction()) return r;
            }
        }
        InteractionResult r = super.interact(player, hand);
        updateAttachment();
        return r;
    }

    @Override
    public void tick() {
        super.tick();
        if (level().getGameTime() % 100 != 0) return;
        updateAttachment();
        if (level().isClientSide || !(getItem().getItem() instanceof MapItem map) || !(level() instanceof ServerLevel server)) {
            return;
        }
        ItemStack clone = getItem().copy();
        MapItemSavedData data = MapItem.getSavedData(clone, level());
        if (data != null && !data.locked) {
            var fake = FakePlayerFactory.get(server, DUMMY);
            clone.setEntityRepresentation(null);
            fake.setPos(getX(), getY(), getZ());
            fake.getInventory().setItem(0, clone);
            map.update(level(), fake, data);
        }
    }

    private void updateAttachment() {
        attachment = Attachment.NONE;
        if (direction.getAxis() == Direction.Axis.Y) return;
        BlockState back = level().getBlockState(behind());
        boolean standing = back.is(BlockTags.STANDING_SIGNS), ceiling = back.is(BlockTags.CEILING_HANGING_SIGNS);
        if (standing || ceiling) {
            signRotation = back.getValue(BlockStateProperties.ROTATION_16);
            double[] angles = {0, 0, 0, 180, -90, 90};
            double ours = angles[getDirection().getOpposite().ordinal()];
            double sign = signRotation / 16.0 * 360.0;
            if (sign > 180) sign -= 360;
            double diff = ours - sign, abs = Math.abs(diff);
            if (diff < 0) abs -= 0.01; // two frames equidistant both ways mustn't both attach
            if (abs < 45) attachment = standing ? Attachment.STANDING_IN_FRONT : Attachment.HANGING_IN_FRONT;
            else if (abs >= 135 && abs < 225) attachment = standing ? Attachment.STANDING_BEHIND : Attachment.HANGING_BEHIND;
        } else if (back.is(BlockTags.WALL_SIGNS)) {
            if (back.getValue(WallSignBlock.FACING) == getDirection()) attachment = Attachment.WALL_SIGN;
        } else if (back.is(BlockTags.WALL_HANGING_SIGNS)) {
            Direction d = back.getValue(WallHangingSignBlock.FACING);
            if (d == getDirection() || d == getDirection().getOpposite()) attachment = Attachment.HANGING_FROM_WALL;
        }
    }

    BlockPos behind() {
        return pos.relative(direction.getOpposite());
    }

    @Override
    protected void defineSynchedData() {
        super.defineSynchedData();
        entityData.define(SHINY, false);
    }

    @Override
    public boolean survives() {
        return attachment != Attachment.NONE || super.survives();
    }

    @Override
    public ItemEntity spawnAtLocation(ItemStack stack, float offset) {
        // ItemFrame drops a vanilla frame for itself; drop the glass one instead.
        if (stack.is(Items.ITEM_FRAME) && !droppedOwnItem) {
            stack = new ItemStack(item());
            droppedOwnItem = true;
        }
        return super.spawnAtLocation(stack, offset);
    }

    @Override
    public ItemStack getPickedResult(HitResult target) {
        return getItem().isEmpty() ? new ItemStack(item()) : getItem().copy();
    }

    private Item item() {
        String id = entityData.get(SHINY) ? "glowing_glass_item_frame" : "glass_item_frame";
        var item = QuarkBlocks.ALL_ITEMS.get(id);
        return item != null ? item.get() : Items.ITEM_FRAME;
    }

    @Override
    public void addAdditionalSaveData(CompoundTag tag) {
        super.addAdditionalSaveData(tag);
        tag.putBoolean("isShiny", entityData.get(SHINY));
    }

    @Override
    public void readAdditionalSaveData(CompoundTag tag) {
        super.readAdditionalSaveData(tag);
        entityData.set(SHINY, tag.getBoolean("isShiny"));
    }

    @Override
    public Packet<ClientGamePacketListener> getAddEntityPacket() {
        return NetworkHooks.getEntitySpawningPacket(this);
    }

    @Override
    public void writeSpawnData(FriendlyByteBuf buf) {
        buf.writeBlockPos(pos);
        buf.writeVarInt(direction.get3DDataValue());
    }

    @Override
    public void readSpawnData(FriendlyByteBuf buf) {
        pos = buf.readBlockPos();
        setDirection(Direction.from3DDataValue(buf.readVarInt()));
    }

    /** The frame's item (QuarkItemFrameItem); the glowing one makes a shiny frame. */
    public static class FrameItem extends Item {
        private final boolean shiny;

        public FrameItem(Properties p, boolean shiny) {
            super(p);
            this.shiny = shiny;
        }

        @Override
        public InteractionResult useOn(UseOnContext ctx) {
            BlockPos at = ctx.getClickedPos().relative(ctx.getClickedFace());
            Player player = ctx.getPlayer();
            ItemStack stack = ctx.getItemInHand();
            if (player != null && (player.level().isOutsideBuildHeight(at)
                    || !player.mayUseItemAt(at, ctx.getClickedFace(), stack))) {
                return InteractionResult.FAIL;
            }
            Level level = ctx.getLevel();
            GlassItemFrame frame = new GlassItemFrame(level, at, ctx.getClickedFace());
            frame.entityData.set(SHINY, shiny);
            if (stack.getTag() != null) EntityType.updateCustomEntityTag(level, player, frame, stack.getTag());
            if (frame.survives()) {
                if (!level.isClientSide) {
                    level.gameEvent(player, GameEvent.ENTITY_PLACE, frame.position());
                    frame.playPlacementSound();
                    level.addFreshEntity(frame);
                }
                stack.shrink(1);
            }
            return InteractionResult.sidedSuccess(level.isClientSide);
        }
    }

    Vec3 renderOffset() {
        return new Vec3(getDirection().getStepX() * 0.3F, -0.25, getDirection().getStepZ() * 0.3F);
    }
}
