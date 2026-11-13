package warpledge.quarkblocks;

import com.google.gson.JsonObject;
import net.minecraft.world.food.FoodProperties;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.Rarity;
import net.minecraft.world.item.MobBucketItem;
import net.minecraft.world.item.RecordItem;
import net.minecraft.world.level.material.Fluids;
import net.minecraftforge.common.ForgeSpawnEggItem;

/** Builds one item from its items.json entry; gen.py picks the kind (ITEM_KINDS). */
final class ItemFactory {
    private ItemFactory() {}

    static Item create(JsonObject spec) {
        String id = spec.get("id").getAsString();
        Item.Properties p = new Item.Properties();
        return switch (spec.get("kind").getAsString()) {
            case "plain" -> new Item(p);
            // Quark's CrabsModule.
            case "food" -> new Item(p.food(id.equals("cooked_crab_leg")
                    ? new FoodProperties.Builder().meat().nutrition(8).saturationMod(0.8F).build()
                    : new FoodProperties.Builder().meat().nutrition(1).saturationMod(0.3F).build()));
            case "ancient_fruit" -> new QuarkItems.AncientFruit(p.food(new FoodProperties.Builder()
                    .nutrition(4).saturationMod(0.3F).alwaysEat().build()));
            case "forgotten_hat" -> new QuarkItems.ForgottenHat(p.stacksTo(1).durability(0).rarity(Rarity.RARE));
            // Quark's ambient discs play until stopped (AmbientDiscsModule, QuarkItems.loopDiscs).
            case "disc" -> new RecordItem(15, QuarkBlocks.SOUND_BY_NAME.get(
                    spec.getAsJsonArray("sounds").get(0).getAsString()),
                    p.stacksTo(1).rarity(Rarity.RARE), Integer.MAX_VALUE);
            case "parrot_egg" -> new QuarkItems.ParrotEggItem(p.stacksTo(16), spec.get("variant").getAsString());
            case "abacus" -> new QuarkItems.Abacus(p.stacksTo(1));
            case "trowel" -> new QuarkItems.Trowel(p.stacksTo(1));
            case "slime_bucket" -> new QuarkItems.SlimeBucket(p.stacksTo(1).craftRemainder(Items.BUCKET));
            case "bottled_cloud" -> new QuarkItems.BottledCloud(p);
            case "seed_pouch" -> new SeedPouchItem(p.stacksTo(1));
            case "quill" -> new PathfindersQuillItem(p.stacksTo(1));
            case "ancient_tome" -> new AncientTomeItem(p.stacksTo(1).rarity(Rarity.UNCOMMON));
            case "pickarang" -> new Pickarang.PickarangItem(p.stacksTo(1));
            case "torch_arrow" -> new TorchArrow.Item(p);
            case "soul_bead" -> new SoulBead.Item(p);
            case "rune" -> Runes.template();
            case "glass_frame" -> new GlassItemFrame.FrameItem(p, id.startsWith("glowing_"));
            case "spawn_egg" -> new ForgeSpawnEggItem(QuarkBlocks.mob(spec.get("mob").getAsString()),
                    spec.getAsJsonArray("colors").get(0).getAsInt(), spec.getAsJsonArray("colors").get(1).getAsInt(), p);
            case "crab_bucket" -> new MobBucketItem(QuarkBlocks.CRAB, () -> Fluids.WATER,
                    QuarkBlocks.SOUND_BY_NAME.get("item.bucket.empty_crab"), p.stacksTo(1));
            default -> throw new IllegalArgumentException("unknown item kind in " + spec);
        };
    }
}
