package warpledge.quarkblocks;

import com.google.gson.JsonObject;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.level.block.AmethystClusterBlock;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.ButtonBlock;
import net.minecraft.world.level.block.CarpetBlock;
import net.minecraft.world.level.block.DoorBlock;
import net.minecraft.world.level.block.FenceBlock;
import net.minecraft.world.level.block.FenceGateBlock;
import net.minecraft.world.level.block.GlassBlock;
import net.minecraft.world.level.block.IronBarsBlock;
import net.minecraft.world.level.block.LadderBlock;
import net.minecraft.world.level.block.LeavesBlock;
import net.minecraft.world.level.block.PressurePlateBlock;
import net.minecraft.world.level.block.RotatedPillarBlock;
import net.minecraft.world.level.block.SlabBlock;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.StairBlock;
import net.minecraft.world.level.block.TrapDoorBlock;
import net.minecraft.world.level.block.WallBlock;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.world.level.block.state.properties.BlockSetType;
import net.minecraft.world.level.block.state.properties.WoodType;
import net.minecraftforge.registries.ForgeRegistries;

/** Builds one block from its blocks.json entry; gen.py picks the kind. */
final class BlockFactory {
    private BlockFactory() {}

    static Block create(JsonObject spec) {
        Block base = ForgeRegistries.BLOCKS.getValue(new ResourceLocation(spec.get("copy").getAsString()));
        if (base == null) throw new IllegalArgumentException("unknown copy block in " + spec);
        BlockBehaviour.Properties p = BlockBehaviour.Properties.copy(base);
        int light = spec.has("light") ? spec.get("light").getAsInt() : 0;
        if (light > 0) {
            // A block with a lit property is only bright when lit (Quark's crystal lamps).
            boolean litOnly = spec.has("props") && spec.getAsJsonObject("props").has("lit");
            p = p.lightLevel(s -> !litOnly || s.getProperties().stream()
                    .anyMatch(q -> q.getName().equals("lit") && Boolean.TRUE.equals(s.getValue(q))) ? light : 0);
        }
        if (spec.has("see_through") && spec.get("see_through").getAsBoolean()) p = p.noOcclusion();
        String set = spec.has("set") ? spec.get("set").getAsString() : "oak";
        return switch (spec.get("kind").getAsString()) {
            case "cube" -> new Block(p);
            case "glass" -> new GlassBlock(p.noOcclusion());
            case "slab" -> new SlabBlock(p);
            case "stairs" -> new StairBlock(base::defaultBlockState, p);
            case "wall" -> new WallBlock(p);
            case "pane" -> new IronBarsBlock(p.noOcclusion());
            case "fence" -> new FenceBlock(p);
            case "fence_gate" -> new FenceGateBlock(p, wood(set));
            case "pillar" -> new RotatedPillarBlock(p);
            case "ladder" -> new LadderBlock(p.noOcclusion());
            case "leaves" -> new LeavesBlock(p.noOcclusion());
            case "carpet" -> new CarpetBlock(p);
            case "door" -> new DoorBlock(p.noOcclusion(), blockSet(set));
            case "trapdoor" -> new TrapDoorBlock(p.noOcclusion(), blockSet(set));
            case "button" -> new ButtonBlock(p.noCollission(), blockSet(set), 30, set.equals("oak"));
            case "pressure_plate" -> new PressurePlateBlock(
                    PressurePlateBlock.Sensitivity.MOBS, p.noCollission(), blockSet(set));
            case "cluster" -> new AmethystClusterBlock(7, 3, p.noOcclusion());
            case "hedge" -> new HedgeBlock(p);
            case "post" -> new WoodPostBlock(p);
            case "vertical_slab" -> spec.has("copper")
                    ? new CopperVerticalSlabBlock(p, spec.get("id").getAsString())
                    : new VerticalSlabBlock(p);
            case "stool" -> new StoolBlock(p.sound(SoundType.WOOD).strength(0.2F).noOcclusion());
            case "leaf_carpet" -> new LeafCarpetBlock(base.defaultMapColor());
            case "monster_box" -> new MonsterBoxBlock(p.noOcclusion());
            case "props" -> PropsBlock.create(spec, p.noOcclusion());
            default -> throw new IllegalArgumentException("unknown kind in " + spec);
        };
    }

    private static BlockSetType blockSet(String name) {
        return switch (name) {
            case "cherry" -> BlockSetType.CHERRY;
            case "bamboo" -> BlockSetType.BAMBOO;
            case "iron" -> BlockSetType.IRON;
            case "gold" -> BlockSetType.GOLD;
            case "stone" -> BlockSetType.STONE;
            case "polished_blackstone" -> BlockSetType.POLISHED_BLACKSTONE;
            case "crimson" -> BlockSetType.CRIMSON;
            case "warped" -> BlockSetType.WARPED;
            default -> BlockSetType.OAK;
        };
    }

    private static WoodType wood(String name) {
        return switch (name) {
            case "cherry" -> WoodType.CHERRY;
            case "bamboo" -> WoodType.BAMBOO;
            case "crimson", "polished_blackstone", "stone" -> WoodType.CRIMSON;
            case "warped" -> WoodType.WARPED;
            default -> WoodType.OAK;
        };
    }
}
