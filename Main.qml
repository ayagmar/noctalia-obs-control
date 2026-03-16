import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  required property var pluginApi

  visible: false
  width: 0
  height: 0

  readonly property var defaults: pluginApi && pluginApi.manifest && pluginApi.manifest.metadata
                                   ? (pluginApi.manifest.metadata.defaultSettings || {})
                                   : ({})
  readonly property var pluginSettings: pluginApi ? (pluginApi.pluginSettings || {}) : ({})
  readonly property string obsctlPath: pluginApi ? (pluginApi.pluginDir + "/scripts/obsctl") : ""
  readonly property string actionRunnerPath: pluginApi ? (pluginApi.pluginDir + "/scripts/run-action") : ""
  readonly property string openPathHelper: pluginApi ? (pluginApi.pluginDir + "/scripts/open-path") : ""
  readonly property string actionEventPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/obs-control-action.json"
  readonly property string configuredVideosPath: pluginSettings.videosPath !== undefined
                                                 ? String(pluginSettings.videosPath).trim()
                                                 : String(defaults.videosPath !== undefined ? defaults.videosPath : "")
  readonly property string videosPath: configuredVideosPath !== ""
                                       ? configuredVideosPath
                                       : (Quickshell.env("XDG_VIDEOS_DIR") || ((Quickshell.env("HOME") || "") + "/Videos"))
  readonly property int pollIntervalMs: Math.max(
                                          750,
                                          Number(pluginSettings.pollIntervalMs !== undefined
                                                   ? pluginSettings.pollIntervalMs
                                                   : (defaults.pollIntervalMs !== undefined ? defaults.pollIntervalMs : 2500))
                                        )
  readonly property string leftClickAction: pluginSettings.leftClickAction !== undefined
                                            ? String(pluginSettings.leftClickAction)
                                            : String(defaults.leftClickAction !== undefined ? defaults.leftClickAction : "panel")
  readonly property bool showBarWhenRecording: pluginSettings.showBarWhenRecording !== undefined
                                               ? Boolean(pluginSettings.showBarWhenRecording)
                                               : Boolean(defaults.showBarWhenRecording)
  readonly property bool showBarWhenReplay: pluginSettings.showBarWhenReplay !== undefined
                                            ? Boolean(pluginSettings.showBarWhenReplay)
                                            : Boolean(defaults.showBarWhenReplay)
  readonly property bool showControlCenterWhenRecording: pluginSettings.showControlCenterWhenRecording !== undefined
                                                         ? Boolean(pluginSettings.showControlCenterWhenRecording)
                                                         : Boolean(defaults.showControlCenterWhenRecording)
  readonly property bool showControlCenterWhenReplay: pluginSettings.showControlCenterWhenReplay !== undefined
                                                      ? Boolean(pluginSettings.showControlCenterWhenReplay)
                                                      : Boolean(defaults.showControlCenterWhenReplay)
  readonly property bool showControlCenterWhenReady: pluginSettings.showControlCenterWhenReady !== undefined
                                                     ? Boolean(pluginSettings.showControlCenterWhenReady)
                                                     : Boolean(defaults.showControlCenterWhenReady)

  property bool obsRunning: false
  property bool websocket: false
  property bool recording: false
  property bool replayBuffer: false
  property string lastActionEventId: ""
  readonly property bool connected: obsRunning && websocket
  readonly property bool showInBar: (recording && showBarWhenRecording)
                                    || (replayBuffer && showBarWhenReplay)
  readonly property bool showInControlCenter: (recording && showControlCenterWhenRecording)
                                              || (replayBuffer && showControlCenterWhenReplay)
                                              || (connected && showControlCenterWhenReady)
  readonly property string primaryActionText: leftClickAction === "toggle-record" ? "toggles recording" : "opens controls"

  function applyStatus(payload) {
    obsRunning = Boolean(payload && payload.obsRunning);
    websocket = Boolean(payload && payload.websocket);
    recording = Boolean(payload && payload.recording);
    replayBuffer = Boolean(payload && payload.replayBuffer);
  }

  function resetStatus() {
    applyStatus({
      "obsRunning": false,
      "websocket": false,
      "recording": false,
      "replayBuffer": false
    });
  }

  function refresh() {
    if (!statusProcess.running) {
      statusProcess.running = true;
    }
  }

  function runAction(action) {
    if (!actionProcess.running) {
      pendingAction = action;
      actionProcess.running = true;
    }
  }

  function launchObs() {
    runAction("launch");
  }

  function toggleRecord() {
    runAction("toggle-record");
  }

  function toggleReplay() {
    runAction("toggle-replay");
  }

  function saveReplay() {
    runAction("save-replay");
  }

  function openVideos() {
    if (videosPath !== "") {
      Quickshell.execDetached([openPathHelper, videosPath]);
    }
  }

  function showActionToast(payload) {
    if (!payload || !payload.title) {
      return;
    }

    const actionLabel = payload.openVideos ? "Open Videos" : "";
    const actionCallback = payload.openVideos ? function () { root.openVideos(); } : null;
    ToastService.showNotice(payload.title, payload.body || "", "", 3200, actionLabel, actionCallback);
  }

  function openControls(screen, anchorItem) {
    if (pluginApi && screen) {
      pluginApi.togglePanel(screen, anchorItem);
    }
  }

  function runPrimaryAction(screen, anchorItem) {
    if (leftClickAction === "toggle-record") {
      runSecondaryAction();
      return;
    }

    openControls(screen, anchorItem);
  }

  function runSecondaryAction() {
    if (!obsRunning) {
      launchObs();
    } else if (connected) {
      toggleRecord();
    } else {
      refresh();
    }
  }

  function runMiddleAction() {
    if (connected) {
      toggleReplay();
    }
  }

  Component.onCompleted: refresh()

  property string pendingAction: ""

  Timer {
    id: pollTimer
    interval: root.pollIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: actionRefreshTimer
    interval: 900
    running: false
    repeat: false
    onTriggered: root.refresh()
  }

  FileView {
    id: actionEventView
    path: root.actionEventPath
    printErrors: false
    watchChanges: true

    onLoaded: {
      try {
        const payload = JSON.parse(String(text() || "").trim() || "{}");
        if (!payload || !payload.eventId || payload.eventId === root.lastActionEventId) {
          return;
        }
        root.lastActionEventId = payload.eventId;
        root.showActionToast(payload);
        root.refresh();
      } catch (e) {}
    }

    onLoadFailed: function() {}
  }

  Process {
    id: actionProcess
    running: false
    command: pendingAction === "" ? [] : [root.obsctlPath, pendingAction]
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      const output = String(stdout.text || "").trim();
      if (exitCode === 0 && output !== "") {
        try {
          root.showActionToast(JSON.parse(output));
        } catch (e) {}
      }

      pendingAction = "";
      actionRefreshTimer.restart();
    }
  }

  Process {
    id: statusProcess
    running: false
    command: [root.obsctlPath, "status"]
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.resetStatus();
        return;
      }

      try {
        root.applyStatus(JSON.parse(String(stdout.text || "").trim() || "{}"));
      } catch (e) {
        root.resetStatus();
      }
    }
  }
}
