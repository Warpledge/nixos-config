package warpledge.quarkblocks;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import net.minecraft.ChatFormatting;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.nbt.ListTag;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.EnchantedBookItem;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.TooltipFlag;
import net.minecraft.world.item.enchantment.Enchantment;
import net.minecraft.world.item.enchantment.EnchantmentHelper;
import net.minecraft.world.level.Level;
import net.minecraftforge.event.AnvilUpdateEvent;
import net.minecraftforge.eventbus.api.EventPriority;
import net.minecraftforge.eventbus.api.SubscribeEvent;

/**
 * Quark's ancient tome (AncientTomeItem and AncientTomesModule, CC BY-NC-SA 3.0): on an
 * anvil it raises its enchantment on an item or book by one level, past the maximum
 * (10 levels, or 30 to go past it). An overlevelled book then applies like any other.
 * Quark's tome trades, loot injection and deepslate tweak are left out.
 */
public class AncientTomeItem extends Item {
    private static final int NORMAL_COST = 10;
    private static final int LIMIT_BREAK_COST = 30;

    public AncientTomeItem(Properties p) {
        super(p);
    }

    @Override
    public boolean isFoil(ItemStack stack) {
        return true;
    }

    @Override
    public boolean isEnchantable(ItemStack stack) {
        return false;
    }

    static Enchantment enchantment(ItemStack stack) {
        if (!(stack.getItem() instanceof AncientTomeItem)) return null;
        ListTag list = EnchantedBookItem.getEnchantments(stack);
        for (int i = 0; i < list.size(); i++) {
            Enchantment e = BuiltInRegistries.ENCHANTMENT.get(ResourceLocation.tryParse(list.getCompound(i).getString("id")));
            if (e != null) return e;
        }
        return null;
    }

    @Override
    public void appendHoverText(ItemStack stack, Level level, List<Component> lines, TooltipFlag flag) {
        Enchantment e = enchantment(stack);
        if (e == null) {
            lines.add(Component.translatable("quarkblocks.misc.ancient_tome_tooltip_any").withStyle(ChatFormatting.GRAY));
            return;
        }
        lines.add(Component.translatable("quarkblocks.misc.ancient_tome_tooltip", Component.translatable(e.getDescriptionId()),
                Component.translatable("enchantment.level." + (e.getMaxLevel() + 1))).withStyle(ChatFormatting.GRAY));
    }

    @SubscribeEvent(priority = EventPriority.HIGHEST)
    public static void anvil(AnvilUpdateEvent event) {
        ItemStack left = event.getLeft();
        ItemStack right = event.getRight();
        if (left.isEmpty() || right.isEmpty() || left.getCount() != 1 || right.getCount() != 1) return;
        ItemStack out;
        int cost;
        if (right.getItem() instanceof AncientTomeItem) {
            Enchantment e = enchantment(right);
            Map<Enchantment, Integer> enchants = EnchantmentHelper.getEnchantments(left);
            if (e == null || !enchants.containsKey(e) || enchants.get(e) > e.getMaxLevel()) return;
            int level = enchants.get(e) + 1;
            enchants.put(e, level);
            out = left.copy();
            EnchantmentHelper.setEnchantments(enchants, out);
            cost = level > e.getMaxLevel() ? LIMIT_BREAK_COST : NORMAL_COST;
        } else if (right.is(Items.ENCHANTED_BOOK)) {
            Map<Enchantment, Integer> current = EnchantmentHelper.getEnchantments(left);
            boolean overlevel = false;
            boolean matching = false;
            for (Map.Entry<Enchantment, Integer> entry : EnchantmentHelper.getEnchantments(right).entrySet()) {
                Enchantment e = entry.getKey();
                if (e == null) continue;
                if (entry.getValue() > e.getMaxLevel()) {
                    overlevel = true;
                    if (e.canEnchant(left) || left.is(Items.ENCHANTED_BOOK)) {
                        matching = true;
                        for (Iterator<Enchantment> it = current.keySet().iterator(); it.hasNext(); ) {
                            Enchantment other = it.next();
                            if (other != e && !other.isCompatibleWith(e)) it.remove();
                        }
                        current.put(e, entry.getValue());
                    }
                } else if (e.canEnchant(left) && current.keySet().stream()
                        .allMatch(other -> other == e || other == null || other.isCompatibleWith(e))) {
                    current.put(e, entry.getValue());
                }
            }
            if (!overlevel || !matching) return;
            out = left.copy();
            EnchantmentHelper.setEnchantments(current, out);
            cost = NORMAL_COST;
        } else {
            return;
        }
        String name = event.getName();
        if (name != null && !name.isEmpty() && (!out.hasCustomHoverName() || !out.getHoverName().getString().equals(name))) {
            out.setHoverName(Component.literal(name));
            cost++;
        }
        event.setOutput(out);
        event.setCost(cost);
    }
}
