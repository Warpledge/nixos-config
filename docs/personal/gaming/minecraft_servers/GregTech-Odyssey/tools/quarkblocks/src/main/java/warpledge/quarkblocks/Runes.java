package warpledge.quarkblocks;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonSyntaxException;
import java.util.List;
import java.util.Locale;
import net.minecraft.ChatFormatting;
import net.minecraft.core.RegistryAccess;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraft.network.chat.CommonComponents;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.GsonHelper;
import net.minecraft.world.Container;
import net.minecraft.world.item.CompassItem;
import net.minecraft.world.item.DyeColor;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.SmithingTemplateItem;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraft.world.item.crafting.RecipeSerializer;
import net.minecraft.world.item.crafting.SmithingRecipe;
import net.minecraft.world.level.Level;
import net.minecraftforge.event.entity.player.ItemTooltipEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Quark's runes (RuneItem, SmithingRuneRecipe, ColorRunesModule, CC BY-NC-SA 3.0): on a
 * smithing table the rune template with a dye recolours an enchanted item's glint, stored
 * as Quark's "quark:RuneColor" NBT so items from Quark worlds keep theirs. The tooltip
 * names the colour. Drawing the glint in that colour needs Quark's render mixins, which
 * quarkblocks doesn't carry, so the glint stays purple.
 */
final class Runes {
    static final String TAG = "quark:RuneColor";

    private Runes() {}

    static String color(ItemStack stack) {
        return stack.hasTag() && stack.getTag().contains(TAG) ? stack.getTag().getString(TAG) : null;
    }

    static boolean canHaveRune(ItemStack stack) {
        return stack.isEnchanted() || stack.is(Items.COMPASS) && CompassItem.isLodestoneCompass(stack);
    }

    private static boolean valid(String name) {
        if (name.equals("rainbow") || name.equals("blank")) return true;
        for (DyeColor d : DyeColor.values()) if (d.getName().equals(name)) return true;
        return false;
    }

    /** The rune smithing template. */
    static SmithingTemplateItem template() {
        String ns = QuarkBlocks.ID;
        return new SmithingTemplateItem(
                Component.translatable("item." + ns + ".smithing_template.rune.applies_to").withStyle(ChatFormatting.BLUE),
                Component.translatable("item." + ns + ".smithing_template.rune.ingredients").withStyle(ChatFormatting.BLUE),
                Component.translatable("upgrade." + ns + ".rune_upgrade").withStyle(ChatFormatting.GRAY),
                Component.translatable("item." + ns + ".smithing_template.rune.base_slot_description"),
                Component.translatable("item." + ns + ".smithing_template.rune.additions_slot_description"),
                List.of(new ResourceLocation("item/empty_slot_sword"), new ResourceLocation("item/empty_slot_pickaxe"),
                        new ResourceLocation("item/empty_slot_chestplate"), new ResourceLocation("item/empty_slot_axe")),
                List.of(QuarkBlocks.rl("item/empty_slot_dye"), QuarkBlocks.rl("item/empty_slot_blaze_powder"),
                        QuarkBlocks.rl("item/empty_slot_nothing")));
    }

    /** quarkblocks:smithing_rune: template + enchanted item + dye (or nothing) gives the rune. */
    record Recipe(ResourceLocation id, Ingredient template, Ingredient addition, String color) implements SmithingRecipe {
        @Override
        public boolean matches(Container c, Level level) {
            return isTemplateIngredient(c.getItem(0)) && isBaseIngredient(c.getItem(1)) && isAdditionIngredient(c.getItem(2));
        }

        @Override
        public ItemStack assemble(Container c, RegistryAccess access) {
            ItemStack base = c.getItem(1);
            if (!isBaseIngredient(base) || color.equals(Runes.color(base))) return ItemStack.EMPTY;
            ItemStack out = base.copyWithCount(1);
            if (color.equals("blank")) out.removeTagKey(TAG);
            else out.getOrCreateTag().putString(TAG, color);
            return out;
        }

        @Override
        public ItemStack getResultItem(RegistryAccess access) {
            ItemStack shown = new ItemStack(Items.IRON_CHESTPLATE);
            shown.enchant(net.minecraft.world.item.enchantment.Enchantments.ALL_DAMAGE_PROTECTION, 1);
            shown.getOrCreateTag().putString(TAG, color);
            return shown;
        }

        @Override
        public boolean isTemplateIngredient(ItemStack s) {
            return template.test(s);
        }

        @Override
        public boolean isBaseIngredient(ItemStack s) {
            return canHaveRune(s);
        }

        @Override
        public boolean isAdditionIngredient(ItemStack s) {
            return addition.isEmpty() ? s.isEmpty() : addition.test(s);
        }

        @Override
        public ResourceLocation getId() {
            return id;
        }

        @Override
        public RecipeSerializer<?> getSerializer() {
            return QuarkBlocks.RUNE_RECIPE.get();
        }
    }

    static final class Serializer implements RecipeSerializer<Recipe> {
        @Override
        public Recipe fromJson(ResourceLocation id, JsonObject json) {
            Ingredient template = Ingredient.fromJson(GsonHelper.getNonNull(json, "template"));
            JsonElement add = json.get("addition");
            Ingredient addition = add != null && !add.isJsonNull() ? Ingredient.fromJson(add) : Ingredient.EMPTY;
            String color = GsonHelper.getAsString(json, "color").toLowerCase(Locale.ROOT);
            if (!valid(color)) throw new JsonSyntaxException("Rune color must be a dye color, rainbow, or blank");
            return new Recipe(id, template, addition, color);
        }

        @Override
        public Recipe fromNetwork(ResourceLocation id, FriendlyByteBuf buf) {
            Ingredient template = Ingredient.fromNetwork(buf);
            Ingredient addition = buf.readBoolean() ? Ingredient.EMPTY : Ingredient.fromNetwork(buf);
            return new Recipe(id, template, addition, buf.readUtf());
        }

        @Override
        public void toNetwork(FriendlyByteBuf buf, Recipe r) {
            r.template().toNetwork(buf);
            buf.writeBoolean(r.addition().isEmpty());
            if (!r.addition().isEmpty()) r.addition().toNetwork(buf);
            buf.writeUtf(r.color());
        }
    }

    /** The rune's colour under the item's enchantments, as Quark shows it. */
    @SubscribeEvent
    public static void tooltip(ItemTooltipEvent event) {
        String c = color(event.getItemStack());
        if (c == null) return;
        Component title = Component.translatable("upgrade." + QuarkBlocks.ID + ".rune_upgrade").withStyle(ChatFormatting.GRAY);
        if (!event.getToolTip().contains(title)) event.getToolTip().add(title);
        ChatFormatting fmt = ChatFormatting.WHITE;
        for (DyeColor d : DyeColor.values()) {
            if (d.getName().equals(c)) {
                event.getToolTip().add(CommonComponents.space().append(Component.translatable("rune.quarkblocks." + c)
                        .withStyle(s -> s.withColor(d == DyeColor.BLACK ? 0x404040 : d.getTextColor()))));
                return;
            }
        }
        if (c.equals("blank")) fmt = ChatFormatting.GRAY;
        event.getToolTip().add(CommonComponents.space().append(Component.translatable("rune.quarkblocks." + c).withStyle(fmt)));
    }
}
