package warpledge.quarkblocks;

import com.google.gson.JsonObject;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.util.StringRepresentable;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.StateDefinition;
import net.minecraft.world.level.block.state.properties.AttachFace;
import net.minecraft.world.level.block.state.properties.BooleanProperty;
import net.minecraft.world.level.block.state.properties.DirectionProperty;
import net.minecraft.world.level.block.state.properties.DoorHingeSide;
import net.minecraft.world.level.block.state.properties.DoubleBlockHalf;
import net.minecraft.world.level.block.state.properties.EnumProperty;
import net.minecraft.world.level.block.state.properties.Half;
import net.minecraft.world.level.block.state.properties.IntegerProperty;
import net.minecraft.world.level.block.state.properties.Property;
import net.minecraft.world.level.block.state.properties.SlabType;
import net.minecraft.world.level.block.state.properties.StairsShape;
import net.minecraft.world.level.block.state.properties.WallSide;
import net.minecraft.world.level.material.FluidState;
import net.minecraft.world.level.material.Fluids;
import net.minecraft.world.phys.shapes.CollisionContext;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;

/**
 * A decorative block whose properties come from blocks.json, for Quark blocks with no
 * vanilla class or port of their own: pipes, rods, potted plants and the machines kept
 * for their look. It holds the states the templates place and does nothing else.
 */
public class PropsBlock extends Block {
    // createBlockStateDefinition runs inside Block's constructor, before fields are set.
    private static final ThreadLocal<List<Property<?>>> PENDING = new ThreadLocal<>();
    private static final List<Class<? extends Enum<?>>> ENUMS = List.of(Direction.Axis.class,
            Half.class, DoubleBlockHalf.class, AttachFace.class, StairsShape.class,
            DoorHingeSide.class, SlabType.class, WallSide.class, Token.class);

    private final String shape;

    static PropsBlock create(JsonObject spec, Properties props) {
        List<Property<?>> list = new ArrayList<>();
        JsonObject p = spec.getAsJsonObject("props");
        for (String name : p.keySet()) list.add(property(name, Set.copyOf(QuarkBlocks.strings(p.getAsJsonArray(name)))));
        PENDING.set(list);
        String shape = spec.has("shape") ? spec.get("shape").getAsString() : "full";
        try {
            return spec.get("kind").getAsString().equals("keeper")
                    ? new Keeper(props, shape, spec.get("id").getAsString())
                    : new PropsBlock(props, shape);
        } finally {
            PENDING.remove();
        }
    }

    /** A look-only machine whose block entity keeps the template's data (KeeperBlockEntity). */
    static final class Keeper extends PropsBlock implements EntityBlock {
        private final String id;

        private Keeper(Properties props, String shape, String id) {
            super(props, shape);
            this.id = id;
        }

        @Override
        public BlockEntity newBlockEntity(BlockPos pos, BlockState state) {
            return new KeeperBlockEntity(QuarkBlocks.KEEPERS.get(id).get(), pos, state);
        }

        @Override
        public void onRemove(BlockState state, Level level, BlockPos pos, BlockState newState, boolean moving) {
            if (!state.is(newState.getBlock()) && level.getBlockEntity(pos) instanceof KeeperBlockEntity k) {
                k.dropItems(level, pos);
            }
            super.onRemove(state, level, pos, newState, moving);
        }
    }

    private PropsBlock(Properties props, String shape) {
        super(props);
        this.shape = shape;
        BlockState def = stateDefinition.any();
        for (Property<?> prop : stateDefinition.getProperties()) def = withQuietDefault(def, prop);
        registerDefaultState(def);
    }

    @Override
    protected void createBlockStateDefinition(StateDefinition.Builder<Block, BlockState> b) {
        b.add(PENDING.get().toArray(Property[]::new));
    }

    /** false, none or the lowest number, so a placed block isn't waterlogged or lit. */
    private static <T extends Comparable<T>> BlockState withQuietDefault(BlockState s, Property<T> prop) {
        for (T v : prop.getPossibleValues()) {
            String n = prop.getName(v);
            if (n.equals("false") || n.equals("none") || n.equals("0") || n.equals("off")) return s.setValue(prop, v);
        }
        return s;
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private static Property<?> property(String name, Set<String> values) {
        if (Set.of("true", "false").containsAll(values)) return BooleanProperty.create(name);
        if (values.stream().allMatch(v -> v.matches("\\d+"))) {
            int[] ints = values.stream().mapToInt(Integer::parseInt).sorted().toArray();
            return IntegerProperty.create(name, ints[0], Math.max(ints[ints.length - 1], ints[0] + 1));
        }
        Set<String> dirs = Arrays.stream(Direction.values()).map(Direction::getSerializedName).collect(Collectors.toSet());
        if (dirs.containsAll(values) && !name.equals("type")) {
            return DirectionProperty.create(name, d -> values.contains(d.getSerializedName()));
        }
        for (Class<? extends Enum<?>> cls : ENUMS) {
            Enum<?>[] all = cls.getEnumConstants();
            Set<String> names = Arrays.stream(all).map(e -> ((StringRepresentable) e).getSerializedName())
                    .collect(Collectors.toSet());
            if (names.containsAll(values)) {
                return EnumProperty.create(name, (Class) cls,
                        e -> values.contains(((StringRepresentable) e).getSerializedName()));
            }
        }
        throw new IllegalArgumentException("no property type for " + name + "=" + values);
    }

    @Override
    public FluidState getFluidState(BlockState state) {
        for (Property<?> p : state.getProperties()) {
            if (p.getName().equals("waterlogged") && Boolean.TRUE.equals(state.getValue(p))) {
                return Fluids.WATER.getSource(false);
            }
        }
        return super.getFluidState(state);
    }

    @Override
    public VoxelShape getShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return switch (shape) {
            case "rod" -> switch (value(state, "facing")) {
                case "east", "west" -> box(0, 6, 6, 16, 10, 10);
                case "north", "south" -> box(6, 6, 0, 10, 10, 16);
                default -> box(6, 0, 6, 10, 16, 10);
            };
            case "pipe" -> box(4, 4, 4, 12, 12, 12);
            case "pot" -> box(5, 0, 5, 11, 6, 11);
            case "thin" -> box(0, 0, 0, 16, 2, 16);
            case "lantern" -> box(5, 0, 5, 11, 9, 11);
            case "cross" -> box(2, 0, 2, 14, 13, 14);
            default -> Shapes.block();
        };
    }

    @Override
    public VoxelShape getCollisionShape(BlockState state, BlockGetter level, BlockPos pos, CollisionContext ctx) {
        return shape.equals("cross") ? Shapes.empty() : getShape(state, level, pos, ctx);
    }

    private static String value(BlockState state, String name) {
        for (Property<?> p : state.getProperties()) {
            if (p.getName().equals(name)) return name(p, state);
        }
        return "";
    }

    private static <T extends Comparable<T>> String name(Property<T> p, BlockState s) {
        return p.getName(s.getValue(p));
    }
}
