"""What omni-server@.service runs: `prestart`, `run` and `stop`, each with a server
id. `run` becomes the server itself, so systemd's main PID is the JVM."""

import os
import sys
import time

import servers

#--- Just under TimeoutStopSec in default.nix, so SIGTERM is the fallback
STOP_TIMEOUT = 280


def prestart(cfg):
    """Keep the last run's console and apply settings saved while the server ran."""
    log = f"{servers.state_dir(cfg['id'])}/console.log"
    if os.path.exists(log):
        os.replace(log, f"{log}.1")
    servers.apply_pending(cfg)


def run(cfg):
    argv = servers.launch_argv(cfg)
    os.chdir(cfg["dir"])
    os.execvp(argv[0], argv)


def stop(cfg):
    """Ask the server to save and stop, then wait for it, since systemd signals the
    main process as soon as ExecStop returns."""
    pid = int(os.environ.get("MAINPID") or 0)
    try:
        servers.send(cfg, "stop")
    except servers.ServerError:
        return
    deadline = time.time() + STOP_TIMEOUT
    while pid and os.path.exists(f"/proc/{pid}") and time.time() < deadline:
        time.sleep(0.5)


def main():
    action, server_id = sys.argv[1], sys.argv[2]
    try:
        cfg = servers.load(server_id)
        {"prestart": prestart, "run": run, "stop": stop}[action](cfg)
    except servers.ServerError as e:
        print(f"omni-server: {e}", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
