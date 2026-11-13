package warpledge.quarkblocks;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.screens.MenuScreens;
import net.minecraft.client.gui.screens.inventory.DispenserScreen;
import net.minecraft.client.renderer.block.BlockRenderDispatcher;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.entity.ItemRenderer;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.resources.model.BakedModel;
import net.minecraft.client.resources.model.ModelResourceLocation;
import net.minecraft.core.Direction;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.DispenserMenu;
import net.minecraft.world.item.Item;
import net.minecraftforge.client.event.ModelEvent;
import net.minecraft.client.renderer.BlockEntityWithoutLevelRenderer;
import net.minecraft.client.renderer.ItemBlockRenderTypes;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.Sheets;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.blockentity.ChestRenderer;
import net.minecraft.client.resources.model.Material;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.level.block.EntityBlock;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.ChestBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.state.properties.ChestType;
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

/**
 * Render layers and tints from blocks.json (Quark set both in code), chest and sign
 * textures, the crate screen and the stool seat.
 */
final class ClientSetup {
    private ClientSetup() {}

    static void register(IEventBus bus) {
        bus.addListener(ClientSetup::setup);
        bus.addListener(ClientSetup::blockColors);
        bus.addListener(ClientSetup::itemColors);
        bus.addListener(ClientSetup::renderers);
        bus.addListener(ClientSetup::extraModels);
    }

    @SuppressWarnings("removal") // still the 1.20.1 way for blocks whose models don't say
    private static void setup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> {
            QuarkBlocks.RENDER.forEach((id, layer) -> {
                RenderType type = switch (layer) {
                    case "cutout" -> RenderType.cutout();
                    case "cutout_mipped" -> RenderType.cutoutMipped();
                    case "translucent" -> RenderType.translucent();
                    default -> RenderType.solid();
                };
                ItemBlockRenderTypes.setRenderLayer(QuarkBlocks.ALL.get(id).get(), type);
            });
            QuarkBlocks.woodTypes().forEach(Sheets::addWoodType);
            MenuScreens.register(QuarkBlocks.CRATE_MENU.get(), CrateScreen::new);
            MenuScreens.register(QuarkBlocks.TROUGH_MENU.get(), TroughScreen::new);
        });
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
        event.registerBlockEntityRenderer(QuarkBlocks.CHEST_BE.get(), ChestTextures::new);
        event.registerBlockEntityRenderer(QuarkBlocks.TRAPPED_CHEST_BE.get(), ChestTextures::new);
        event.registerBlockEntityRenderer(QuarkBlocks.PIPE_BE.get(), PipeRenderer::new);
    }

    private static void extraModels(ModelEvent.RegisterAdditional event) {
        event.register(PipeRenderer.FLARE);
    }

    /**
     * Items moving through a pipe and the flared ends (Quark's PipeRenderer, CC BY-NC-SA 3.0).
     */
    private static final class PipeRenderer implements BlockEntityRenderer<PipeBlockEntity> {
        static final ModelResourceLocation FLARE =
                new ModelResourceLocation(QuarkBlocks.rl("extra/pipe_flare"), "inventory");
        private final Random random = new Random();

        PipeRenderer(BlockEntityRendererProvider.Context ctx) {}

        @Override
        public void render(PipeBlockEntity pipe, float partial, PoseStack pose, MultiBufferSource buffers, int light,
                int overlay) {
            pose.pushPose();
            pose.translate(0.5, 0.5, 0.5);
            ItemRenderer items = Minecraft.getInstance().getItemRenderer();
            for (PipeBlockEntity.PipeItem item : pipe.items) renderItem(item, items, pose, buffers, partial, light, overlay, pipe);
            BlockRenderDispatcher blocks = Minecraft.getInstance().getBlockRenderer();
            BakedModel flare = blocks.getBlockModelShaper().getModelManager().getModel(FLARE);
            for (Direction d : Direction.values()) {
                PipeBlockEntity.Connection c = pipe.connection(d);
                if (!c.flared) continue;
                pose.pushPose();
                switch (d.getAxis()) {
                    case X -> pose.mulPose(Axis.YP.rotationDegrees(-d.toYRot()));
                    case Z -> pose.mulPose(Axis.YP.rotationDegrees(d.toYRot()));
                    case Y -> {
                        pose.mulPose(Axis.XP.rotationDegrees(90F));
                        if (d == Direction.UP) pose.mulPose(Axis.YP.rotationDegrees(180F));
                    }
                }
                pose.translate(-0.5, -0.5, c.flareShift);
                blocks.getModelRenderer().renderModel(pose.last(), buffers.getBuffer(Sheets.cutoutBlockSheet()), null,
                        flare, 1F, 1F, 1F, light, OverlayTexture.NO_OVERLAY);
                pose.popPose();
            }
            pose.popPose();
        }

        private void renderItem(PipeBlockEntity.PipeItem item, ItemRenderer items, PoseStack pose,
                MultiBufferSource buffers, float partial, int light, int overlay, PipeBlockEntity pipe) {
            pose.pushPose();
            float fract = item.fraction(partial);
            Direction face = fract < 0.5 ? item.incoming.getOpposite() : item.outgoing;
            float shift = fract - 0.5F;
            pose.translate(face.getStepX() * shift, face.getStepY() * shift, face.getStepZ() * shift);
            pose.scale(0.4F, 0.4F, 0.4F);
            pose.mulPose(Axis.YP.rotationDegrees((item.timeInWorld + partial) * 4F));
            random.setSeed(item.stack.isEmpty() ? 187 : Item.getId(item.stack.getItem()));
            int n = item.stack.getCount();
            int copies = n > 48 ? 5 : n > 32 ? 4 : n > 16 ? 3 : n > 1 ? 2 : 1;
            for (int i = 0; i < copies; i++) {
                pose.pushPose();
                if (i > 0) {
                    pose.translate((random.nextFloat() * 2 - 1) * 0.15F, (random.nextFloat() * 2 - 1) * 0.15F,
                            (random.nextFloat() * 2 - 1) * 0.15F);
                }
                items.renderStatic(item.stack, ItemDisplayContext.FIXED, light, overlay, pose, buffers, pipe.getLevel(), 0);
                pose.popPose();
            }
            pose.popPose();
        }
    }

    /**
     * Quark's chest textures (VariantChestRenderer, CC BY-NC-SA 3.0):
     * quark_variant_chests/<type>/{normal,left,right} or trap, trap_left, trap_right.
     */
    private static final class ChestTextures<T extends ChestBlockEntity> extends ChestRenderer<T> {
        private final Map<String, Material> cache = new HashMap<>();

        ChestTextures(BlockEntityRendererProvider.Context ctx) {
            super(ctx);
        }

        @Override
        protected Material getMaterial(T be, ChestType type) {
            if (!(be.getBlockState().getBlock() instanceof VariantChestBlock chest)) return super.getMaterial(be, type);
            String name = switch (type) {
                case SINGLE -> chest.trapped ? "trap" : "normal";
                case LEFT -> chest.trapped ? "trap_left" : "left";
                case RIGHT -> chest.trapped ? "trap_right" : "right";
            };
            String path = "quark_variant_chests/" + chest.texture + "/" + name;
            return cache.computeIfAbsent(path, p -> new Material(Sheets.CHEST_SHEET, QuarkBlocks.rl(p)));
        }
    }

    /** Draws a chest item as its block entity, as Zeta's SimpleWithoutLevelRenderer does. */
    static final class ChestItemRenderer extends BlockEntityWithoutLevelRenderer {
        private final BlockEntity be;

        ChestItemRenderer(Minecraft mc, Block block) {
            super(mc.getBlockEntityRenderDispatcher(), mc.getEntityModels());
            BlockState state = block.defaultBlockState();
            be = ((EntityBlock) block).newBlockEntity(BlockPos.ZERO, state);
        }

        @Override
        public void renderByItem(ItemStack stack, ItemDisplayContext ctx, PoseStack pose, MultiBufferSource buffers,
                int light, int overlay) {
            Minecraft.getInstance().getBlockEntityRenderDispatcher().renderItem(be, pose, buffers, light, overlay);
        }
    }

    /** The trough's dispenser-like screen with Quark's own background. */
    private static final class TroughScreen extends DispenserScreen {
        private static final ResourceLocation BG = QuarkBlocks.rl("textures/gui/container/feeding_trough.png");

        TroughScreen(DispenserMenu menu, Inventory inv, Component title) {
            super(menu, inv, title);
        }

        @Override
        protected void renderBg(GuiGraphics g, float partial, int mouseX, int mouseY) {
            g.blit(BG, (width - imageWidth) / 2, (height - imageHeight) / 2, 0, 0, imageWidth, imageHeight);
        }
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
