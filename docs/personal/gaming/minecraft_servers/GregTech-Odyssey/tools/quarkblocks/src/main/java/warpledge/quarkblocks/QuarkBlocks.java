package warpledge.quarkblocks;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import java.io.InputStreamReader;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import net.minecraft.world.entity.ai.village.poi.PoiType;
import net.minecraft.world.inventory.DispenserMenu;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.SignItem;
import net.minecraft.world.level.block.state.properties.BlockSetType;
import net.minecraft.world.level.block.state.properties.WoodType;
import net.minecraftforge.common.extensions.IForgeMenuType;
import net.minecraftforge.fml.event.lifecycle.FMLCommonSetupEvent;
import net.minecraft.advancements.CriteriaTriggers;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.Registries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.MobCategory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTab;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.gameevent.GameEvent;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.event.entity.player.PlayerInteractEvent;
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

    static final DeferredRegister<EntityType<?>> ENTITIES =
            DeferredRegister.create(ForgeRegistries.ENTITY_TYPES, ID);
    static final DeferredRegister<MenuType<?>> MENUS = DeferredRegister.create(ForgeRegistries.MENU_TYPES, ID);
    static final DeferredRegister<PoiType> POIS = DeferredRegister.create(ForgeRegistries.POI_TYPES, ID);

    static final Map<String, RegistryObject<Block>> ALL = new LinkedHashMap<>();
    static final Map<String, RegistryObject<Item>> ALL_ITEMS = new LinkedHashMap<>();
    static final Map<String, String> RENDER = new LinkedHashMap<>();
    static final Map<String, String> TINT = new LinkedHashMap<>();
    // Blocks of each kind, for the block entity types below; filled before registration.
    private static final Map<String, List<RegistryObject<Block>>> BY_KIND = new LinkedHashMap<>();
    private static final Map<String, WoodType> WOODS = new LinkedHashMap<>();

    // Ids are Quark's, so the templates' block entity data (renamed by libgate) loads.
    public static final RegistryObject<BlockEntityType<VariantChestBlockEntity>> CHEST_BE =
            BLOCK_ENTITIES.register("variant_chest", () -> BlockEntityType.Builder.of(
                    VariantChestBlockEntity::new, blocks("chest")).build(null));
    public static final RegistryObject<BlockEntityType<VariantChestBlockEntity.Trapped>> TRAPPED_CHEST_BE =
            BLOCK_ENTITIES.register("variant_trapped_chest", () -> BlockEntityType.Builder.of(
                    VariantChestBlockEntity.Trapped::new, blocks("trapped_chest")).build(null));
    public static final RegistryObject<BlockEntityType<VariantFurnaceBlock.Entity>> FURNACE_BE =
            BLOCK_ENTITIES.register("variant_furnace", () -> BlockEntityType.Builder.of(
                    VariantFurnaceBlock.Entity::new, blocks("furnace")).build(null));
    public static final RegistryObject<BlockEntityType<CrateBlockEntity>> CRATE_BE =
            BLOCK_ENTITIES.register("crate", () -> BlockEntityType.Builder.of(
                    CrateBlockEntity::new, blocks("crate")).build(null));
    public static final RegistryObject<MenuType<CrateMenu>> CRATE_MENU =
            MENUS.register("crate", () -> IForgeMenuType.create(CrateMenu::fromNetwork));
    public static final RegistryObject<BlockEntityType<FeedingTroughBlockEntity>> TROUGH_BE =
            BLOCK_ENTITIES.register("feeding_trough", () -> BlockEntityType.Builder.of(
                    FeedingTroughBlockEntity::new, blocks("feeding_trough")).build(null));
    public static final RegistryObject<MenuType<DispenserMenu>> TROUGH_MENU = MENUS.register("feeding_trough",
            () -> IForgeMenuType.create((id, inv, buf) -> new DispenserMenu(id, inv)));
    public static final RegistryObject<PoiType> TROUGH_POI = POIS.register("feeding_trough",
            () -> new PoiType(Set.copyOf(Arrays.stream(blocks("feeding_trough"))
                    .flatMap(b -> b.getStateDefinition().getPossibleStates().stream()).toList()), 1, 32));
    public static final RegistryObject<BlockEntityType<EnderWatcherBlock.Entity>> WATCHER_BE =
            BLOCK_ENTITIES.register("ender_watcher", () -> BlockEntityType.Builder.of(
                    EnderWatcherBlock.Entity::new, blocks("ender_watcher")).build(null));
    public static final RegistryObject<BlockEntityType<ChuteBlock.Entity>> CHUTE_BE =
            BLOCK_ENTITIES.register("chute", () -> BlockEntityType.Builder.of(
                    ChuteBlock.Entity::new, blocks("chute")).build(null));
    public static final RegistryObject<BlockEntityType<PipeBlockEntity>> PIPE_BE =
            BLOCK_ENTITIES.register("pipe", () -> BlockEntityType.Builder.of(
                    PipeBlockEntity::new, blocks("pipe")).build(null));
    public static final RegistryObject<SoundEvent> PIPE_PICKUP = sound("block.pipe.pickup");
    public static final RegistryObject<SoundEvent> PIPE_SHOOT = sound("block.pipe.shoot");
    public static final RegistryObject<BlockEntityType<CloudBlock.Entity>> CLOUD_BE =
            BLOCK_ENTITIES.register("cloud", () -> BlockEntityType.Builder.of(
                    CloudBlock.Entity::new, blocks("cloud")).build(null));
    public static final RegistryObject<EntityType<ParrotEgg>> PARROT_EGG = ENTITIES.register("parrot_egg",
            () -> EntityType.Builder.<ParrotEgg>of(ParrotEgg::new, MobCategory.MISC).sized(0.4F, 0.4F)
                    .clientTrackingRange(64).updateInterval(10).build("parrot_egg"));
    public static final RegistryObject<EntityType<Pickarang>> PICKARANG = ENTITIES.register("pickarang",
            () -> EntityType.Builder.<Pickarang>of(Pickarang::new, MobCategory.MISC).sized(0.4F, 0.4F)
                    .clientTrackingRange(4).updateInterval(10).build("pickarang"));
    public static final RegistryObject<EntityType<TorchArrow>> TORCH_ARROW = ENTITIES.register("torch_arrow",
            () -> EntityType.Builder.<TorchArrow>of(TorchArrow::new, MobCategory.MISC).sized(0.5F, 0.5F)
                    .clientTrackingRange(4).updateInterval(20).build("torch_arrow"));
    public static final RegistryObject<EntityType<SoulBead>> SOUL_BEAD = ENTITIES.register("soul_bead",
            () -> EntityType.Builder.<SoulBead>of(SoulBead::new, MobCategory.MISC).sized(0F, 0F)
                    .clientTrackingRange(8).updateInterval(128).fireImmune().build("soul_bead"));
    static final DeferredRegister<RecipeSerializer<?>> RECIPES =
            DeferredRegister.create(ForgeRegistries.RECIPE_SERIALIZERS, ID);
    public static final RegistryObject<RecipeSerializer<Runes.Recipe>> RUNE_RECIPE =
            RECIPES.register("smithing_rune", Runes.Serializer::new);
    static final Map<String, RegistryObject<SoundEvent>> SOUND_BY_NAME = new LinkedHashMap<>();
    // One block entity type per look-only machine, named after it (Quark's ids).
    static final Map<String, RegistryObject<BlockEntityType<KeeperBlockEntity>>> KEEPERS = new LinkedHashMap<>();

    public static final RegistryObject<EntityType<StoolEntity>> STOOL = ENTITIES.register("stool",
            () -> EntityType.Builder.<StoolEntity>of(StoolEntity::new, MobCategory.MISC)
                    .sized(6F / 16F, 0.5F).clientTrackingRange(3).updateInterval(Integer.MAX_VALUE)
                    .setShouldReceiveVelocityUpdates(false).build("stool"));

    public static final RegistryObject<SoundEvent> MONSTER_BOX_GROWL = SOUNDS.register(
            "block.monster_box.growl",
            () -> SoundEvent.createVariableRangeEvent(rl("block.monster_box.growl")));
    public static RegistryObject<BlockEntityType<MonsterBoxBlockEntity>> MONSTER_BOX_BE;

    public QuarkBlocks() {
        IEventBus bus = FMLJavaModLoadingContext.get().getModEventBus();
        for (JsonElement e : readSpec("items.json")) {
            JsonObject spec = e.getAsJsonObject();
            String id = spec.get("id").getAsString();
            // Sounds must be registered now; the items themselves are built later.
            if (spec.has("sounds")) {
                for (String s : strings(spec.getAsJsonArray("sounds"))) SOUND_BY_NAME.computeIfAbsent(s, QuarkBlocks::sound);
            }
            ALL_ITEMS.put(id, ITEMS.register(id, () -> ItemFactory.create(spec)));
        }
        for (JsonElement e : readSpec("blocks.json")) {
            JsonObject spec = e.getAsJsonObject();
            String id = spec.get("id").getAsString();
            String kind = spec.get("kind").getAsString();
            RegistryObject<Block> block = BLOCKS.register(id, () -> BlockFactory.create(spec));
            ALL.put(id, block);
            BY_KIND.computeIfAbsent(kind, k -> new ArrayList<>()).add(block);
            // A wall sign has no item of its own; its standing sign's item places both.
            switch (kind) {
                case "wall_sign" -> {}
                case "sign" -> ALL_ITEMS.put(id, ITEMS.register(id, () -> new SignItem(
                        new Item.Properties().stacksTo(16), block.get(),
                        ALL.get(spec.get("wood").getAsString() + "_wall_sign").get())));
                case "chest", "trapped_chest" -> ALL_ITEMS.put(id, ITEMS.register(id,
                        () -> new ChestItem(block.get(), new Item.Properties())));
                default -> ALL_ITEMS.put(id, ITEMS.register(id,
                        () -> new BlockItem(block.get(), new Item.Properties())));
            }
            if (spec.has("render")) RENDER.put(id, spec.get("render").getAsString());
            if (spec.has("tint")) TINT.put(id, spec.get("tint").getAsString());
            if ("keeper".equals(kind)) {
                KEEPERS.put(id, BLOCK_ENTITIES.register(id, () -> BlockEntityType.Builder.<KeeperBlockEntity>of(
                        (pos, state) -> new KeeperBlockEntity(KEEPERS.get(id).get(), pos, state), block.get())
                        .build(null)));
            }
            if ("monster_box".equals(kind)) {
                MONSTER_BOX_BE = BLOCK_ENTITIES.register(id, () ->
                        BlockEntityType.Builder.of(MonsterBoxBlockEntity::new, block.get())
                                .build(null));
            }
        }
        TABS.register("blocks", () -> CreativeModeTab.builder()
                .title(Component.literal("Quark Blocks"))
                .icon(() -> new ItemStack(ALL_ITEMS.values().iterator().next().get()))
                .displayItems((params, out) -> ALL_ITEMS.values().forEach(i -> out.accept(i.get())))
                .build());

        BLOCKS.register(bus);
        ITEMS.register(bus);
        BLOCK_ENTITIES.register(bus);
        SOUNDS.register(bus);
        ENTITIES.register(bus);
        MENUS.register(bus);
        POIS.register(bus);
        TABS.register(bus);
        bus.addListener(QuarkBlocks::commonSetup);
        MinecraftForge.EVENT_BUS.register(MonsterBoxBlockEntity.Drops.class);
        MinecraftForge.EVENT_BUS.register(TroughFeeding.class);
        MinecraftForge.EVENT_BUS.register(QuarkItems.class);
        MinecraftForge.EVENT_BUS.register(SeedPouchItem.class);
        MinecraftForge.EVENT_BUS.register(AncientTomeItem.class);
        MinecraftForge.EVENT_BUS.register(Runes.class);
        RECIPES.register(bus);
        MinecraftForge.EVENT_BUS.addListener(QuarkBlocks::rightClickBlock);
        // A separate class, so a dedicated server never loads the client classes.
        if (FMLEnvironment.dist.isClient()) {
            ClientSetup.register(bus);
            ClientItems.register(bus);
        }
    }

    /**
     * Shift-placing a block on a stool's top makes it tall first (Quark's StoolsModule);
     * honeycomb waxes a copper vertical slab, which vanilla's HoneycombItem only does for
     * its own blocks.
     */
    private static void rightClickBlock(PlayerInteractEvent.RightClickBlock event) {
        Level level = event.getLevel();
        BlockPos pos = event.getPos();
        BlockState state = level.getBlockState(pos);
        ItemStack stack = event.getItemStack();
        if (state.getBlock() instanceof StoolBlock stool && event.getEntity().isShiftKeyDown()
                && stack.getItem() instanceof BlockItem && event.getFace() == Direction.UP) {
            stool.blockClicked(level, pos);
        } else if (state.getBlock() instanceof CopperVerticalSlabBlock copper && stack.is(Items.HONEYCOMB)) {
            copper.waxedState(state).ifPresent(waxed -> {
                Player player = event.getEntity();
                if (player instanceof ServerPlayer sp) CriteriaTriggers.ITEM_USED_ON_BLOCK.trigger(sp, pos, stack);
                if (!player.getAbilities().instabuild) stack.shrink(1);
                level.setBlock(pos, waxed, Block.UPDATE_ALL_IMMEDIATE);
                level.gameEvent(GameEvent.BLOCK_CHANGE, pos, GameEvent.Context.of(player, waxed));
                level.levelEvent(player, 3003, pos, 0);
                event.setCanceled(true);
                event.setCancellationResult(InteractionResult.sidedSuccess(level.isClientSide));
            });
        }
    }

    static RegistryObject<SoundEvent> sound(String name) {
        return SOUNDS.register(name, () -> SoundEvent.createVariableRangeEvent(rl(name)));
    }

    private static Block[] blocks(String kind) {
        return BY_KIND.getOrDefault(kind, List.of()).stream().map(RegistryObject::get).toArray(Block[]::new);
    }

    /** Quark's own wood types (quarkblocks:blossom); sign faces at entity/signs/<wood>. */
    static synchronized WoodType woodType(JsonObject spec) {
        return WOODS.computeIfAbsent(spec.get("wood").getAsString(),
                w -> WoodType.register(new WoodType(ID + ":" + w, BlockSetType.OAK)));
    }

    static Collection<WoodType> woodTypes() {
        return WOODS.values();
    }

    private static void commonSetup(FMLCommonSetupEvent event) {
        Network.register();
        // Vanilla's sign block entity type only accepts vanilla signs; Zeta adds its own
        // the same way.
        event.enqueueWork(() -> {
            addValidBlocks(BlockEntityType.SIGN, blocks("sign"), blocks("wall_sign"));
            TorchArrow.registerDispenser();
        });
    }

    @SuppressWarnings("unchecked")
    private static void addValidBlocks(BlockEntityType<?> type, Block[]... extra) {
        for (Field f : BlockEntityType.class.getDeclaredFields()) {
            if (f.getType() != Set.class || Modifier.isStatic(f.getModifiers())) continue;
            try {
                f.setAccessible(true);
                Set<Block> valid = new HashSet<>((Set<Block>) f.get(type));
                for (Block[] bs : extra) valid.addAll(List.of(bs));
                f.set(type, valid);
                return;
            } catch (ReflectiveOperationException e) {
                throw new IllegalStateException("can't extend " + type, e);
            }
        }
        throw new IllegalStateException("no valid-blocks set in BlockEntityType");
    }

    static ResourceLocation rl(String path) {
        return new ResourceLocation(ID, path);
    }

    private static JsonArray readSpec(String file) {
        var in = QuarkBlocks.class.getResourceAsStream("/quarkblocks/" + file);
        if (in == null) throw new IllegalStateException(file + " missing; run gen.py");
        return new Gson().fromJson(new InputStreamReader(in, StandardCharsets.UTF_8), JsonArray.class);
    }

    static List<String> strings(JsonArray a) {
        List<String> out = new ArrayList<>();
        a.forEach(x -> out.add(x.getAsString()));
        return out;
    }
}
