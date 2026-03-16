#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const action = process.argv[2];
const validCommands = new Set(["launch", "toggle-record", "toggle-replay", "save-replay"]);

if (!validCommands.has(action)) {
  console.error("usage: run-action <launch|toggle-record|toggle-replay|save-replay>");
  process.exit(2);
}

const scriptDir = __dirname;
const obsctlJs = path.join(scriptDir, "obsctl.js");
const runtimeDir = process.env.XDG_RUNTIME_DIR || "/tmp";
const eventPath = path.join(runtimeDir, "obs-control-action.json");

function writeEvent(payload) {
  const eventPayload = {
    ...payload,
    eventId: `${Date.now()}-${process.pid}-${Math.random().toString(16).slice(2, 10)}`,
  };
  fs.writeFileSync(eventPath, `${JSON.stringify(eventPayload)}\n`, "utf8");
}

const child = spawnSync(process.execPath, [obsctlJs, action], {
  encoding: "utf8",
});

const stdout = String(child.stdout || "").trim();
const stderr = String(child.stderr || "").trim();

if (child.status === 0) {
  if (stdout) {
    try {
      const payload = JSON.parse(stdout);
      if (payload && payload.title) {
        writeEvent(payload);
      }
    } catch {}
    process.stdout.write(`${stdout}\n`);
  }
  process.exit(0);
}

const payload = {
  ok: false,
  event: "error",
  title: "OBS control failed",
  body: stderr || "Check the OBS helper output.",
};
writeEvent(payload);
if (stderr) {
  process.stderr.write(`${stderr}\n`);
}
process.exit(child.status || 1);
