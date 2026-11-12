package warpledge.quarkblocks;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;
import net.minecraftforge.fml.loading.FMLEnvironment;
import net.minecraftforge.registries.DeferredRegister;
import net.minecraftforge.registries.ForgeRegistries;
import net.minecraftforge.registries.RegistryObject;

/** Registers the blocks gen.py listed in blocks.json; see BlockFactory for each kind. */
@Mod(QuarkBlocks.ID)
public class QuarkBlocks {
    public static final String ID = "quarkblocks";

    static final DeferredRegister<Block> BLOCKS =
            DeferredRegister.create(ForgeRegistries.BLOCKS, ID);
    static final DeferredRegister<Item> ITEMS = DeferredRegister.create(ForgeRegistries.ITEMS, ID);
    static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES =
            DeferredRegister.create(ForgeRegistries.BLOCK_ENTITY_TYPES, ID);
    static final DeferredRegister<SoundEvent> SOUNDS =
            DeferredRegister.create(ForgeRegistries.SOUND_EVENTS, ID);
    static final DeferredRegister<CreativeModeTab> TABS =
            DeferredRegister.create(Registries.CREATIVE_MODE_TAB, ID);

    static final Map<String, RegistryObject<Block>> ALL = new LinkedHashMap<>();
    static final Map<String, String> RENDER = new LinkedHashMap<>();

    public static final RegistryObject<SoundEvent> MONSTER_BOX_GROWL = SOUNDS.register(
            "block.monster_box.growl",
            () -> SoundEvent.createVariableRangeEvent(rl("block.monster_box.growl")));
    public static RegistryObject<BlockEntityType<MonsterBoxBlockEntity>> MONSTER_BOX_BE;

    public QuarkBlocks() {
        IEventBus bus = FMLJavaModLoadingContext.get().getModEventBus();
        for (JsonElement e : readSpec()) {
            JsonObject spec = e.getAsJsonObject();
            String id = spec.get("id").getAsString();
            RegistryObject<Block> block = BLOCKS.register(id, () -> BlockFactory.create(spec));
            ALL.put(id, block);
            ITEMS.register(id, () -> new BlockItem(block.get(), new Item.Properties()));
            if (spec.has("render")) RENDER.put(id, spec.get("render").getAsString());
            if ("monster_box".equals(spec.get("kind").getAsString())) {
                MONSTER_BOX_BE = BLOCK_ENTITIES.register(id, () ->
                        BlockEntityType.Builder.of(MonsterBoxBlockEntity::new, block.get())
                                .build(null));
            }
        }
        TABS.register("blocks", () -> CreativeModeTab.builder()
                .title(Component.literal("Quark Blocks"))
                .icon(() -> new ItemStack(ALL.values().iterator().next().get()))
                .displayItems((params, out) -> ALL.values().forEach(b -> out.accept(b.get())))
                .build());

        BLOCKS.register(bus);
        ITEMS.register(bus);
        BLOCK_ENTITIES.register(bus);
        SOUNDS.register(bus);
        TABS.register(bus);
        MinecraftForge.EVENT_BUS.register(MonsterBoxBlockEntity.Drops.class);
        // A separate class, so a dedicated server never loads the client classes.
        if (FMLEnvironment.dist.isClient()) ClientSetup.register(bus);
    }

    static ResourceLocation rl(String path) {
        return new ResourceLocation(ID, path);
    }

    private static JsonArray readSpec() {
        var in = QuarkBlocks.class.getResourceAsStream("/quarkblocks/blocks.json");
        if (in == null) throw new IllegalStateException("blocks.json missing; run gen.py");
        return new Gson().fromJson(new InputStreamReader(in, StandardCharsets.UTF_8), JsonArray.class);
    }

    static List<String> strings(JsonArray a) {
        List<String> out = new ArrayList<>();
        a.forEach(x -> out.add(x.getAsString()));
        return out;
    }
}
