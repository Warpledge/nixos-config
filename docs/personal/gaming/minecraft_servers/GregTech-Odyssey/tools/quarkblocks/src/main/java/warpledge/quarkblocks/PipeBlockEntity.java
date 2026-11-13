package warpledge.quarkblocks;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.Random;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.particles.DustParticleOptions;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.nbt.ListTag;
import net.minecraft.nbt.Tag;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.game.ClientGamePacketListener;
import net.minecraft.network.protocol.game.ClientboundBlockEntityDataPacket;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.Container;
import net.minecraft.world.WorldlyContainer;
import net.minecraft.world.WorldlyContainerHolder;
import net.minecraft.world.entity.item.ItemEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.LevelAccessor;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.LevelEvent;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraftforge.common.capabilities.ForgeCapabilities;
import net.minecraftforge.items.IItemHandler;
import net.minecraftforge.items.ItemHandlerHelper;
import net.minecraftforge.items.wrapper.InvWrapper;
import net.minecraftforge.items.wrapper.SidedInvWrapper;
import org.joml.Vector3f;

/**
 * quarkblocks:pipe (Quark's PipeBlockEntity, CC BY-NC-SA 3.0), with Quark's defaults: an
 * item takes 10 ticks to cross, more than 16 at once breaks the pipe. Items prefer down,
 * then straight on, then a random side, then up. Saves "pipeItems" and "connections" as
 * Quark does, so the templates' pipes keep what they carry.
 */
public class PipeBlockEntity extends BlockEntity implements WorldlyContainer {
    static final int SPEED = 10;
    private static final int MAX_ITEMS = 16;
    private static final List<Direction> HORIZONTALS =
            List.of(Direction.NORTH, Direction.SOUTH, Direction.WEST, Direction.EAST);

    final List<PipeItem> items = new LinkedList<>();
    private final List<PipeItem> queued = new LinkedList<>();
    private final Connection[] connections = new Connection[6];
    private boolean iterating;

    public PipeBlockEntity(BlockPos pos, BlockState state) {
        super(QuarkBlocks.PIPE_BE.get(), pos, state);
    }

    void tick() {
        boolean enabled = enabled();
        if (!enabled && level.getGameTime() % 10 == 0 && level instanceof ServerLevel server) {
            server.sendParticles(new DustParticleOptions(new Vector3f(1F, 0F, 0F), 1F), worldPosition.getX() + 0.5,
                    worldPosition.getY() + 0.5, worldPosition.getZ() + 0.5, 3, 0.2, 0.2, 0.2, 0);
        }
        if (!level.isClientSide && enabled) {
            boolean picked = false;
            for (Direction side : Direction.values()) {
                if (connection(side) != Connection.OPENING) continue;
                AABB box = new AABB(
                        worldPosition.getX() + 0.25 + 0.5 * Math.min(0, side.getStepX()),
                        worldPosition.getY() + 0.25 + 0.5 * Math.min(0, side.getStepY()),
                        worldPosition.getZ() + 0.25 + 0.5 * Math.min(0, side.getStepZ()),
                        worldPosition.getX() + 0.75 + 0.5 * Math.max(0, side.getStepX()),
                        worldPosition.getY() + 0.75 + 0.5 * Math.max(0, side.getStepY()),
                        worldPosition.getZ() + 0.75 + 0.5 * Math.max(0, side.getStepZ()));
                Direction against = side.getOpposite();
                for (ItemEntity item : level.getEntitiesOfClass(ItemEntity.class, box, e -> e.isAlive()
                        && Direction.getNearest(e.getDeltaMovement().x, e.getDeltaMovement().y,
                                e.getDeltaMovement().z) == against)) {
                    passIn(item.getItem().copy(), side);
                    level.playSound(null, item.getX(), item.getY(), item.getZ(), QuarkBlocks.PIPE_PICKUP.get(),
                            SoundSource.BLOCKS, 1F, 1F);
                    level.gameEvent(GameEvent.PROJECTILE_LAND, worldPosition, GameEvent.Context.of(getBlockState()));
                    item.discard();
                    picked = true;
                }
            }
            if (picked) sync();
        }
        int before = comparatorOutput();
        if (!items.isEmpty()) {
            if (items.size() > MAX_ITEMS && !level.isClientSide) {
                level.levelEvent(LevelEvent.PARTICLES_DESTROY_BLOCK, worldPosition, Block.getId(getBlockState()));
                drop(new ItemStack(getBlockState().getBlock()), null, false);
                level.removeBlock(worldPosition, false);
            }
            iterating = true;
            for (ListIterator<PipeItem> it = items.listIterator(); it.hasNext(); ) {
                PipeItem item = it.next();
                Direction last = item.outgoing;
                if (item.tick(this)) {
                    it.remove();
                    if (item.valid) passOut(item);
                    else if (!level.isClientSide) drop(item.stack, last, true);
                }
            }
            iterating = false;
            items.addAll(queued);
            if (!queued.isEmpty()) sync();
            queued.clear();
        }
        if (comparatorOutput() != before) level.updateNeighbourForOutputSignal(worldPosition, getBlockState().getBlock());
    }

    int comparatorOutput() {
        return Math.min(15, items.size());
    }

    boolean passIn(ItemStack stack, Direction face, Direction backlog, long seed, int time) {
        PipeItem item = new PipeItem(stack, face, seed);
        item.lastTick = level.getGameTime();
        item.backlogged = backlog;
        if (iterating) {
            queued.add(item);
            return true;
        }
        int before = comparatorOutput();
        items.add(item);
        item.timeInWorld = time;
        if (comparatorOutput() != before) level.updateNeighbourForOutputSignal(worldPosition, getBlockState().getBlock());
        return true;
    }

    boolean passIn(ItemStack stack, Direction face) {
        return passIn(stack, face, null, level.random.nextLong(), 0);
    }

    private void passOut(PipeItem item) {
        BlockPos target = worldPosition.relative(item.outgoing);
        boolean did = false;
        BlockEntity be = level.getBlockEntity(target);
        if (level.getBlockState(target).getBlock() instanceof WorldlyContainerHolder || be != null) {
            if (be instanceof PipeBlockEntity pipe) {
                did = pipe.passIn(item.stack, item.outgoing.getOpposite(), null, item.seed, item.timeInWorld);
            } else if (!level.isClientSide) {
                ItemStack rest = insert(item.stack, level, target, be, item.outgoing.getOpposite(), false);
                if (rest.getCount() != item.stack.getCount()) {
                    did = true;
                    if (!rest.isEmpty()) bounceBack(item, rest);
                }
            }
        }
        if (!did) bounceBack(item, null);
    }

    private void bounceBack(PipeItem item, ItemStack stack) {
        if (!level.isClientSide) {
            passIn(stack == null ? item.stack : stack, item.outgoing, item.incoming, item.seed, item.timeInWorld);
        }
    }

    /** Zeta's MiscUtil.putIntoInv: what's left after putting stack into the block at pos. */
    static ItemStack insert(ItemStack stack, LevelAccessor level, BlockPos pos, BlockEntity be, Direction face,
            boolean simulate) {
        IItemHandler handler = null;
        BlockState state = level.getBlockState(pos);
        if (state.getBlock() instanceof WorldlyContainerHolder holder) {
            handler = new SidedInvWrapper(holder.getContainer(state, level, pos), face);
        } else if (be != null) {
            handler = be.getCapability(ForgeCapabilities.ITEM_HANDLER, face).orElse(null);
            if (handler == null && be instanceof WorldlyContainer c) handler = new SidedInvWrapper(c, face);
            else if (handler == null && be instanceof Container c) handler = new InvWrapper(c);
        }
        return handler == null ? stack : ItemHandlerHelper.insertItem(handler, stack, simulate);
    }

    private boolean canFit(ItemStack stack, BlockPos pos, Direction face) {
        BlockEntity be = level.getBlockEntity(pos);
        if (!(level.getBlockState(pos).getBlock() instanceof WorldlyContainerHolder) && be == null) return false;
        if (be instanceof PipeBlockEntity pipe) return pipe.enabled();
        return insert(stack, level, pos, be, face, true).isEmpty();
    }

    private void drop(ItemStack stack, Direction facing, boolean sound) {
        if (level.isClientSide) return;
        double x = worldPosition.getX() + 0.5, y = worldPosition.getY() + 0.25, z = worldPosition.getZ() + 0.5;
        if (facing != null) {
            x -= facing.getStepX() * 0.4;
            y -= facing.getStepY() * 0.55;
            z -= facing.getStepZ() * 0.4;
        }
        boolean shoot = enabled();
        if (sound) {
            level.playSound(null, x, y, z, QuarkBlocks.PIPE_SHOOT.get(), SoundSource.BLOCKS, 1F, shoot ? 1F : 0.025F);
            level.gameEvent(GameEvent.PROJECTILE_SHOOT, worldPosition, GameEvent.Context.of(getBlockState()));
        }
        ItemEntity e = new ItemEntity(level, x, y, z, stack);
        e.setDefaultPickUpDelay();
        if (facing != null) {
            double v = shoot ? 0.5 : 0.125;
            e.setDeltaMovement(-facing.getStepX() * v, -facing.getStepY() * v, -facing.getStepZ() * v);
        }
        level.addFreshEntity(e);
    }

    void dropAll() {
        for (PipeItem item : items) drop(item.stack, null, false);
        items.clear();
    }

    private boolean enabled() {
        return getBlockState().getBlock() instanceof PipeBlock && !level.hasNeighborSignal(worldPosition);
    }

    private void sync() {
        if (level instanceof ServerLevel server) server.sendBlockUpdated(worldPosition, getBlockState(), getBlockState(), 3);
    }

    //-- Connections

    // A copper pipe makes a full connection only to solid sides (BasePipeBlock), so each
    // type has one flare shift.
    enum Connection {
        NONE(false, false, 0),
        PIPE(true, false, 0),
        OPENING(false, true, -0.125),
        TERMINAL(true, true, 0.125),
        TERMINAL_OFFSET(true, true, 0.1875);

        final boolean solid;
        final boolean flared;
        final double flareShift;

        Connection(boolean solid, boolean flared, double flareShift) {
            this.solid = solid;
            this.flared = flared;
            this.flareShift = flareShift;
        }
    }

    void refreshConnections() {
        if (level == null) return;
        for (Direction d : Direction.values()) connections[d.ordinal()] = connectionTo(level, worldPosition, d);
    }

    Connection connection(Direction d) {
        if (connections[d.ordinal()] == null && level != null) connections[d.ordinal()] = connectionTo(level, worldPosition, d);
        return connections[d.ordinal()] == null ? Connection.NONE : connections[d.ordinal()];
    }

    static Connection connectionTo(BlockGetter level, BlockPos pos, Direction face) {
        return connectionTo(level, pos, face, false);
    }

    private static Connection connectionTo(BlockGetter level, BlockPos pos, Direction face, boolean recursed) {
        BlockPos at = pos.relative(face);
        BlockState state = level.getBlockState(at);
        if (state.getBlock() instanceof WorldlyContainerHolder) return Connection.TERMINAL;
        BlockEntity be = level.getBlockEntity(at);
        if (be instanceof PipeBlockEntity) return Connection.PIPE;
        if (be instanceof Container || be != null && be.getCapability(ForgeCapabilities.ITEM_HANDLER,
                face.getOpposite()).isPresent()) {
            VoxelShape shape = state.getCollisionShape(level, pos);
            boolean offset = face.getAxisDirection() == Direction.AxisDirection.NEGATIVE
                    ? shape.max(face.getAxis()) < 1 : shape.min(face.getAxis()) > 0;
            return offset ? Connection.TERMINAL_OFFSET : Connection.TERMINAL;
        }
        // An open end: the far side is solid and no other side is.
        if (!recursed && connectionTo(level, pos, face.getOpposite(), true).solid) {
            for (Direction d : Direction.values()) {
                if (d.getAxis() != face.getAxis() && connectionTo(level, pos, d, true).solid) return Connection.NONE;
            }
            return Connection.OPENING;
        }
        return Connection.NONE;
    }

    //-- Saving and syncing

    @Override
    public void load(CompoundTag tag) {
        super.load(tag);
        items.clear();
        ListTag list = tag.getList("pipeItems", Tag.TAG_COMPOUND);
        for (int i = 0; i < list.size(); i++) items.add(PipeItem.read(list.getCompound(i)));
        byte[] c = tag.getByteArray("connections");
        for (int i = 0; i < c.length && i < 6; i++) connections[i] = Connection.values()[c[i]];
    }

    @Override
    protected void saveAdditional(CompoundTag tag) {
        super.saveAdditional(tag);
        writeShared(tag);
    }

    private void writeShared(CompoundTag tag) {
        ListTag list = new ListTag();
        for (PipeItem item : items) list.add(item.write());
        tag.put("pipeItems", list);
        byte[] c = new byte[6];
        for (Direction d : Direction.values()) c[d.ordinal()] = (byte) connection(d).ordinal();
        tag.putByteArray("connections", c);
    }

    @Override
    public CompoundTag getUpdateTag() {
        CompoundTag tag = new CompoundTag();
        writeShared(tag);
        return tag;
    }

    @Override
    public Packet<ClientGamePacketListener> getUpdatePacket() {
        return ClientboundBlockEntityDataPacket.create(this);
    }

    //-- Container: hoppers and the like put items in through a face's slot

    @Override
    public int getContainerSize() {
        return 6;
    }

    @Override
    public boolean isEmpty() {
        return true;
    }

    @Override
    public ItemStack getItem(int slot) {
        return ItemStack.EMPTY;
    }

    @Override
    public ItemStack removeItem(int slot, int count) {
        return ItemStack.EMPTY;
    }

    @Override
    public ItemStack removeItemNoUpdate(int slot) {
        return ItemStack.EMPTY;
    }

    @Override
    public void setItem(int slot, ItemStack stack) {
        if (stack.isEmpty()) return;
        passIn(stack, Direction.values()[slot]);
        if (!level.isClientSide) sync();
    }

    @Override
    public boolean stillValid(Player player) {
        return false;
    }

    @Override
    public void clearContent() {}

    @Override
    public int[] getSlotsForFace(Direction side) {
        return new int[] {0, 1, 2, 3, 4, 5};
    }

    @Override
    public boolean canPlaceItemThroughFace(int slot, ItemStack stack, Direction dir) {
        return dir != null && slot == dir.ordinal() && enabled();
    }

    @Override
    public boolean canTakeItemThroughFace(int slot, ItemStack stack, Direction dir) {
        return false;
    }

    /** One item on its way through, with Quark's NBT names. */
    static final class PipeItem {
        final ItemStack stack;
        final Direction incoming;
        Direction outgoing;
        Direction backlogged;
        long seed;
        int ticks;
        int timeInWorld;
        boolean valid = true;
        long lastTick;

        PipeItem(ItemStack stack, Direction face, long seed) {
            this.stack = stack;
            incoming = outgoing = face;
            this.seed = seed;
        }

        boolean tick(PipeBlockEntity pipe) {
            long now = pipe.level.getGameTime();
            if (lastTick != now) {
                lastTick = now;
                ticks++;
                timeInWorld++;
                if (ticks == SPEED / 2 - 1) outgoing = target(pipe);
                if (outgoing == null) {
                    valid = false;
                    return true;
                }
            }
            return ticks >= SPEED;
        }

        private Direction target(PipeBlockEntity pipe) {
            BlockPos at = pipe.worldPosition;
            if (incoming != Direction.DOWN && backlogged != Direction.DOWN
                    && pipe.canFit(stack, at.below(), Direction.UP)) {
                return Direction.DOWN;
            }
            Direction straight = incoming;
            if (incoming.getAxis() != Direction.Axis.Y) {
                straight = incoming.getOpposite();
                if (straight != backlogged && pipe.canFit(stack, at.relative(straight), incoming)) return straight;
            }
            List<Direction> sides = new ArrayList<>(HORIZONTALS);
            sides.remove(incoming);
            sides.remove(straight);
            Random rng = new Random(seed);
            seed = rng.nextLong();
            Collections.shuffle(sides, rng);
            for (Direction side : sides) {
                if (side != backlogged && pipe.canFit(stack, at.relative(side), side.getOpposite())) return side;
            }
            if (incoming != Direction.UP && backlogged != Direction.UP && pipe.canFit(stack, at.above(), Direction.DOWN)) {
                return Direction.UP;
            }
            return backlogged;
        }

        float fraction(float partial) {
            return (ticks + partial) / SPEED;
        }

        CompoundTag write() {
            CompoundTag tag = stack.save(new CompoundTag());
            tag.putInt("ticksInPipe", ticks);
            tag.putInt("incomingFace", incoming.ordinal());
            tag.putInt("outgoingFace", outgoing.ordinal());
            tag.putInt("backloggedFace", backlogged == null ? -1 : backlogged.ordinal());
            tag.putLong("rngSeed", seed);
            tag.putInt("timeInWorld", timeInWorld);
            return tag;
        }

        static PipeItem read(CompoundTag tag) {
            PipeItem item = new PipeItem(ItemStack.of(tag), Direction.values()[tag.getInt("incomingFace")],
                    tag.getLong("rngSeed"));
            item.ticks = tag.getInt("ticksInPipe");
            item.outgoing = Direction.values()[tag.getInt("outgoingFace")];
            item.timeInWorld = tag.getInt("timeInWorld");
            int b = tag.getInt("backloggedFace");
            item.backlogged = b == -1 ? null : Direction.values()[b];
            return item;
        }
    }
}
