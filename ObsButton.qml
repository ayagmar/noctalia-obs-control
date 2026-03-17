import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n

NIconButtonHot {
  id: root

  property ShellScreen screen
  property var pluginApi

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool connected: obsRunning && websocket
  readonly property string primaryActionText: service ? service.primaryActionText : "opens controls"
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  icon: ""
  hot: recording || replayBuffer
  colorBgHot: recording ? Color.mError : Color.mSecondary
  colorFgHot: recording ? Color.mOnError : Color.mOnSecondary

  tooltipText: {
    if (recording) {
      return tr("control_center.tooltip.recording", "OBS recording is active\nLeft click {primaryAction}\nRight click stops recording\nMiddle click toggles the replay buffer", { primaryAction: primaryActionText });
    }
    if (replayBuffer) {
      return tr("control_center.tooltip.replay", "OBS replay buffer is active\nLeft click {primaryAction}\nRight click starts recording\nMiddle click stops the replay buffer", { primaryAction: primaryActionText });
    }
    if (connected) {
      return tr("control_center.tooltip.ready", "OBS is ready\nLeft click {primaryAction}\nRight click starts recording\nMiddle click toggles the replay buffer", { primaryAction: primaryActionText });
    }
    if (obsRunning) {
      return tr("control_center.tooltip.needs_restart", "OBS is running, but WebSocket control is unavailable\nRestart OBS once to restore controls");
    }
    return tr("control_center.tooltip.offline", "OBS is offline\nLeft click {primaryAction}\nRight click launches OBS", { primaryAction: primaryActionText });
  }

  NIcon {
    anchors.centerIn: parent
    visible: recording || replayBuffer
    icon: recording ? "player-record" : "history"
    pointSize: Math.max(1, Math.round(root.width * 0.48))
    color: {
      if ((root.enabled && root.hovering) || root.pressed) {
        return Color.mOnHover;
      }
      return recording ? Color.mOnError : Color.mOnSecondary;
    }
  }

  Image {
    anchors.centerIn: parent
    visible: !recording && !replayBuffer
    source: root.obsLogoSource
    sourceSize.width: Math.round(root.width * 0.56)
    sourceSize.height: Math.round(root.height * 0.56)
    width: Math.round(root.width * 0.56)
    height: Math.round(root.height * 0.56)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
    opacity: ((root.enabled && root.hovering) || root.pressed) ? 0.96 : 0.9
  }

  onClicked: {
    if (!service || !pluginApi || !screen) {
      return;
    }

    service.runPrimaryAction(screen, root);
  }

  onRightClicked: {
    if (!service) {
      return;
    }

    service.runSecondaryAction();
  }

  onMiddleClicked: {
    if (service) {
      service.runMiddleAction();
    }
  }
}
