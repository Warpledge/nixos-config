package com.github.alexthe666.alexsmobs.effect;

import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.Ingredient;
import net.minecraftforge.common.brewing.IBrewingRecipe;

// Alex's Mobs Continued 2.3.0's class (SRG names, as in the jar), no longer a Forge
// BrewingRecipe. GTO's EMI ids those brewing/forge/<input>/<ingredient>/<output> by
// item, so potion-to-potion recipes share ids and gtolib's EMI bake crashes. EMI
// skips a plain IBrewingRecipe; the brewing stand still uses it.
public class ProperBrewingRecipe implements IBrewingRecipe {
    private final ItemStack input;
    private final Ingredient ingredient;
    private final ItemStack output;

    public ProperBrewingRecipe(ItemStack input, Ingredient ingredient, ItemStack output) {
        this.input = input;
        this.ingredient = ingredient;
        this.output = output;
    }

    @Override
    public boolean isInput(ItemStack stack) {
        if (stack == null) {
            return false;
        }
        return ItemStack.m_41656_(stack, this.input) && ItemStack.m_150942_(this.input, stack);
    }

    @Override
    public boolean isIngredient(ItemStack stack) {
        return this.ingredient.test(stack);
    }

    @Override
    public ItemStack getOutput(ItemStack input, ItemStack ingredient) {
        return isInput(input) && isIngredient(ingredient) ? this.output.m_41777_() : ItemStack.f_41583_;
    }
}
