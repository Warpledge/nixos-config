package warpledge.quarkblocks;

import java.util.List;
import java.util.Random;
import net.minecraft.core.BlockPos;
import net.minecraft.core.NonNullList;
import net.minecraft.core.particles.ItemParticleOption;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.world.ContainerHelper;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.animal.Animal;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.DispenserMenu;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.block.entity.RandomizableContainerBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

/**
 * quarkblocks:feeding_trough (Quark's FeedingTroughBlockEntity, CC BY-NC-SA 3.0). Holds a
 * loot table or "Items" like a dispenser; "rng" is its own breeding roll seed.
 */
public class FeedingTroughBlockEntity extends RandomizableContainerBlockEntity {
    static final double LOVE_CHANCE = 0.333333333;
    static final double RANGE = 10;
    static final int MAX_ANIMALS = 32;

    private NonNullList<ItemStack> stacks = NonNullList.withSize(9, ItemStack.EMPTY);
    private long rng;

    enum Fed { FED, LOVE, NONE }

    public FeedingTroughBlockEntity(BlockPos pos, BlockState state) {
        super(QuarkBlocks.TROUGH_BE.get(), pos, state);
    }

    boolean hasFoodFor(Animal animal) {
        unpackLootTable(null);
        for (ItemStack s : stacks) if (animal.isFood(s)) return true;
        return false;
    }

    Fed tryFeeding(Animal animal) {
        unpackLootTable(null);
        for (ItemStack stack : stacks) {
            if (!animal.isFood(stack)) continue;
            SoundEvent sound = animal.getEatingSound(stack);
            animal.playSound(sound, 0.5F + 0.5F * level.random.nextInt(2),
                    (level.random.nextFloat() - level.random.nextFloat()) * 0.2F + 1.0F);
            particles(animal, stack);
            stack.shrink(1);
            setChanged();
            Random roll = new Random(rng);
            rng = roll.nextLong();
            if (roll.nextDouble() < LOVE_CHANCE) {
                List<Animal> around = level.getEntitiesOfClass(Animal.class, new AABB(worldPosition).inflate(RANGE));
                if (around.size() <= MAX_ANIMALS) animal.setInLove(null);
                return Fed.LOVE;
            }
            return Fed.FED;
        }
        return Fed.NONE;
    }

    @Override
    public void setChanged() {
        super.setChanged();
        BlockState state = getBlockState();
        if (level != null && state.getBlock() instanceof FeedingTroughBlock) {
            boolean full = !isEmpty();
            if (state.getValue(FeedingTroughBlock.FULL) != full) {
                level.setBlock(worldPosition, state.setValue(FeedingTroughBlock.FULL, full), 2);
            }
        }
    }

    private void particles(Entity e, ItemStack stack) {
        if (!(level instanceof ServerLevel server)) return;
        for (int i = 0; i < 16; i++) {
            Vec3 dir = new Vec3((e.level().random.nextFloat() - 0.5) * 0.1, Math.random() * 0.1 + 0.1, 0)
                    .xRot(-e.getXRot() * ((float) Math.PI / 180F)).yRot(-e.getYRot() * ((float) Math.PI / 180F));
            double dy = -e.level().random.nextFloat() * 0.6 - 0.3;
            Vec3 p = new Vec3((e.level().random.nextFloat() - 0.5) * 0.3, dy, 0.6)
                    .xRot(-e.getXRot() * ((float) Math.PI / 180F)).yRot(-e.getYRot() * ((float) Math.PI / 180F))
                    .add(e.getX(), e.getY() + e.getEyeHeight(), e.getZ());
            server.sendParticles(new ItemParticleOption(ParticleTypes.ITEM, stack), p.x, p.y, p.z, 1,
                    dir.x, dir.y + 0.05, dir.z, 0);
        }
    }

    @Override
    public int getContainerSize() {
        return 9;
    }

    @Override
    public boolean isEmpty() {
        for (ItemStack s : stacks) if (!s.isEmpty()) return false;
        return true;
    }

    @Override
    protected Component getDefaultName() {
        return Component.translatable("quarkblocks.container.feeding_trough");
    }

    @Override
    public void load(CompoundTag tag) {
        super.load(tag);
        rng = tag.getLong("rng");
        stacks = NonNullList.withSize(getContainerSize(), ItemStack.EMPTY);
        if (!tryLoadLootTable(tag)) ContainerHelper.loadAllItems(tag, stacks);
    }

    @Override
    protected void saveAdditional(CompoundTag tag) {
        super.saveAdditional(tag);
        tag.putLong("rng", rng);
        if (!trySaveLootTable(tag)) ContainerHelper.saveAllItems(tag, stacks);
    }

    @Override
    protected NonNullList<ItemStack> getItems() {
        return stacks;
    }

    @Override
    protected void setItems(NonNullList<ItemStack> items) {
        stacks = items;
    }

    @Override
    protected AbstractContainerMenu createMenu(int id, Inventory inv) {
        return new DispenserMenu(id, inv, this) {
            @Override
            public MenuType<?> getType() {
                return QuarkBlocks.TROUGH_MENU.get();
            }
        };
    }
}
