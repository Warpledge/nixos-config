package warpledge.quarkblocks;

import net.minecraft.util.StringRepresentable;

/**
 * Quark's string property values that no vanilla enum covers: post connections, the
 * crafter's power, the redstone randomizer's side and the vertical slab's type. gen.py
 * fails if a block needs a value missing here.
 */
public enum Token implements StringRepresentable {
    NONE, CHAIN, OTHER_POST, OFF, ON, TRIGGERED, LEFT, RIGHT, NORTH, SOUTH, EAST, WEST, DOUBLE;

    @Override
    public String getSerializedName() {
        return name().toLowerCase(java.util.Locale.ROOT);
    }
}
