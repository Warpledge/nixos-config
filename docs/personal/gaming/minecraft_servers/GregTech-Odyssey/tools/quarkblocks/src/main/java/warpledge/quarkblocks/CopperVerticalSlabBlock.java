package warpledge.quarkblocks;

import java.util.Optional;
import net.minecraft.core.BlockPos;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.item.context.UseOnContext;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.WeatheringCopper;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraftforge.common.ToolAction;
import net.minecraftforge.common.ToolActions;
import net.minecraftforge.registries.RegistryObject;

/**
 * Quark's cut copper vertical slabs (WeatheringCopperVerticalSlabBlock, CC BY-NC-SA 3.0):
 * unwaxed ones age like vanilla copper, an axe scrapes a stage or the wax off, and
 * honeycomb waxes them (QuarkBlocks.waxOn). Siblings are found by id, so gen.py
 * registers the whole family whenever one is used.
 */
public class CopperVerticalSlabBlock extends VerticalSlabBlock implements WeatheringCopper {
    private static final String[] AGES = {"", "exposed_", "weathered_", "oxidized_"};

    private final int age;
    private final boolean waxed;
    private final String base;

    public CopperVerticalSlabBlock(Properties props, String id) {
        super(props);
        waxed = id.startsWith("waxed_");
        String rest = waxed ? id.substring(6) : id;
        int a = 0;
        for (int i = 1; i < AGES.length; i++) if (rest.startsWith(AGES[i])) a = i;
        age = a;
        base = rest.substring(AGES[a].length());
    }

    private Optional<Block> sibling(boolean wax, int a) {
        if (a < 0 || a >= AGES.length) return Optional.empty();
        RegistryObject<Block> b = QuarkBlocks.ALL.get((wax ? "waxed_" : "") + AGES[a] + base);
        return b == null ? Optional.empty() : Optional.of(b.get());
    }

    Optional<BlockState> waxedState(BlockState state) {
        return waxed ? Optional.empty() : sibling(true, age).map(b -> b.withPropertiesOf(state));
    }

    @Override
    public WeatherState getAge() {
        return WeatherState.values()[age];
    }

    @Override
    public Optional<BlockState> getNext(BlockState state) {
        return waxed ? Optional.empty() : sibling(false, age + 1).map(b -> b.withPropertiesOf(state));
    }

    @Override
    public boolean isRandomlyTicking(BlockState state) {
        return !waxed && age < AGES.length - 1;
    }

    @Override
    public void randomTick(BlockState state, ServerLevel level, BlockPos pos, RandomSource random) {
        onRandomTick(state, level, pos, random);
    }

    @Override
    public BlockState getToolModifiedState(BlockState state, UseOnContext ctx, ToolAction action, boolean simulate) {
        if (action == ToolActions.AXE_WAX_OFF && waxed) {
            return sibling(false, age).map(b -> b.withPropertiesOf(state)).orElse(null);
        }
        if (action == ToolActions.AXE_SCRAPE && !waxed) {
            return sibling(false, age - 1).map(b -> b.withPropertiesOf(state)).orElse(null);
        }
        return super.getToolModifiedState(state, ctx, action, simulate);
    }
}
