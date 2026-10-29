// Loads the CSS matugen renders from matugen.css.matugen beside this file into
// every window, and again whenever matugen rewrites it.
"use strict";
const {app, webContents} = require("electron");
const fs = require("fs");
const path = require("path");

const config = process.env.XDG_CONFIG_HOME || path.join(app.getPath("home"), ".config");
const dir = path.join(config, "claude-desktop");
const file = path.join(dir, "matugen.css");
const keys = new Map();
const queues = new Map();

const read = () => {
  try {
    return fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
};

// One insert at a time per window, so a stale key never outlives its replacement
const apply = (wc, css) => {
  const next = (queues.get(wc.id) || Promise.resolve()).then(async () => {
    if (wc.isDestroyed()) return;
    const old = keys.get(wc.id);
    keys.delete(wc.id);
    if (old) await wc.removeInsertedCSS(old).catch(() => {});
    if (css && !wc.isDestroyed()) keys.set(wc.id, await wc.insertCSS(css));
  }).catch(() => {});
  queues.set(wc.id, next);
};

app.on("web-contents-created", (_, wc) => {
  const id = wc.id;
  wc.on("dom-ready", () => apply(wc, read()));
  wc.once("destroyed", () => {
    keys.delete(id);
    queues.delete(id);
  });
});

let timer;
try {
  fs.watch(dir, (_, name) => {
    if (name && name !== "matugen.css") return;
    clearTimeout(timer);
    timer = setTimeout(() => {
      const css = read();
      for (const wc of webContents.getAllWebContents()) apply(wc, css);
    }, 200);
  });
} catch {}
