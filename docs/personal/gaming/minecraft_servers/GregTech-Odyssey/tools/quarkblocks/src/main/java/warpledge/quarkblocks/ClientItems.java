package warpledge.quarkblocks;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import net.minecraft.client.renderer.entity.ArrowRenderer;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.entity.NoopRenderer;
import net.minecraft.world.inventory.InventoryMenu;
import net.minecraftforge.client.event.RegisterColorHandlersEvent;
import java.util.Set;
import java.util.stream.Collectors;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.blockentity.BlockEntityRendererProvider;
import net.minecraft.client.renderer.entity.ThrownItemRenderer;
import net.minecraft.client.renderer.item.ItemProperties;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.resources.sounds.SimpleSoundInstance;
import net.minecraft.client.resources.sounds.SoundInstance;
import net.minecraft.core.BlockPos;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.Shapes;
import net.minecraft.world.phys.shapes.VoxelShape;
import net.minecraftforge.client.event.EntityRenderersEvent;
import net.minecraftforge.client.event.RenderGuiOverlayEvent;
import net.minecraftforge.client.event.RenderHighlightEvent;
import net.minecraftforge.client.event.sound.PlaySoundEvent;
import net.minecraftforge.client.gui.overlay.VanillaGuiOverlay;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;
import org.joml.Matrix4f;

/** The client half of QuarkItems (Quark's modules' Client classes, CC BY-NC-SA 3.0). */
final class ClientItems {
    private ClientItems() {}

    static void register(IEventBus modBus) {
        modBus.addListener(ClientItems::setup);
        modBus.addListener(ClientItems::renderers);
        modBus.addListener(ClientItems::itemColors);
        MinecraftForge.EVENT_BUS.addListener(ClientItems::abacusHud);
        MinecraftForge.EVENT_BUS.addListener(ClientItems::abacusPath);
        MinecraftForge.EVENT_BUS.addListener(ClientItems::loopDisc);
    }

    private static void setup(FMLClientSetupEvent event) {
        event.enqueueWork(() -> {
            if (QuarkItems.has("abacus")) {
                ItemProperties.register(QuarkBlocks.ALL_ITEMS.get("abacus").get(), new ResourceLocation("count"),
                        (stack, level, entity, seed) -> {
                            int n = abacusCount(stack, entity);
                            return n == -1 ? 1F : 0.01F * n + 0.005F;
                        });
            }
            if (QuarkItems.has("slime_in_a_bucket")) {
                ItemProperties.register(QuarkBlocks.ALL_ITEMS.get("slime_in_a_bucket").get(),
                        new ResourceLocation("excited"), (stack, level, entity, seed) ->
                                stack.hasTag() && stack.getTag().getBoolean("excited") ? 1 : 0);
            }
        });
    }

    private static void renderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(QuarkBlocks.PARROT_EGG.get(), ThrownItemRenderer::new);
        event.registerBlockEntityRenderer(QuarkBlocks.CLOUD_BE.get(), CloudRenderer::new);
        event.registerEntityRenderer(QuarkBlocks.PICKARANG.get(), PickarangRenderer::new);
        event.registerEntityRenderer(QuarkBlocks.TORCH_ARROW.get(), ctx -> new ArrowRenderer<TorchArrow>(ctx) {
            @Override
            public ResourceLocation getTextureLocation(TorchArrow arrow) {
                return QuarkBlocks.rl("textures/model/entity/torch_arrow.png");
            }
        });
        event.registerEntityRenderer(QuarkBlocks.SOUL_BEAD.get(), NoopRenderer::new);
    }

    /** The quill's ink takes the colour written in it (PathfinderMapsModule). */
    private static void itemColors(RegisterColorHandlersEvent.Item event) {
        if (QuarkItems.has("pathfinders_quill")) {
            event.register((stack, i) -> i == 0 ? 0xFFFFFF : PathfindersQuillItem.color(stack),
                    QuarkBlocks.ALL_ITEMS.get("pathfinders_quill").get());
        }
    }

    /** A spinning pickarang (Quark's PickarangRenderer). */
    private static final class PickarangRenderer extends EntityRenderer<Pickarang> {
        PickarangRenderer(EntityRendererProvider.Context ctx) {
            super(ctx);
        }

        @Override
        public void render(Pickarang rang, float yaw, float partial, PoseStack pose,
                net.minecraft.client.renderer.MultiBufferSource buffers, int light) {
            if (rang.tickCount < 2) return;
            pose.pushPose();
            pose.translate(0, 0.2, 0);
            pose.mulPose(Axis.XP.rotationDegrees(90F));
            Minecraft mc = Minecraft.getInstance();
            float time = rang.tickCount + (mc.isPaused() ? 0 : partial);
            pose.mulPose(Axis.ZP.rotationDegrees(time * 20F));
            mc.getItemRenderer().renderStatic(rang.stack(), ItemDisplayContext.FIXED, light, OverlayTexture.NO_OVERLAY,
                    pose, buffers, rang.level(), 0);
            pose.popPose();
        }

        @Override
        public ResourceLocation getTextureLocation(Pickarang rang) {
            return InventoryMenu.BLOCK_ATLAS;
        }
    }

    //-- Abacus (AbacusModule)

    private static int abacusCount(ItemStack stack, LivingEntity entity) {
        Minecraft mc = Minecraft.getInstance();
        if (entity != mc.player || mc.player == null || !(mc.hitResult instanceof BlockHitResult hit)) return -1;
        return QuarkItems.Abacus.count(stack, hit.getBlockPos(), mc.player.level());
    }

    private static ItemStack heldAbacus(Player player) {
        ItemStack s = player.getMainHandItem();
        if (!(s.getItem() instanceof QuarkItems.Abacus)) s = player.getOffhandItem();
        return s.getItem() instanceof QuarkItems.Abacus ? s : ItemStack.EMPTY;
    }

    private static void abacusHud(RenderGuiOverlayEvent.Post event) {
        Minecraft mc = Minecraft.getInstance();
        if (event.getOverlay() != VanillaGuiOverlay.CROSSHAIR.type() || mc.player == null) return;
        ItemStack stack = heldAbacus(mc.player);
        int n = stack.isEmpty() ? -1 : abacusCount(stack, mc.player);
        if (n < 0) return;
        int x = event.getWindow().getGuiScaledWidth() / 2 + 10;
        int y = event.getWindow().getGuiScaledHeight() / 2 - 7;
        event.getGuiGraphics().renderItem(stack, x, y);
        String text = n < QuarkItems.Abacus.MAX ? Integer.toString(n + 1) : QuarkItems.Abacus.MAX + "+";
        event.getGuiGraphics().drawString(mc.font, text, x + 17, y + 5, 0xFFFFFF, true);
    }

    /** Outlines the path the abacus counts along, in place of the block outline. */
    private static void abacusPath(RenderHighlightEvent.Block event) {
        Minecraft mc = Minecraft.getInstance();
        if (mc.player == null) return;
        ItemStack stack = heldAbacus(mc.player);
        int n = stack.isEmpty() ? -1 : abacusCount(stack, mc.player);
        BlockPos target = QuarkItems.Abacus.bound(stack);
        if (n < 0 || n > QuarkItems.Abacus.MAX || target == null) return;
        BlockPos from = event.getTarget().getBlockPos();
        int dx = from.getX() - target.getX(), dy = from.getY() - target.getY(), dz = from.getZ() - target.getZ();
        VoxelShape shape = Shapes.create(new AABB(target));
        if (dx != 0) shape = Shapes.or(shape, Shapes.create(new AABB(target).expandTowards(dx, 0, 0)));
        if (dy != 0) shape = Shapes.or(shape, Shapes.create(new AABB(target.offset(dx, 0, 0)).expandTowards(0, dy, 0)));
        if (dz != 0) shape = Shapes.or(shape, Shapes.create(new AABB(target.offset(dx, dy, 0)).expandTowards(0, 0, dz)));
        VertexConsumer lines = event.getMultiBufferSource().getBuffer(RenderType.lines());
        Vec3 cam = event.getCamera().getPosition();
        PoseStack.Pose pose = event.getPoseStack().last();
        Matrix4f m = pose.pose();
        for (AABB box : shape.toAabbs()) {
            Shapes.create(box).forAllEdges((x1, y1, z1, x2, y2, z2) -> {
                float fx = (float) (x2 - x1), fy = (float) (y2 - y1), fz = (float) (z2 - z1);
                float len = Mth.sqrt(fx * fx + fy * fy + fz * fz);
                fx /= len;
                fy /= len;
                fz /= len;
                lines.vertex(m, (float) (x1 - cam.x), (float) (y1 - cam.y), (float) (z1 - cam.z)).color(0F, 0F, 0F, 0.4F)
                        .normal(pose.normal(), fx, fy, fz).endVertex();
                lines.vertex(m, (float) (x2 - cam.x), (float) (y2 - cam.y), (float) (z2 - cam.z)).color(0F, 0F, 0F, 0.4F)
                        .normal(pose.normal(), fx, fy, fz).endVertex();
            });
        }
        event.setCanceled(true);
    }

    //-- Ambient discs (AmbientDiscsModule)

    private static Set<ResourceLocation> discSounds;

    /** A jukebox playing one of Quark's ambient discs loops it at volume 3, as Quark does. */
    private static void loopDisc(PlaySoundEvent event) {
        if (discSounds == null) {
            discSounds = QuarkBlocks.SOUND_BY_NAME.keySet().stream().filter(n -> n.startsWith("ambient."))
                    .map(QuarkBlocks::rl).collect(Collectors.toSet());
        }
        SoundInstance s = event.getSound();
        if (s == null || s.getSource() != SoundSource.RECORDS || !discSounds.contains(s.getLocation())) return;
        if (s instanceof SimpleSoundInstance && s.isLooping()) return;
        event.setSound(new SimpleSoundInstance(s.getLocation(), SoundSource.RECORDS, 3F, 1F,
                SoundInstance.createUnseededRandom(), true, 0, SoundInstance.Attenuation.LINEAR, s.getX(), s.getY(),
                s.getZ(), false));
    }

    //-- Cloud (BottledCloudModule)

    /** A white block that shrinks and pulses as the cloud fades (Quark's CloudRenderer). */
    private static final class CloudRenderer implements BlockEntityRenderer<CloudBlock.Entity> {
        CloudRenderer(BlockEntityRendererProvider.Context ctx) {}

        @Override
        public void render(CloudBlock.Entity cloud, float partial, PoseStack pose,
                net.minecraft.client.renderer.MultiBufferSource buffers, int light, int overlay) {
            Minecraft mc = Minecraft.getInstance();
            float t = mc.level == null ? 0 : mc.level.getGameTime() + partial;
            float scale = (float) ((cloud.liveTime - partial + Math.sin(t * 0.2F) * -10F) / 200F) * 0.6F;
            if (scale <= 0) return;
            pose.translate(0.5, 0.5, 0.5);
            pose.scale(scale, scale, scale);
            mc.getItemRenderer().renderStatic(new ItemStack(Blocks.WHITE_CONCRETE), ItemDisplayContext.NONE, 240,
                    OverlayTexture.NO_OVERLAY, pose, buffers, mc.level, 0);
        }
    }
}
