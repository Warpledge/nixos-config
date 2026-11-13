package warpledge.quarkblocks;

import java.util.function.Supplier;
import net.minecraft.network.FriendlyByteBuf;
import net.minecraftforge.network.NetworkEvent;
import net.minecraftforge.network.NetworkRegistry;
import net.minecraftforge.network.simple.SimpleChannel;

/** quarkblocks' packets: the crate screen's scroll, which the server's menu must follow. */
final class Network {
    private static final String VERSION = "1";
    private static final SimpleChannel CHANNEL = NetworkRegistry.newSimpleChannel(
            QuarkBlocks.rl("main"), () -> VERSION, VERSION::equals, VERSION::equals);

    private Network() {}

    static void register() {
        CHANNEL.registerMessage(0, ScrollCrate.class, ScrollCrate::write, ScrollCrate::read, ScrollCrate::handle);
    }

    static void scrollCrate(boolean down) {
        CHANNEL.sendToServer(new ScrollCrate(down));
    }

    record ScrollCrate(boolean down) {
        void write(FriendlyByteBuf buf) {
            buf.writeBoolean(down);
        }

        static ScrollCrate read(FriendlyByteBuf buf) {
            return new ScrollCrate(buf.readBoolean());
        }

        void handle(Supplier<NetworkEvent.Context> ctx) {
            ctx.get().enqueueWork(() -> {
                var player = ctx.get().getSender();
                if (player != null && player.containerMenu instanceof CrateMenu m) m.scroll(down, false);
            });
            ctx.get().setPacketHandled(true);
        }
    }
}
