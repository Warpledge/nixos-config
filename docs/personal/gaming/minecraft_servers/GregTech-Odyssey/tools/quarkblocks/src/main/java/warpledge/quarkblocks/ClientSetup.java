package warpledge.quarkblocks;

import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.client.renderer.RenderType;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;

/** Render layers from blocks.json; Quark set them in code, so its models don't. */
final class ClientSetup {
    private ClientSetup() {}

    static void register(IEventBus bus) {
        bus.addListener(ClientSetup::setup);
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
}
