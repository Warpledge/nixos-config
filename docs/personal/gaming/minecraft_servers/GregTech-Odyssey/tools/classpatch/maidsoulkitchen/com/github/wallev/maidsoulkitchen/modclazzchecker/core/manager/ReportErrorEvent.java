package com.github.wallev.maidsoulkitchen.modclazzchecker.core.manager;

import net.minecraftforge.event.entity.player.PlayerEvent;

// Maidsoul Kitchen 0.3.0.9's class with its login message off. The original registers
// on the Forge bus and, at login, posts a chat warning for every task whose classes
// failed its check (here Youkai's kettle and fermentation tank through Maid Storage
// Manager), with no config to stop it. Failed tasks stay off, and the analysis file
// in logs/ and the log lines are still written.
public class ReportErrorEvent {
    private final BaseClazzCheckManager<?, ?> checkManager;

    private ReportErrorEvent(BaseClazzCheckManager<?, ?> checkManager) {
        this.checkManager = checkManager;
    }

    public void reportError(PlayerEvent.PlayerLoggedInEvent event) {
    }

    public static void init(BaseClazzCheckManager<?, ?> checkManager) {
    }
}
