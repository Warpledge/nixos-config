package warpledge.quarkblocks;

import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.core.BlockPos;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraftforge.client.event.EntityRenderersEvent;
import net.minecraftforge.client.event.RegisterColorHandlersEvent;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;
import net.minecraftforge.registries.ForgeRegistries;

/** Render layers and tints from blocks.json (Quark set both in code), and the stool seat. */
final class ClientSetup {
    private ClientSetup() {}

    static void register(IEventBus bus) {
        bus.addListener(ClientSetup::setup);
        bus.addListener(ClientSetup::blockColors);
        bus.addListener(ClientSetup::itemColors);
        bus.addListener(ClientSetup::renderers);
    }

    @SuppressWarnings("removal") // still the 1.20.1 way for blocks whose models don't say
    private static void setup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> QuarkBlocks.RENDER.forEach((id, layer) -> {
            RenderType type = switch (layer) {
                case "cutout" -> RenderType.cutout();
                case "cutout_mipped" -> RenderType.cutoutMipped();
                case "translucent" -> RenderType.translucent();
                default -> RenderType.solid();
            };
            ItemBlockRenderTypes.setRenderLayer(QuarkBlocks.ALL.get(id).get(), type);
        }));
    }

    /** "myalite", or the block whose colour this one copies (Zeta's AlikeColorHandler). */
    private static void blockColors(RegisterColorHandlersEvent.Block event) {
        QuarkBlocks.TINT.forEach((id, src) -> {
            Block block = QuarkBlocks.ALL.get(id).get();
            if (src.equals("myalite")) {
                event.register((s, level, pos, i) -> MyaliteColor.at(pos), block);
            } else {
                event.register((s, level, pos, i) -> {
                    Block like = ForgeRegistries.BLOCKS.getValue(new ResourceLocation(src));
                    return like == null ? -1 : event.getBlockColors().getColor(like.defaultBlockState(), level, pos, i);
                }, block);
            }
        });
    }

    private static void itemColors(RegisterColorHandlersEvent.Item event) {
        QuarkBlocks.TINT.forEach((id, src) -> {
            Block block = QuarkBlocks.ALL.get(id).get();
            if (src.equals("myalite")) {
                event.register((stack, i) -> MyaliteColor.at(lookedAt()), block);
            } else {
                event.register((stack, i) -> {
                    Block like = ForgeRegistries.BLOCKS.getValue(new ResourceLocation(src));
                    return like == null ? -1 : event.getItemColors().getColor(new ItemStack(like), i);
                }, block);
            }
        });
    }

    private static BlockPos lookedAt() {
        Minecraft mc = Minecraft.getInstance();
        if (mc.player == null) return BlockPos.ZERO;
        return mc.hitResult instanceof BlockHitResult hit ? hit.getBlockPos() : mc.player.blockPosition();
    }

    private static void renderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(QuarkBlocks.STOOL.get(), Invisible::new);
    }

    /** Draws nothing; for the stool seat. */
    private static final class Invisible extends EntityRenderer<StoolEntity> {
        Invisible(EntityRendererProvider.Context ctx) {
            super(ctx);
        }

        @Override
        public ResourceLocation getTextureLocation(StoolEntity entity) {
            return null;
        }
    }
}
