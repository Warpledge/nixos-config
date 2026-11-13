package warpledge.quarkblocks;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.player.Inventory;

/** The crate's screen (Quark's CrateScreen, CC BY-NC-SA 3.0): scroll bar and an item count. */
public class CrateScreen extends AbstractContainerScreen<CrateMenu> {
    private static final ResourceLocation TEXTURE = QuarkBlocks.rl("textures/gui/crate.png");
    private static final int TEXT = 0x404040;
    private int lastScroll;
    private int scrollOffs;
    private boolean scrolling;

    public CrateScreen(CrateMenu menu, Inventory inv, Component title) {
        super(menu, inv, title);
        imageHeight = 114 + CrateMenu.ROWS * 18;
        inventoryLabelY = imageHeight - 94;
    }

    @Override
    public void render(GuiGraphics g, int mouseX, int mouseY, float partial) {
        renderBackground(g);
        super.render(g, mouseX, mouseY, partial);
        renderTooltip(g, mouseX, mouseY);
    }

    private boolean canScroll() {
        return menu.stackCount() / CrateMenu.COLS > 0;
    }

    private float pxPerScroll() {
        return 95F / (menu.stackCount() / CrateMenu.COLS);
    }

    @Override
    public boolean mouseScrolled(double x, double y, double delta) {
        menu.scroll(delta < 0, true);
        lastScroll = scrollOffs = Math.round((menu.scroll / CrateMenu.COLS) * pxPerScroll());
        return true;
    }

    @Override
    public boolean mouseClicked(double x, double y, int button) {
        if (button == 0 && insideScrollbar(x, y)) {
            scrolling = canScroll();
            return true;
        }
        return super.mouseClicked(x, y, button);
    }

    private boolean insideScrollbar(double x, double y) {
        int left = leftPos + 175, top = topPos + 18;
        return x >= left && y >= top && x < left + 14 && y < top + 112;
    }

    @Override
    public boolean mouseDragged(double x, double y, int button, double dx, double dy) {
        if (!scrolling) return super.mouseDragged(x, y, button, dx, dy);
        scrollOffs = (int) Math.max(0, Math.min(95, y - (topPos + 18) - 6));
        float px = pxPerScroll();
        float diff = scrollOffs - lastScroll;
        while (Math.abs(diff) >= px) {
            menu.scroll(diff > 0, true);
            lastScroll = Math.round((menu.scroll / CrateMenu.COLS) * px);
            diff = scrollOffs - lastScroll;
        }
        return true;
    }

    @Override
    public boolean mouseReleased(double x, double y, int button) {
        if (button == 0) scrolling = false;
        return super.mouseReleased(x, y, button);
    }

    @Override
    protected void renderBg(GuiGraphics g, float partial, int mouseX, int mouseY) {
        int i = (width - imageWidth) / 2, j = (height - imageHeight) / 2;
        g.blit(TEXTURE, i, j, 0, 0, imageWidth + 20, imageHeight);
        int maxScroll = (menu.stackCount() / CrateMenu.COLS) * CrateMenu.COLS;
        g.blit(TEXTURE, i + imageWidth, j + 18 + scrollOffs, 232 + (maxScroll == 0 ? 12 : 0), 0, 12, 15);
        String count = menu.total() + "/" + CrateItemHandler.MAX_ITEMS;
        g.drawString(font, count, i + imageWidth - font.width(count) - 8, j + 6, TEXT, false);
    }

    @Override
    protected void renderLabels(GuiGraphics g, int mouseX, int mouseY) {
        g.drawString(font, title, titleLabelX, titleLabelY, TEXT, false);
        g.drawString(font, playerInventoryTitle, inventoryLabelX, inventoryLabelY, TEXT, false);
    }
}
