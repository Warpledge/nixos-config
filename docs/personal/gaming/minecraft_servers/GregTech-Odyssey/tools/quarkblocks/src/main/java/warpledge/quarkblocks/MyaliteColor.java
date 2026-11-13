package warpledge.quarkblocks;

import java.awt.Color;
import java.util.List;
import net.minecraft.core.BlockPos;
import net.minecraft.util.Mth;
import net.minecraft.world.level.levelgen.LegacyRandomSource;
import net.minecraft.world.level.levelgen.synth.PerlinSimplexNoise;

/** Myalite's hue drifting with position (Quark's MyaliteColorLogic, CC BY-NC-SA 3.0). */
final class MyaliteColor {
    private static final PerlinSimplexNoise NOISE = new PerlinSimplexNoise(
            new LegacyRandomSource(4543543), List.of(-4, -3, -2, -1, 0, 1, 2, 3, 4));

    private MyaliteColor() {}

    static int at(BlockPos pos) {
        if (pos == null) pos = BlockPos.ZERO;
        float x = pos.getX() * 0.15F, y = pos.getY() * 0.15F, z = pos.getZ() * 0.15F;
        double xv = x + Mth.sin(z) * 2, zv = z + Mth.cos(x) * 2, yv = y + Mth.sin(y + Mth.PI / 4) * 2;
        double n = NOISE.getValue(xv + yv, zv + yv * 2, false);
        return Color.HSBtoRGB((float) (n * 0.15 - 0.3 + 0.05), 0.7F, 0.8F);
    }
}
