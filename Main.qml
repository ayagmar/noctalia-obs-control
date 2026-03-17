import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import "I18n.js" as I18n

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
  readonly property string openPathHelper: pluginApi ? (pluginApi.pluginDir + "/scripts/open-path") : ""
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
  property int recordDurationMs: 0
  property int displayRecordDurationMs: 0
  readonly property bool connected: obsRunning && websocket
  readonly property bool showInBar: (recording && showBarWhenRecording)
                                    || (replayBuffer && showBarWhenReplay)
  readonly property bool showInControlCenter: (recording && showControlCenterWhenRecording)
                                              || (replayBuffer && showControlCenterWhenReplay)
                                              || (connected && showControlCenterWhenReady)
  readonly property string primaryActionText: leftClickAction === "toggle-record"
                                                ? tr("actions.primary.toggle_record", "toggles recording")
                                                : tr("actions.primary.open_controls", "opens controls")

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations);
  }

  function applyStatus(payload) {
    obsRunning = Boolean(payload && payload.obsRunning);
    websocket = Boolean(payload && payload.websocket);
    recording = Boolean(payload && payload.recording);
    replayBuffer = Boolean(payload && payload.replayBuffer);
    recordDurationMs = Math.max(0, Number(payload && payload.recordDurationMs ? payload.recordDurationMs : 0));
    displayRecordDurationMs = recording ? recordDurationMs : 0;
    displayTimer.running = recording;
  }

  function resetStatus() {
    applyStatus({
      "obsRunning": false,
      "websocket": false,
      "recording": false,
      "replayBuffer": false,
      "recordDurationMs": 0
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
    if (!payload) {
      return;
    }

    const translated = translatedActionPayload(payload);
    if (!translated.title) {
      return;
    }

    const actionLabel = payload.openVideos ? tr("toast.actions.open_videos", "Open Videos") : "";
    const actionCallback = payload.openVideos ? function () { root.openVideos(); } : null;
    ToastService.showNotice(translated.title, translated.body, "", 3200, actionLabel, actionCallback);
  }

  function translatedActionPayload(payload) {
    if (!payload) {
      return { title: "", body: "" };
    }

    switch (payload.event) {
    case "record-started":
      return {
        title: tr("toast.record_started.title", "OBS recording started"),
        body: tr("toast.record_started.body", "Local recording is running."),
      };
    case "record-started-launch":
      return {
        title: tr("toast.record_started_launch.title", "OBS recording started"),
        body: tr("toast.record_started_launch.body", "OBS launched in the tray."),
      };
    case "record-stopped":
      return {
        title: tr("toast.record_stopped.title", "OBS recording stopped"),
        body: tr("toast.record_stopped.body", "Recording saved to Videos."),
      };
    case "replay-started":
      return {
        title: tr("toast.replay_started.title", "OBS replay buffer started"),
        body: tr("toast.replay_started.body", "Replay buffer is active."),
      };
    case "replay-started-launch":
      return {
        title: tr("toast.replay_started_launch.title", "OBS replay buffer started"),
        body: tr("toast.replay_started_launch.body", "OBS launched in the tray."),
      };
    case "replay-stopped":
      return {
        title: tr("toast.replay_stopped.title", "OBS replay buffer stopped"),
        body: tr("toast.replay_stopped.body", "Instant replay is off."),
      };
    case "replay-saved":
      return {
        title: tr("toast.replay_saved.title", "OBS replay saved"),
        body: tr("toast.replay_saved.body", "Saved the last replay buffer to Videos."),
      };
    case "offline":
      return {
        title: tr("toast.offline.title", "OBS is offline"),
        body: tr("toast.offline.body", "Launch OBS to use recording controls."),
      };
    default:
      return {
        title: payload.title || "",
        body: payload.body || "",
      };
    }
  }

  function showProcessErrorToast(detail) {
    const body = detail && detail !== ""
                 ? detail
                 : tr("toast.error.body", "Check the OBS helper output.");
    ToastService.showNotice(
      tr("toast.error.title", "OBS control failed"),
      body,
      "",
      4200
    );
  }

  function openControls(screen, anchorItem) {
    if (pluginApi && screen) {
      pluginApi.togglePanel(screen, anchorItem);
    }
  }

  function togglePanelFromIpc() {
    pluginApi?.withCurrentScreen(function(screen) {
      root.openControls(screen, null);
    });
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
    id: actionRefreshTimer
    interval: 900
    running: false
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: pollTimer
    interval: root.pollIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: displayTimer
    interval: 1000
    running: false
    repeat: true
    onTriggered: {
      if (!root.recording) {
        root.displayRecordDurationMs = 0;
        running = false;
        return;
      }

      root.displayRecordDurationMs += 1000;
    }
  }

  IpcHandler {
    target: "plugin:obs-control"

    function togglePanel() {
      root.togglePanelFromIpc();
    }

    function refreshStatus() {
      root.refresh();
    }

    function launchObs() {
      root.launchObs();
    }

    function toggleRecord() {
      root.toggleRecord();
    }

    function toggleReplay() {
      root.toggleReplay();
    }

    function saveReplay() {
      root.saveReplay();
    }

    function openVideos() {
      root.openVideos();
    }

    function primaryAction() {
      if (root.leftClickAction === "toggle-record") {
        root.runSecondaryAction();
        return;
      }
      root.togglePanelFromIpc();
    }

    function secondaryAction() {
      root.runSecondaryAction();
    }

    function middleAction() {
      root.runMiddleAction();
    }
  }

  Process {
    id: actionProcess
    running: false
    command: pendingAction === "" ? [] : [root.obsctlPath, pendingAction]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode) {
      const output = String(stdout.text || "").trim();
      const errorOutput = String(stderr.text || "").trim();

      if (exitCode === 0 && output !== "") {
        try {
          root.showActionToast(JSON.parse(output));
        } catch (e) {}
      } else if (exitCode !== 0) {
        root.showProcessErrorToast(errorOutput);
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
