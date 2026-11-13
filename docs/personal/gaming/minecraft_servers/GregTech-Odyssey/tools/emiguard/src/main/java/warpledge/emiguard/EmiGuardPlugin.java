package warpledge.emiguard;

import dev.emi.emi.api.EmiPlugin;
import dev.emi.emi.api.EmiRegistry;
import dev.emi.emi.api.recipe.EmiRecipe;
import dev.emi.emi.api.recipe.EmiRecipeCategory;
import dev.emi.emi.api.stack.EmiIngredient;
import dev.emi.emi.api.stack.EmiStack;
import dev.emi.emi.registry.EmiRecipes;
import dev.emi.emi.registry.EmiStackList;
import it.unimi.dsi.fastutil.Hash;
import it.unimi.dsi.fastutil.objects.Object2ObjectOpenCustomHashMap;
import it.unimi.dsi.fastutil.objects.ObjectArrayList;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Drops EMI recipes that would crash gtolib's native recipe index during EMI's bake,
 * and logs each one. GTO loads this only when its class is listed under
 * misc.enableEmiJeiExternalPlugins in config/gtocore.yaml.
 *
 * <p>The checks mirror what the EMI fork's Java EmiRecipeIndex walks: each recipe's
 * inputs, catalysts and outputs, each ingredient's stacks, and a stack-keyed map
 * using EMI's own ComparisonHashStrategy, which gtolib's version replaces.
 */
public class EmiGuardPlugin implements EmiPlugin {
    private static final Logger LOG = LoggerFactory.getLogger("emiguard");

    @Override
    public void register(EmiRegistry registry) {
        Set<EmiRecipe> bad = Collections.newSetFromMap(new IdentityHashMap<>());
        boolean[] scanned = {false};
        registry.removeRecipes(recipe -> {
            // bake() fills its recipe list before running the filters, so the first
            // call can see every recipe at once.
            if (!scanned[0]) {
                scanned[0] = true;
                scan(bad);
            }
            return bad.contains(recipe);
        });
    }

    private static void scan(Set<EmiRecipe> bad) {
        List<EmiRecipe> recipes;
        try {
            Field f = EmiRecipes.class.getDeclaredField("recipes");
            f.setAccessible(true);
            @SuppressWarnings("unchecked")
            List<EmiRecipe> list = (List<EmiRecipe>) f.get(null);
            recipes = new ArrayList<>(list);
        } catch (ReflectiveOperationException | RuntimeException e) {
            LOG.error("[emiguard] can't read EmiRecipes.recipes; nothing checked", e);
            return;
        }

        Hash.Strategy<EmiStack> strategy = new EmiStackList.ComparisonHashStrategy();
        Map<EmiStack, List<EmiRecipe>> index = new Object2ObjectOpenCustomHashMap<>(strategy);
        Map<EmiRecipe, List<EmiStack>> stacksOf = new IdentityHashMap<>();
        Map<String, Integer> ids = new HashMap<>();

        // Pass 1: shape checks, then index every stack as gtolib would.
        for (EmiRecipe recipe : recipes) {
            if (recipe == null) {
                LOG.warn("[emiguard] null recipe in EMI's list");
                continue;
            }
            try {
                String problem = shapeProblem(recipe);
                if (problem != null) {
                    drop(bad, recipe, problem);
                    continue;
                }
                List<EmiStack> stacks = stacks(recipe);
                stacksOf.put(recipe, stacks);
                for (EmiStack stack : stacks) {
                    index.computeIfAbsent(stack, k -> new ObjectArrayList<>(1)).add(recipe);
                }
                if (recipe.getId() != null) {
                    ids.merge(String.valueOf(recipe.getId()), 1, Integer::sum);
                }
            } catch (Throwable t) {
                drop(bad, recipe, "threw " + t);
            }
        }

        // Pass 2: a stack whose hash or equality changed since it was indexed (it
        // "self-mutated") no longer finds its own entry; gtolib gets null there.
        for (Map.Entry<EmiRecipe, List<EmiStack>> e : stacksOf.entrySet()) {
            EmiRecipe recipe = e.getKey();
            try {
                for (EmiStack stack : e.getValue()) {
                    if (index.get(stack) == null) {
                        drop(bad, recipe, "stack self-mutated after indexing: " + describe(stack));
                        break;
                    }
                }
                if (!bad.contains(recipe) && !stacks(recipe).equals(e.getValue())) {
                    // Equal by List.equals means each stack's equals() still holds.
                    drop(bad, recipe, "returns different stacks on a second read");
                }
            } catch (Throwable t) {
                drop(bad, recipe, "threw on second read " + t);
            }
        }

        checkCategories(recipes, bad);

        ids.forEach((id, n) -> {
            if (n > 1) {
                LOG.warn("[emiguard] {} recipes share the id {} (kept)", n, id);
            }
        });
        LOG.info("[emiguard] checked {} recipes, dropped {}", recipes.size(), bad.size());
    }

    /**
     * A recipe in a category nobody registered, or a registered category or workstation
     * entry left with no recipes, has no entry in the by-category map; gtolib's index
     * may look one up and get null. Unregistered recipes are dropped; the rest is
     * written to the dump for diffing.
     */
    private static void checkCategories(List<EmiRecipe> recipes, Set<EmiRecipe> bad) {
        try {
            Set<EmiRecipeCategory> registered =
                    Collections.newSetFromMap(new IdentityHashMap<>());
            registered.addAll(EmiRecipes.categories);
            // Survivors: what bake() keeps after every other filter, ours aside.
            List<Predicate<EmiRecipe>> others = new ArrayList<>(EmiRecipes.invalidators);
            Set<EmiRecipeCategory> used = Collections.newSetFromMap(new IdentityHashMap<>());
            Map<String, Integer> unregistered = new HashMap<>();
            for (EmiRecipe recipe : recipes) {
                if (recipe == null || bad.contains(recipe)) continue;
                EmiRecipeCategory cat = recipe.getCategory();
                if (!registered.contains(cat)) {
                    unregistered.merge(String.valueOf(cat.getId()), 1, Integer::sum);
                    bad.add(recipe);
                    continue;
                }
                boolean kept = true;
                for (Predicate<EmiRecipe> p : others) {
                    try {
                        if (p.test(recipe)) {
                            kept = false;
                            break;
                        }
                    } catch (Throwable t) {
                        // our own filter (not yet installed in the list) or a broken one
                    }
                }
                if (kept) used.add(cat);
            }
            unregistered.forEach((id, n) -> LOG.warn(
                    "[emiguard] dropped {} recipes in unregistered category {}", n, id));

            // Not removed: GT's categories look empty here because gtolib's index adds
            // GT's recipes itself, and main has empty categories without crashing.
            dump(recipes, registered, used);
        } catch (Throwable t) {
            LOG.error("[emiguard] category check failed", t);
        }
    }

    /**
     * Writes what EMI hands the index to emiguard-dump.txt in the game folder, sorted
     * so a run with a suspect mod can be diffed against one without it.
     */
    private static void dump(List<EmiRecipe> recipes, Set<EmiRecipeCategory> registered,
            Set<EmiRecipeCategory> used) throws Exception {
        List<String> lines = new ArrayList<>();
        for (EmiRecipeCategory cat : registered) {
            lines.add("category " + cat.getId() + " " + cat.getClass().getName()
                    + (used.contains(cat) ? "" : " (no plugin recipes)"));
        }
        Field wf = EmiRecipes.class.getDeclaredField("workstations");
        wf.setAccessible(true);
        for (Map.Entry<?, ?> e : ((Map<?, ?>) wf.get(null)).entrySet()) {
            Object key = e.getKey();
            Object id = key instanceof EmiRecipeCategory c ? c.getId() : key;
            for (Object ing : (List<?>) e.getValue()) {
                lines.add("workstation " + id + " " + ing.getClass().getName() + " "
                        + stackIds((EmiIngredient) ing)
                        + (registered.contains(key) ? "" : " (unregistered category)"));
            }
        }
        for (EmiRecipe recipe : recipes) {
            if (recipe == null) continue;
            lines.add("recipe " + recipe.getId() + " " + recipe.getCategory().getId() + " "
                    + recipe.getClass().getName());
        }
        Collections.sort(lines);
        java.nio.file.Files.write(java.nio.file.Path.of("emiguard-dump.txt"), lines);
        LOG.info("[emiguard] wrote {} lines to emiguard-dump.txt", lines.size());
    }

    private static String stackIds(EmiIngredient ing) {
        List<String> ids = new ArrayList<>();
        List<EmiStack> stacks = ing.getEmiStacks();
        if (stacks == null) return "NULL-STACKS";
        for (EmiStack s : stacks) ids.add(s == null ? "NULL" : String.valueOf(s.getId()));
        return String.join(",", ids);
    }

    /** Null lists or null entries anywhere gtolib iterates. */
    private static String shapeProblem(EmiRecipe recipe) {
        if (recipe.getCategory() == null) return "null category";
        String s = listProblem("inputs", recipe.getInputs());
        if (s == null) s = listProblem("catalysts", recipe.getCatalysts());
        if (s != null) return s;
        List<EmiStack> outputs = recipe.getOutputs();
        if (outputs == null) return "null outputs";
        for (EmiStack out : outputs) {
            if (out == null) return "null output stack";
        }
        return null;
    }

    private static String listProblem(String what, List<EmiIngredient> list) {
        if (list == null) return "null " + what;
        for (EmiIngredient ing : list) {
            if (ing == null) return "null entry in " + what;
            List<EmiStack> stacks = ing.getEmiStacks();
            if (stacks == null) return "null getEmiStacks() in " + what + ": " + ing;
            for (EmiStack stack : stacks) {
                if (stack == null) return "null stack in " + what + ": " + ing;
            }
        }
        return null;
    }

    private static List<EmiStack> stacks(EmiRecipe recipe) {
        List<EmiStack> out = new ArrayList<>();
        for (EmiIngredient ing : recipe.getInputs()) out.addAll(ing.getEmiStacks());
        for (EmiIngredient ing : recipe.getCatalysts()) out.addAll(ing.getEmiStacks());
        out.addAll(recipe.getOutputs());
        return out;
    }

    private static void drop(Set<EmiRecipe> bad, EmiRecipe recipe, String why) {
        if (!bad.add(recipe)) return;
        String category;
        try {
            category = String.valueOf(recipe.getCategory().getId());
        } catch (Throwable t) {
            category = "?";
        }
        String id;
        try {
            id = String.valueOf(recipe.getId());
        } catch (Throwable t) {
            id = "?";
        }
        LOG.warn("[emiguard] dropped {} ({}, category {}): {}",
                id, recipe.getClass().getName(), category, why);
    }

    private static String describe(EmiStack stack) {
        try {
            return stack.getId() + " " + stack.getNbt();
        } catch (Throwable t) {
            return stack.getClass().getName();
        }
    }
}
