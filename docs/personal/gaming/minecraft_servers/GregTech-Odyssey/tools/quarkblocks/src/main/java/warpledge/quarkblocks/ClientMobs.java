package warpledge.quarkblocks;

import com.google.common.collect.ImmutableList;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import java.util.Random;
import java.util.function.BiConsumer;
import net.minecraft.client.Minecraft;
import net.minecraft.client.model.AgeableListModel;
import net.minecraft.client.model.EntityModel;
import net.minecraft.client.model.HumanoidModel;
import net.minecraft.client.model.SkeletonModel;
import net.minecraft.client.model.geom.ModelLayerLocation;
import net.minecraft.client.model.geom.ModelLayers;
import net.minecraft.client.model.geom.ModelPart;
import net.minecraft.client.model.geom.PartPose;
import net.minecraft.client.model.geom.builders.CubeDeformation;
import net.minecraft.client.model.geom.builders.CubeListBuilder;
import net.minecraft.client.model.geom.builders.LayerDefinition;
import net.minecraft.client.model.geom.builders.MeshDefinition;
import net.minecraft.client.model.geom.builders.PartDefinition;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.entity.EntityRendererProvider;
import net.minecraft.client.renderer.entity.MobRenderer;
import net.minecraft.client.renderer.entity.RenderLayerParent;
import net.minecraft.client.renderer.entity.SkeletonRenderer;
import net.minecraft.client.renderer.entity.layers.EyesLayer;
import net.minecraft.client.renderer.entity.layers.RenderLayer;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.monster.AbstractSkeleton;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraftforge.client.event.EntityRenderersEvent;
import net.minecraftforge.eventbus.api.IEventBus;

/**
 * Models and renderers for Quark's mobs (CC BY-NC-SA 3.0; each class names its Quark
 * original). Textures are Quark's, under textures/model/entity/.
 */
final class ClientMobs {
    private ClientMobs() {}

    static final ModelLayerLocation WRAITH = layer("wraith");
    static final ModelLayerLocation FOXHOUND = layer("foxhound");
    static final ModelLayerLocation CRAB = layer("crab");
    static final ModelLayerLocation TORETOISE = layer("toretoise");
    static final ModelLayerLocation FORGOTTEN_HAT = layer("forgotten_hat");

    private static ModelLayerLocation layer(String name) {
        return new ModelLayerLocation(QuarkBlocks.rl(name), "main");
    }

    private static ResourceLocation tex(String path) {
        return QuarkBlocks.rl("textures/model/entity/" + path + ".png");
    }

    static void register(IEventBus modBus) {
        modBus.addListener(ClientMobs::layers);
        modBus.addListener(ClientMobs::renderers);
    }

    private static void layers(EntityRenderersEvent.RegisterLayerDefinitions event) {
        event.registerLayerDefinition(WRAITH, WraithModel::layer);
        event.registerLayerDefinition(FOXHOUND, FoxhoundModel::layer);
        event.registerLayerDefinition(CRAB, CrabModel::layer);
        event.registerLayerDefinition(TORETOISE, ToretoiseModel::layer);
        event.registerLayerDefinition(FORGOTTEN_HAT, ClientMobs::hatLayer);
    }

    private static void renderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerEntityRenderer(QuarkBlocks.WRAITH.get(), ctx -> new MobRenderer<Wraith, WraithModel>(ctx,
                new WraithModel(ctx.bakeLayer(WRAITH)), 0F) {
            @Override
            public ResourceLocation getTextureLocation(Wraith e) {
                return tex("wraith");
            }
        });
        event.registerEntityRenderer(QuarkBlocks.FORGOTTEN.get(), ForgottenRenderer::new);
        event.registerEntityRenderer(QuarkBlocks.FOXHOUND.get(), FoxhoundRenderer::new);
        event.registerEntityRenderer(QuarkBlocks.CRAB.get(), CrabRenderer::new);
        event.registerEntityRenderer(QuarkBlocks.TORETOISE.get(), ToretoiseRenderer::new);
    }

    /** ForgottenHatModel: a tall hat with a brim, on Quark's armour model frame. */
    private static LayerDefinition hatLayer() {
        MeshDefinition mesh = new MeshDefinition();
        PartDefinition root = mesh.getRoot();
        for (String part : new String[] {"hat", "body", "left_arm", "right_arm", "left_leg", "right_leg"}) {
            root.addOrReplaceChild(part, CubeListBuilder.create(), PartPose.ZERO);
        }
        PartDefinition head = root.addOrReplaceChild("head", CubeListBuilder.create(), PartPose.ZERO);
        head.addOrReplaceChild("piece1", CubeListBuilder.create().texOffs(0, 0)
                .addBox(-4F, -10F, -4F, 8, 10, 8, new CubeDeformation(0.6F)), PartPose.ZERO);
        head.addOrReplaceChild("piece2", CubeListBuilder.create().texOffs(0, 18).addBox(-6F, -6F, -6F, 12, 1, 12),
                PartPose.ZERO);
        return LayerDefinition.create(mesh, 64, 64);
    }

    private static HumanoidModel<LivingEntity> hatModel;

    /** The forgotten hat as worn (QuarkItems.ForgottenHat asks for it). */
    static HumanoidModel<LivingEntity> hatModel() {
        if (hatModel == null) hatModel = new HumanoidModel<>(Minecraft.getInstance().getEntityModels().bakeLayer(FORGOTTEN_HAT));
        return hatModel;
    }

    //-- Wraith

    /** WraithModel: a hooded body and arms that bob and fade in and out. */
    static final class WraithModel extends EntityModel<Wraith> {
        private final ModelPart main;
        private final ModelPart arms;
        private double offset;
        private float alpha;

        WraithModel(ModelPart root) {
            super(RenderType::entityTranslucent);
            main = root.getChild("main");
            arms = main.getChild("arms");
        }

        static LayerDefinition layer() {
            MeshDefinition mesh = new MeshDefinition();
            PartDefinition main = mesh.getRoot().addOrReplaceChild("main", CubeListBuilder.create(), PartPose.offset(0, 24, 0));
            main.addOrReplaceChild("arms", CubeListBuilder.create()
                    .texOffs(36, 6).addBox(-8.5F, 1F, -2F, 3, 15, 5)
                    .texOffs(0, 55).addBox(-5.5F, 12F, 0F, 11, 4, 0)
                    .texOffs(47, 3).addBox(-8.5F, 11F, -2F, 3, 3, 5, new CubeDeformation(0.25F))
                    .texOffs(36, 6).mirror().addBox(5.5F, 1F, -2F, 3, 15, 5).mirror(false)
                    .texOffs(47, 3).mirror().addBox(5.5F, 11F, -2F, 3, 3, 5, new CubeDeformation(0.25F)).mirror(false),
                    PartPose.offset(0, -17, -1));
            main.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 0).addBox(-4.5F, -10F, -4F, 11, 26, 7),
                    PartPose.offsetAndRotation(-1, -18, 0, 0.3927F, 0, 0));
            return LayerDefinition.create(mesh, 64, 64);
        }

        @Override
        public void setupAnim(Wraith e, float swing, float swingAmount, float age, float yaw, float pitch) {
            Random rng = new Random(e.getId());
            float t1 = age + rng.nextInt(10000000), t2 = age + rng.nextInt(6000000), t3 = age + rng.nextInt(8000000);
            main.xRot = (float) Math.sin(t1 / 16) * 0.1F - 0.3F;
            main.yRot = (float) Math.sin(t2 / 20) * 0.12F;
            main.zRot = (float) Math.sin(t3 / 12) * 0.07F;
            arms.xRot = (float) Math.sin(t2 / 22) * 0.15F;
            offset = Math.sin(t1 / 16) * 0.1 - 0.25;
            alpha = 0.8F + (float) Math.sin(t2 / 20) * 0.2F;
        }

        @Override
        public void renderToBuffer(PoseStack pose, VertexConsumer vb, int light, int overlay, float r, float g, float b, float a) {
            pose.pushPose();
            pose.translate(0, offset, -0.1); // -0.1 keeps the model inside the hitbox
            main.render(pose, vb, light, overlay, r, g, b, a * alpha);
            pose.popPose();
        }
    }

    //-- Forgotten

    /** ForgottenRenderer: a 1.2x skeleton with clothing, glowing eyes and a sheathed sword. */
    private static final class ForgottenRenderer extends SkeletonRenderer {
        @SuppressWarnings({"unchecked", "rawtypes"})
        ForgottenRenderer(EntityRendererProvider.Context ctx) {
            super(ctx);
            SkeletonModel<AbstractSkeleton> clothes = new SkeletonModel<>(ctx.bakeLayer(ModelLayers.STRAY_OUTER_LAYER));
            addLayer(new RenderLayer<AbstractSkeleton, SkeletonModel<AbstractSkeleton>>(this) {
                @Override
                public void render(PoseStack pose, MultiBufferSource buffers, int light, AbstractSkeleton e, float swing,
                        float amount, float partial, float age, float yaw, float pitch) {
                    coloredCutoutModelCopyLayerRender(getParentModel(), clothes, tex("forgotten/overlay"), pose, buffers,
                            light, e, swing, amount, age, yaw, pitch, partial, 1F, 1F, 1F);
                }
            });
            addLayer(new EyesLayer<AbstractSkeleton, SkeletonModel<AbstractSkeleton>>(this) {
                private final RenderType type = RenderType.eyes(tex("forgotten/eye"));

                @Override
                public RenderType renderType() {
                    return type;
                }
            });
            addLayer(new RenderLayer<AbstractSkeleton, SkeletonModel<AbstractSkeleton>>(this) {
                @Override
                public void render(PoseStack pose, MultiBufferSource buffers, int light, AbstractSkeleton e, float swing,
                        float amount, float partial, float age, float yaw, float pitch) {
                    if (!(e instanceof Forgotten f)) return;
                    ItemStack sword = f.getEntityData().get(Forgotten.SHEATHED);
                    pose.pushPose();
                    pose.translate(0.1, 0.2, 0.15);
                    pose.scale(0.75F, 0.75F, 0.75F);
                    pose.mulPose(Axis.ZP.rotationDegrees(90));
                    ctx.getItemInHandRenderer().renderItem(e, sword, ItemDisplayContext.NONE, true, pose, buffers, light);
                    pose.popPose();
                }
            });
        }

        @Override
        public ResourceLocation getTextureLocation(AbstractSkeleton e) {
            return tex("forgotten/main");
        }

        @Override
        protected void scale(AbstractSkeleton e, PoseStack pose, float partial) {
            pose.scale(1.2F, 1.2F, 1.2F);
        }
    }

    //-- Foxhound

    /** FoxhoundModel (McVinnyq's, via Quark): standing, sitting and curled-up sleeping poses. */
    static final class FoxhoundModel extends AgeableListModel<Foxhound> {
        private final ModelPart head, rightFrontLeg, leftFrontLeg, rightBackLeg, leftBackLeg, body, tail;

        FoxhoundModel(ModelPart root) {
            super(false, 5, 2.5F);
            head = root.getChild("head");
            rightFrontLeg = root.getChild("rightFrontLeg");
            leftFrontLeg = root.getChild("leftFrontLeg");
            rightBackLeg = root.getChild("rightBackLeg");
            leftBackLeg = root.getChild("leftBackLeg");
            body = root.getChild("body");
            tail = body.getChild("tail");
        }

        static LayerDefinition layer() {
            MeshDefinition mesh = new MeshDefinition();
            PartDefinition root = mesh.getRoot();
            PartDefinition head = root.addOrReplaceChild("head", CubeListBuilder.create().texOffs(0, 20)
                    .addBox(-4F, -3F, -6F, 8, 6, 6), PartPose.offsetAndRotation(0, 14.5F, -5.5F, 0, 1F, 0));
            head.addOrReplaceChild("rightEar", CubeListBuilder.create().texOffs(0, 47).addBox(-4F, -5F, -5F, 2, 2, 3), PartPose.ZERO);
            head.addOrReplaceChild("leftEar", CubeListBuilder.create().texOffs(10, 47).addBox(2F, -5F, -5F, 2, 2, 3), PartPose.ZERO);
            head.addOrReplaceChild("snout", CubeListBuilder.create().texOffs(29, 18).addBox(-2F, 1F, -10F, 4, 2, 4), PartPose.ZERO);
            PartDefinition body = root.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 2)
                    .addBox(-4F, -12F, 0F, 8, 12, 6), PartPose.offsetAndRotation(0, 17F, 6.5F, 1.5707964F, 0, 0));
            body.addOrReplaceChild("tail", CubeListBuilder.create().texOffs(36, 16).addBox(-2F, -4F, 0F, 4, 5, 10),
                    PartPose.offsetAndRotation(0, 0, 1.5F, -1.3089969F, 0, 0));
            body.addOrReplaceChild("fluff", CubeListBuilder.create().texOffs(28, 0).addBox(-5F, 0F, -4F, 10, 8, 8),
                    PartPose.offset(0, -13F, 3F));
            root.addOrReplaceChild("leftBackLeg", CubeListBuilder.create().texOffs(36, 32).addBox(-1.5F, 0, -1.5F, 3, 12, 3),
                    PartPose.offset(3F, 12F, 4));
            root.addOrReplaceChild("rightBackLeg", CubeListBuilder.create().texOffs(24, 32).addBox(-1.5F, 0, -1.5F, 3, 12, 3),
                    PartPose.offset(-3F, 12F, 4));
            root.addOrReplaceChild("rightFrontLeg", CubeListBuilder.create().texOffs(0, 32).addBox(-1.5F, 0, -1.5F, 3, 12, 3),
                    PartPose.offset(-2F, 12F, -3.5F));
            root.addOrReplaceChild("leftFrontLeg", CubeListBuilder.create().texOffs(12, 32).addBox(-1.5F, 0, -1.5F, 3, 12, 3),
                    PartPose.offset(2F, 12F, -3.5F));
            return LayerDefinition.create(mesh, 64, 64);
        }

        private static void angle(ModelPart p, float x, float y, float z) {
            p.xRot = x;
            p.yRot = y;
            p.zRot = z;
        }

        @Override
        public void prepareMobModel(Foxhound h, float swing, float amount, float partial) {
            tail.xRot = h.getRemainingPersistentAngerTime() > 0 ? -0.6544985F
                    : -1.3089969F + Mth.cos(swing * 0.6662F) * amount;
            head.yRot = h.getHeadRollAngle(partial) - h.getBodyRollAngle(partial, 0F);
            head.xRot = 0;
            body.yRot = h.getBodyRollAngle(partial, -0.16F);
            tail.yRot = h.getBodyRollAngle(partial, -0.2F);
            if (h.isSleeping()) {
                head.setPos(1F, 20.5F, -5.5F);
                angle(head, 0, 0.7853982F, -0.0436332F);
                body.setPos(0, 20F, 6.5F);
                angle(body, 1.5707964F, 0, 1.5707964F);
                tail.setPos(0, -1F, 1F);
                angle(tail, 2.5497515F, -0.2275909F, 0);
                rightFrontLeg.setPos(0, 18F, -3.5F);
                leftFrontLeg.setPos(2F, 21F, -4.5F);
                rightBackLeg.setPos(0, 22F, 5.5F);
                leftBackLeg.setPos(3F, 20F, 4.5F);
                angle(rightFrontLeg, 0.2181662F, 0.4363323F, 1.3089969F);
                angle(leftFrontLeg, 0, 0, 1.3962634F);
                angle(rightBackLeg, -1.0471976F, -0.0872665F, 1.4835299F);
                angle(leftBackLeg, -0.7853982F, 0, 1.2217305F);
            } else if (h.isInSittingPose()) {
                head.setPos(0, 12F, -3.5F);
                body.setPos(0, 23F, 1.5F);
                angle(body, 0.7853982F, body.yRot, 0);
                tail.setPos(0, 0, 2F);
                angle(tail, -1.1F, 0, 0);
                rightFrontLeg.setPos(-2F, 12F, -4.25F);
                leftFrontLeg.setPos(2F, 12F, -4.25F);
                rightBackLeg.setPos(-3F, 21F, 4.5F);
                leftBackLeg.setPos(3F, 21F, 4.5F);
                angle(rightFrontLeg, 0, 0, 0);
                angle(leftFrontLeg, 0, 0, 0);
                angle(rightBackLeg, -1.3089969F, 0.3926991F, 0);
                angle(leftBackLeg, -1.3089969F, -0.3926991F, 0);
            } else {
                head.setPos(0, 14.5F, -5.5F);
                body.setPos(0, 17F, 6.5F);
                angle(body, 1.5707964F, body.yRot, 0);
                tail.setPos(0, 0, 1.5F);
                rightFrontLeg.setPos(-2F, 12F, -3.5F);
                leftFrontLeg.setPos(2F, 12F, -3.5F);
                rightBackLeg.setPos(-3F, 12F, 4);
                leftBackLeg.setPos(3F, 12F, 4);
                float a = Mth.cos(swing * 0.6662F) * 1.4F * amount;
                float b = Mth.cos(swing * 0.6662F + (float) Math.PI) * 1.4F * amount;
                angle(rightFrontLeg, a, 0, 0);
                angle(leftFrontLeg, b, 0, 0);
                angle(rightBackLeg, b, 0, 0);
                angle(leftBackLeg, a, 0, 0);
            }
        }

        @Override
        public void setupAnim(Foxhound e, float swing, float amount, float age, float yaw, float pitch) {
            if (!e.isSleeping()) {
                head.yRot += yaw * 0.017453292F;
                head.xRot += pitch * 0.017453292F;
            } else {
                head.yRot += Mth.cos(e.tickCount / 30F) / 20;
            }
        }

        @Override
        protected Iterable<ModelPart> headParts() {
            return ImmutableList.of(head);
        }

        @Override
        protected Iterable<ModelPart> bodyParts() {
            return ImmutableList.of(body, rightBackLeg, leftBackLeg, rightFrontLeg, leftFrontLeg);
        }
    }

    /** FoxhoundRenderer: red, blue (soul) or, 1 in 256, black; idle, hostile or asleep. */
    private static final class FoxhoundRenderer extends MobRenderer<Foxhound, FoxhoundModel> {
        FoxhoundRenderer(EntityRendererProvider.Context ctx) {
            super(ctx, new FoxhoundModel(ctx.bakeLayer(FOXHOUND)), 0.5F);
            addLayer(new RenderLayer<>(this) {
                @Override
                public void render(PoseStack pose, MultiBufferSource buffers, int light, Foxhound h, float swing,
                        float amount, float partial, float age, float yaw, float pitch) {
                    if (!h.isTame() || h.isInvisible()) return;
                    float[] c = h.getCollarColor().getTextureDiffuseColors();
                    renderColoredCutoutModel(getParentModel(), tex("foxhound/collar"), pose, buffers, light, h, c[0], c[1], c[2]);
                }
            });
        }

        @Override
        public ResourceLocation getTextureLocation(Foxhound h) {
            String colour = h.isBlue() ? "blue" : h.getUUID().getMostSignificantBits() % 256 == 0 ? "black" : "red";
            String state = h.isSleeping() ? "sleeping" : h.getRemainingPersistentAngerTime() > 0 ? "hostile" : "idle";
            return tex("foxhound/" + colour + "/" + state);
        }
    }

    //-- Crab

    /** CrabModel: scuttling legs; a raving crab dances and waves its claws. */
    static final class CrabModel extends EntityModel<Crab> {
        private final ModelPart group, leftClaw, rightClaw;
        private final ModelPart[] left = new ModelPart[4], right = new ModelPart[4];
        private float wiggleX, wiggleY, size;

        CrabModel(ModelPart root) {
            group = root.getChild("group");
            leftClaw = group.getChild("leftClaw");
            rightClaw = group.getChild("rightClaw");
            for (int i = 0; i < 4; i++) {
                left[i] = group.getChild("leftLeg" + (i + 1));
                right[i] = group.getChild("rightLeg" + (i + 1));
            }
        }

        static LayerDefinition layer() {
            MeshDefinition mesh = new MeshDefinition();
            PartDefinition group = mesh.getRoot().addOrReplaceChild("group", CubeListBuilder.create(), PartPose.ZERO);
            PartDefinition body = group.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 0)
                    .addBox(-4F, -2.5F, -3F, 8, 5, 6), PartPose.offset(0, 20F, 0));
            body.addOrReplaceChild("rightEye", CubeListBuilder.create().texOffs(0, 11).addBox(-3F, -3.5F, -2.85F, 1, 3, 1),
                    PartPose.rotation(-0.3926991F, 0, 0));
            body.addOrReplaceChild("leftEye", CubeListBuilder.create().texOffs(0, 11).addBox(2F, -3.5F, -2.85F, 1, 3, 1),
                    PartPose.rotation(-0.3926991F, 0, 0));
            group.addOrReplaceChild("rightClaw", CubeListBuilder.create().texOffs(14, 11).addBox(-3F, -2.5F, -6F, 3, 5, 6),
                    PartPose.offsetAndRotation(-3F, 20F, -4F, 0, 0.3926991F, -0.3926991F));
            group.addOrReplaceChild("leftClaw", CubeListBuilder.create().mirror().texOffs(14, 11).addBox(0F, -2.5F, -6F, 3, 5, 6),
                    PartPose.offsetAndRotation(3F, 20F, -4F, 0, -0.3926991F, 0.3926991F));
            float[] z = {2F, 0.9F, 0F, -1F};
            float[] leftY = {-0.4363323F, -0.2181662F, 0.2181662F, 0.4363323F};
            float[] rightY = {0.4363323F, 0.2181662F, -0.2181662F, -0.4363323F};
            for (int i = 0; i < 4; i++) {
                group.addOrReplaceChild("leftLeg" + (i + 1), CubeListBuilder.create().mirror().texOffs(0, 19)
                        .addBox(0F, -0.5F, -0.5F, 6, 1, 1), PartPose.offsetAndRotation(3F, 20F, z[i], 0, leftY[i], 0.7853982F));
                CubeListBuilder r = CubeListBuilder.create();
                if (i == 1) r.mirror(); // Quark's model mirrors this one leg's texture
                group.addOrReplaceChild("rightLeg" + (i + 1), r.texOffs(0, 19).addBox(-6F, -0.5F, -0.5F, 6, 1, 1),
                        PartPose.offsetAndRotation(-3F, 20F, z[i], 0, rightY[i], -0.7853982F));
            }
            return LayerDefinition.create(mesh, 32, 32);
        }

        @Override
        public void setupAnim(Crab crab, float swing, float amount, float age, float yaw, float pitch) {
            float c = Mth.cos(swing * 0.6662F), d = Mth.cos(swing * 0.6662F + (float) Math.PI);
            right[0].zRot = -0.2618F + (-1 + c) * 0.7F * amount;
            right[1].zRot = -0.5236F + (-1 + d) * 0.7F * amount;
            right[2].zRot = -0.5236F + (-1 + c) * 0.7F * amount;
            right[3].zRot = -0.2618F + (-1 + d) * 0.7F * amount;
            left[0].zRot = 0.2618F + (1 + d) * 0.7F * amount;
            left[1].zRot = 0.5236F + (1 + c) * 0.7F * amount;
            left[2].zRot = 0.5236F + (1 + d) * 0.7F * amount;
            left[3].zRot = 0.2618F + (1 + c) * 0.7F * amount;
            leftClaw.xRot = rightClaw.xRot = 0;
            wiggleX = wiggleY = 0;
            size = crab.size() / (young ? 2 : 1);
            if (crab.raving()) {
                float tick = age * (20F / (125F / 4));
                float sin = (float) (Math.sin(tick) * 0.5 + 0.5);
                for (int i = 0; i < 4; i++) {
                    left[i].zRot = sin * 0.8F + 0.6F;
                    right[i].zRot = -(sin * 0.8F + 0.6F);
                }
                wiggleX = (sin - 0.5F) * 2 * -0.05F + -0.05F / 2;
                wiggleY = (float) Math.sin(tick / 2) * 0.2F;
                leftClaw.xRot = rightClaw.xRot = sin * 0.5F - 1.2F;
            }
        }

        @Override
        public void renderToBuffer(PoseStack pose, VertexConsumer vb, int light, int overlay, float r, float g, float b, float a) {
            pose.pushPose();
            pose.translate(0, 1.5 - size * 1.5, 0);
            pose.scale(size, size, size);
            pose.mulPose(Axis.YP.rotationDegrees(90F));
            pose.translate(wiggleX, wiggleY, 0);
            group.render(pose, vb, light, overlay, r, g, b, a);
            pose.popPose();
        }
    }

    /** CrabRenderer: red, blue or green, with an optional mould layer. */
    private static final class CrabRenderer extends MobRenderer<Crab, CrabModel> {
        private static final String[] COLOURS = {"red", "blue", "green"};

        CrabRenderer(EntityRendererProvider.Context ctx) {
            super(ctx, new CrabModel(ctx.bakeLayer(CRAB)), 0.4F);
            addLayer(new RenderLayer<>(this) {
                @Override
                public void render(PoseStack pose, MultiBufferSource buffers, int light, Crab crab, float swing,
                        float amount, float partial, float age, float yaw, float pitch) {
                    if (crab.variant() >= Crab.COLORS) {
                        renderColoredCutoutModel(getParentModel(), tex("crab/mold_layer"), pose, buffers, light, crab, 1F, 1F, 1F);
                    }
                }
            });
        }

        @Override
        public ResourceLocation getTextureLocation(Crab crab) {
            return tex("crab/" + COLOURS[crab.variant() % COLOURS.length]);
        }
    }

    //-- Toretoise

    /** ToretoiseModel: plodding legs, a stomp when angry; ores are parts of the shell. */
    static final class ToretoiseModel extends EntityModel<Toretoise> {
        private final ModelPart body, head, rightFrontLeg, leftFrontLeg, rightBackLeg, leftBackLeg;
        private Toretoise entity;
        private float frames;

        ToretoiseModel(ModelPart root) {
            body = root.getChild("body");
            head = root.getChild("head");
            rightFrontLeg = root.getChild("rightFrontLeg");
            leftFrontLeg = root.getChild("leftFrontLeg");
            rightBackLeg = root.getChild("rightBackLeg");
            leftBackLeg = root.getChild("leftBackLeg");
        }

        private static void box(PartDefinition p, String name, int u, int v, float x, float y, float z, int w, int h, int d) {
            p.addOrReplaceChild(name, CubeListBuilder.create().texOffs(u, v).addBox(x, y, z, w, h, d), PartPose.ZERO);
        }

        static LayerDefinition layer() {
            MeshDefinition mesh = new MeshDefinition();
            PartDefinition root = mesh.getRoot();
            PartDefinition body = root.addOrReplaceChild("body", CubeListBuilder.create().texOffs(0, 0)
                    .addBox(-11F, 0F, -13F, 22, 12, 26), PartPose.offset(0, 8F, 0));
            PartDefinition head = root.addOrReplaceChild("head", CubeListBuilder.create().texOffs(0, 38)
                    .addBox(-4F, -4F, -8F, 8, 5, 8), PartPose.offset(0, 16F, -13F));
            head.addOrReplaceChild("mouth", CubeListBuilder.create().texOffs(66, 38).addBox(-4.5F, -2.5F, -8F, 9, 4, 8),
                    PartPose.offset(0, 1F, -1F));
            root.addOrReplaceChild("leftFrontLeg", CubeListBuilder.create().mirror().texOffs(34, 38)
                    .addBox(-4F, -2F, -4F, 8, 10, 8), PartPose.offsetAndRotation(10F, 16F, -12F, 0, -0.7853982F, 0));
            root.addOrReplaceChild("rightBackLeg", CubeListBuilder.create().texOffs(34, 38)
                    .addBox(-4F, -2F, -4F, 8, 10, 8), PartPose.offsetAndRotation(-10F, 16F, 12F, 0, 0.7853982F, 0));
            root.addOrReplaceChild("rightFrontLeg", CubeListBuilder.create().texOffs(34, 38)
                    .addBox(-4F, -2F, -4F, 8, 10, 8), PartPose.offsetAndRotation(-10F, 16F, -12F, 0, 0.7853982F, 0));
            root.addOrReplaceChild("leftBackLeg", CubeListBuilder.create().mirror().texOffs(34, 38)
                    .addBox(-4F, -2F, -4F, 8, 10, 8), PartPose.offsetAndRotation(10F, 16F, 12F, 0, -0.7853982F, 0));
            box(body, "CoalOre1", 36, 56, 0F, -7F, -6F, 3, 3, 3);
            box(body, "CoalOre2", 42, 56, 7F, -2F, -10F, 6, 6, 6);
            box(body, "CoalOre3", 66, 50, -2F, -7F, -4F, 7, 7, 7);
            box(body, "CoalOre4", 60, 64, -15F, 0F, 1F, 4, 6, 6);
            box(body, "IronOre1", 36, 89, 1F, -3F, 1F, 8, 3, 8);
            box(body, "IronOre2", 32, 81, -7F, -2F, -11F, 6, 2, 6);
            box(body, "IronOre3", 30, 76, -9F, -1F, 6F, 4, 1, 4);
            box(body, "LapisOre1", 0, 51, -5F, -8F, 0F, 8, 8, 0);
            box(body, "LapisOre2", 0, 53, -1F, -8F, -4F, 0, 8, 8);
            box(body, "LapisOre3", 18, 51, -10F, -8F, 8F, 8, 8, 0);
            box(body, "LapisOre4", 18, 53, -6F, -8F, 4F, 0, 8, 8);
            box(body, "RedstoneOre1", 0, 83, -8F, -12F, -6F, 5, 12, 5);
            box(body, "RedstoneOre2", 0, 74, 6F, -6F, -1F, 3, 6, 3);
            box(body, "RedstoneOre3", 12, 76, -7F, -4F, 2F, 2, 4, 2);
            box(body, "RedstoneOre4", 20, 87, 1F, -9F, -9F, 4, 9, 4);
            box(body, "RedstoneOre5", 15, 77, -1F, -5F, 5F, 5, 5, 5);
            return LayerDefinition.create(mesh, 128, 128);
        }

        @Override
        public void setupAnim(Toretoise e, float swing, float amount, float age, float yaw, float pitch) {
            entity = e;
            frames = swing;
        }

        @Override
        public void renderToBuffer(PoseStack pose, VertexConsumer vb, int light, int overlay, float r, float g, float b, float a) {
            float partial = Minecraft.getInstance().getFrameTime();
            pose.pushPose();
            int buffer = 10;
            if (entity.angryTicks > 0 && entity.angryTicks < Toretoise.ANGRY_TIME - buffer) {
                double t = Math.sin((entity.angryTicks - partial) / (Toretoise.ANGRY_TIME - buffer) * Math.PI) * -20;
                pose.translate(0, 1, 1);
                pose.mulPose(Axis.XP.rotationDegrees((float) t));
                pose.translate(0, -1, -1);
            }
            float speed = 30, pause = 12, actual = frames * 10, dbl = speed * 2, buff = speed - pause, scale = 0.02F;
            float bodyTrans = (float) (Math.sin(actual / dbl * Math.PI) + 1F) * scale;
            float ride = entity.rideTime > 0 ? Math.min(30, entity.rideTime - 1 + partial) / 30F : 0;
            bodyTrans *= 1F - ride;
            pose.translate(0, bodyTrans, 0);
            pose.mulPose(Axis.ZP.rotation((bodyTrans - scale) * 0.5F));
            body.render(pose, vb, light, overlay, r, g, b, a);
            pose.pushPose();
            pose.translate(0, bodyTrans, ride * 0.3);
            head.xRot = bodyTrans * 2;
            head.render(pose, vb, light, overlay, r, g, b, a);
            pose.popPose();
            BiConsumer<ModelPart, Float> leg = (part, f) -> {
                float time = Math.min(buff, f % dbl);
                float trans = ((float) (Math.sin(time / buff * Math.PI) + 1.0) / -2F) * 0.12F + 0.06F;
                float rot = ((float) Math.sin((f % dbl) / dbl * Math.PI) + 1F) * -0.25F;
                trans = trans * (1F - ride) + ride * -0.2F;
                rot *= 1F - ride;
                pose.pushPose();
                ModelPart.Cube cube = part.getRandomCube(entity.getRandom());
                double spread = (1F / 16F) * -1.8 * ride;
                double x = part.x + cube.minX, z = part.z + cube.minZ;
                pose.translate(x * (spread / Math.abs(x)), trans, z * (spread / Math.abs(z)));
                float y = part.yRot;
                part.xRot = rot;
                part.yRot *= 1F - ride;
                part.render(pose, vb, light, overlay, r, g, b, a);
                part.yRot = y;
                pose.popPose();
            };
            leg.accept(leftFrontLeg, actual);
            leg.accept(rightFrontLeg, actual + speed);
            leg.accept(leftBackLeg, actual + speed * 0.5F);
            leg.accept(rightBackLeg, actual + speed * 1.5F);
            pose.popPose();
        }
    }

    /** ToretoiseRenderer: the base shell, plus its ore's texture over the shell's ore parts. */
    private static final class ToretoiseRenderer extends MobRenderer<Toretoise, ToretoiseModel> {
        ToretoiseRenderer(EntityRendererProvider.Context ctx) {
            super(ctx, new ToretoiseModel(ctx.bakeLayer(TORETOISE)), 1F);
            addLayer(new RenderLayer<>(this) {
                @Override
                public void render(PoseStack pose, MultiBufferSource buffers, int light, Toretoise t, float swing,
                        float amount, float partial, float age, float yaw, float pitch) {
                    int ore = t.ore();
                    if (ore > 0 && ore <= 5) {
                        renderColoredCutoutModel(getParentModel(), tex("toretoise/ore" + ore), pose, buffers, light, t, 1F, 1F, 1F);
                    }
                }
            });
        }

        @Override
        public ResourceLocation getTextureLocation(Toretoise t) {
            return tex("toretoise/base");
        }
    }
}
