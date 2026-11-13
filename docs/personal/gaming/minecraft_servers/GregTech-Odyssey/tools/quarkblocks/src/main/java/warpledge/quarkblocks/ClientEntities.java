package warpledge.quarkblocks;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import java.util.List;
import net.minecraft.client.Minecraft;
import net.minecraft.client.model.geom.ModelLayers;
import net.minecraft.client.model.geom.ModelPart;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.Sheets;
import net.minecraft.client.renderer.block.BlockRenderDispatcher;
import net.minecraft.client.renderer.blockentity.BannerRenderer;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.resources.model.ModelBakery;
import net.minecraft.client.resources.model.ModelResourceLocation;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.inventory.InventoryMenu;
import net.minecraft.world.item.BannerItem;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.MapItem;
import net.minecraft.world.item.ShieldItem;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.entity.BannerBlockEntity;
import net.minecraft.world.level.saveddata.maps.MapItemSavedData;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.client.event.EntityRenderersEvent;
import net.minecraftforge.client.event.ModelEvent;
import net.minecraftforge.eventbus.api.IEventBus;

/** Renderers for quarkblocks' entities (Quark's, CC BY-NC-SA 3.0; each names its class). */
final class ClientEntities {
    private ClientEntities() {}

    static void register(IEventBus modBus) {
        modBus.addListener(ClientEntities::renderers);
        modBus.addListener(ClientEntities::models);
    }

    private static void renderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(QuarkBlocks.GLASS_FRAME.get(), GlassFrameRenderer::new);
    }

    private static void models(ModelEvent.RegisterAdditional event) {
        event.register(GlassFrameRenderer.MODEL);
    }

    /** GlassItemFrameRenderer: the item at 1.5x, or the bare glass model when empty. */
    private static final class GlassFrameRenderer extends EntityRenderer<GlassItemFrame> {
        static final ModelResourceLocation MODEL =
                new ModelResourceLocation(QuarkBlocks.rl("extra/glass_item_frame"), "inventory");
        private static final List<Direction> SIGN_DIRECTIONS = List.of(Direction.NORTH, Direction.EAST,
                Direction.SOUTH, Direction.WEST);
        private static final BannerBlockEntity BANNER = new BannerBlockEntity(BlockPos.ZERO,
                Blocks.WHITE_BANNER.defaultBlockState());
        private final ModelPart bannerFlag;

        GlassFrameRenderer(EntityRendererProvider.Context ctx) {
            super(ctx);
            bannerFlag = ctx.bakeLayer(ModelLayers.BANNER).getChild("flag");
        }

        @Override
        public void render(GlassItemFrame frame, float yaw, float partial, PoseStack pose, MultiBufferSource buffers,
                int light) {
            super.render(frame, yaw, partial, pose, buffers, light);
            pose.pushPose();
            Direction dir = frame.getDirection();
            Vec3 off = frame.renderOffset();
            pose.translate(-off.x, -off.y, -off.z);
            pose.translate(dir.getStepX() * 0.46875, dir.getStepY() * 0.46875, dir.getStepZ() * 0.46875);
            pose.mulPose(Axis.XP.rotationDegrees(frame.getXRot()));
            pose.mulPose(Axis.YP.rotationDegrees(180F - frame.getYRot()));
            if (frame.getEntityData().get(GlassItemFrame.SHINY)) light = 0xF000F0;
            ItemStack stack = frame.getItem();
            if (stack.isEmpty()) {
                Minecraft mc = Minecraft.getInstance();
                BlockRenderDispatcher blocks = mc.getBlockRenderer();
                pose.pushPose();
                pose.translate(-0.5, -0.5, -0.5);
                blocks.getModelRenderer().renderModel(pose.last(), buffers.getBuffer(Sheets.cutoutBlockSheet()), null,
                        blocks.getBlockModelShaper().getModelManager().getModel(MODEL), 1F, 1F, 1F, light,
                        OverlayTexture.NO_OVERLAY);
                pose.popPose();
            } else {
                renderItem(frame, pose, buffers, light, stack);
            }
            pose.popPose();
        }

        @Override
        public Vec3 getRenderOffset(GlassItemFrame frame, float partial) {
            return frame.renderOffset();
        }

        @Override
        public ResourceLocation getTextureLocation(GlassItemFrame frame) {
            return InventoryMenu.BLOCK_ATLAS;
        }

        @Override
        protected boolean shouldShowName(GlassItemFrame frame) {
            if (!Minecraft.renderNames() || frame.getItem().isEmpty() || !frame.getItem().hasCustomHoverName()
                    || entityRenderDispatcher.crosshairPickEntity != frame) {
                return false;
            }
            float f = frame.isDiscrete() ? 32F : 64F;
            return entityRenderDispatcher.distanceToSqr(frame) < f * f;
        }

        @Override
        protected void renderNameTag(GlassItemFrame frame, Component name, PoseStack pose, MultiBufferSource buffers,
                int light) {
            super.renderNameTag(frame, frame.getItem().getHoverName(), pose, buffers, light);
        }

        private void renderItem(GlassItemFrame frame, PoseStack pose, MultiBufferSource buffers, int light, ItemStack stack) {
            Minecraft mc = Minecraft.getInstance();
            pose.pushPose();
            MapItemSavedData map = MapItem.getSavedData(stack, frame.level());
            if (frame.attachment != GlassItemFrame.Attachment.NONE) {
                int rotation = frame.signRotation - SIGN_DIRECTIONS.indexOf(frame.getDirection().getOpposite()) * 4;
                float angle = -rotation * 22.5F, scale = 0.32F;
                switch (frame.attachment) {
                    case STANDING_BEHIND -> angle += 180F;
                    case WALL_SIGN -> {
                        angle = 0;
                        pose.translate(0, -0.3, 0.45);
                    }
                    case HANGING_FROM_WALL -> {
                        angle = 0;
                        pose.translate(0, -0.52, -0.01);
                    }
                    default -> {}
                }
                pose.translate(0, 0.35, 0.98);
                pose.scale(scale, scale, scale);
                pose.mulPose(Axis.YP.rotationDegrees(angle));
                switch (frame.attachment) {
                    case HANGING_IN_FRONT -> pose.translate(0, -0.52 / scale, -0.075);
                    case HANGING_BEHIND -> pose.translate(0, -0.52 / scale, 0.3);
                    default -> {}
                }
                pose.translate(0, 0, -0.585);
            }
            int rotation = map != null ? frame.getRotation() % 4 * 2 : frame.getRotation();
            pose.mulPose(Axis.ZP.rotationDegrees(rotation * 360F / 8F));
            if (map != null) {
                pose.mulPose(Axis.ZP.rotationDegrees(180F));
                pose.scale(0.0078125F, 0.0078125F, 0.0078125F);
                pose.translate(-64F, -64F, 62.5F); // 62.5, not 64, so the map doesn't z-fight
                mc.gameRenderer.getMapRenderer().render(pose, buffers, MapItem.getMapId(stack), map, true, light);
            } else if (stack.getItem() instanceof BannerItem banner) {
                BANNER.fromItem(stack, banner.getColor());
                pose.pushPose();
                pose.translate(0.0001F, -0.5001F, 0.55F);
                pose.scale(0.799999F, 0.399999F, 0.5F);
                BannerRenderer.renderPatterns(pose, buffers, light, OverlayTexture.NO_OVERLAY, bannerFlag,
                        ModelBakery.BANNER_BASE, true, BANNER.getPatterns());
                pose.popPose();
            } else {
                float s = 1.5F;
                if (stack.getItem() instanceof ShieldItem) {
                    s *= 2.66666667F;
                    pose.translate(-0.25F, 0F, 0.5F);
                } else {
                    pose.translate(0F, 0F, 0.475F);
                }
                pose.scale(s * 0.5F, s * 0.5F, s * 0.5F);
                mc.getItemRenderer().renderStatic(stack, ItemDisplayContext.FIXED, light, OverlayTexture.NO_OVERLAY, pose,
                        buffers, mc.level, 0);
            }
            pose.popPose();
        }
    }
}
