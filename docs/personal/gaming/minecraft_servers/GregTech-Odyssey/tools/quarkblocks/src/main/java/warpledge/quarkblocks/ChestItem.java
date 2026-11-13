package warpledge.quarkblocks;

import java.util.function.Consumer;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.BlockEntityWithoutLevelRenderer;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.level.block.Block;
import net.minecraftforge.client.extensions.common.IClientItemExtensions;

/** A chest's item, drawn as its chest model (its item model is builtin/entity). */
public class ChestItem extends BlockItem {
    public ChestItem(Block block, Properties props) {
        super(block, props);
    }

    @Override
    public void initializeClient(Consumer<IClientItemExtensions> consumer) {
        consumer.accept(new IClientItemExtensions() {
            private BlockEntityWithoutLevelRenderer renderer;

            @Override
            public BlockEntityWithoutLevelRenderer getCustomRenderer() {
                if (renderer == null) {
                    Minecraft mc = Minecraft.getInstance();
                    renderer = new ClientSetup.ChestItemRenderer(mc, getBlock());
                }
                return renderer;
            }
        });
    }
}
