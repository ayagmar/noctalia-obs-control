import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property int recordDurationMs: Number(service && service.displayRecordDurationMs ? service.displayRecordDurationMs : 0)
  readonly property bool connected: obsRunning && websocket

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  function formatDuration(durationMs) {
    const totalSeconds = Math.max(0, Math.floor(durationMs / 1000))
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    if (hours > 0) {
      return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
    }

    return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
  }

  property bool allowAttach: true
  property real contentPreferredWidth: Math.round(372 * Style.uiScaleRatio)
  property real contentPreferredHeight: content.implicitHeight + (Style.margin2L * 2)

  Item {
    id: panelContainer
    anchors.fill: parent

    ColumnLayout {
      id: content
      x: Style.marginL
      y: Style.marginL
      width: parent.width - (Style.margin2L)
      spacing: Style.marginL

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Image {
          source: root.obsLogoSource
          sourceSize.width: Math.round(Style.fontSizeXXL * 1.8)
          sourceSize.height: Math.round(Style.fontSizeXXL * 1.8)
          width: Math.round(Style.fontSizeXXL * 1.8)
          height: Math.round(Style.fontSizeXXL * 1.8)
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          asynchronous: true
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            text: root.tr("panel.header.title", "OBS Control")
            pointSize: Style.fontSizeXL
            font.weight: Style.fontWeightSemiBold
            color: Color.mPrimary
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: {
              if (recording) {
                return root.tr("panel.header.recording", "Recording is active. Stop the capture or manage replay actions from here.");
              }
              if (replayBuffer) {
                return root.tr("panel.header.replay", "Replay buffer is active. Save the latest replay at any time.");
              }
              if (connected) {
                return root.tr("panel.header.ready", "OBS is connected and ready for recording or replay.");
              }
              if (obsRunning) {
                return root.tr("panel.header.needs_restart", "OBS is open, but WebSocket control is unavailable until it is restarted once.");
              }
              return root.tr("panel.header.offline", "OBS is offline. Launch it here and the widget will track its state.");
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: statusColumn.implicitHeight + (Style.marginXL)

        ColumnLayout {
          id: statusColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NText {
            Layout.fillWidth: true
            text: root.tr("panel.status.label", "Status") + ": " +
                  (recording
                    ? root.tr("panel.status.recording", "Recording")
                    : (replayBuffer
                        ? root.tr("panel.status.replay", "Replay Buffer")
                        : (connected
                            ? root.tr("panel.status.ready", "Ready")
                            : (obsRunning
                                ? root.tr("panel.status.needs_restart", "Needs OBS Restart")
                                : root.tr("panel.status.offline", "Offline")))))
            font.weight: Style.fontWeightSemiBold
            color: recording ? Color.mError : (replayBuffer ? Color.mSecondary : Color.mOnSurface)
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: websocket
                  ? root.tr("panel.status.connected_hint", "The bar indicator follows recording state. Left click opens this panel, right click toggles recording, and middle click toggles replay.")
                  : root.tr("panel.status.disconnected_hint", "WebSocket control is unavailable right now. Launch or restart OBS to restore quick actions.")
          }

          NText {
            Layout.fillWidth: true
            visible: recording && recordDurationMs > 0
            text: root.tr("panel.status.elapsed", "Elapsed") + ": " + root.formatDuration(recordDurationMs)
            font.weight: Style.fontWeightMedium
            color: Color.mOnSurface
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginM

        NButton {
          Layout.fillWidth: true
          icon: obsRunning ? "refresh" : "player-play"
          text: obsRunning
                ? root.tr("panel.actions.refresh_obs", "Refresh OBS")
                : root.tr("panel.actions.launch_obs", "Launch OBS")
          enabled: !obsRunning || !websocket
          onClicked: {
            if (!service) {
              return;
            }
            if (obsRunning) {
              service.refresh();
            } else {
              service.launchObs();
            }
          }
        }

        NButton {
          Layout.fillWidth: true
          icon: "player-record"
          text: recording
                ? root.tr("panel.actions.stop_recording", "Stop Recording")
                : root.tr("panel.actions.start_recording", "Start Recording")
          enabled: connected
          backgroundColor: recording ? Color.mError : Color.mPrimary
          textColor: recording ? Color.mOnError : Color.mOnPrimary
          onClicked: service && service.toggleRecord()
        }

        NButton {
          Layout.fillWidth: true
          icon: "history"
          text: replayBuffer
                ? root.tr("panel.actions.stop_replay", "Stop Replay")
                : root.tr("panel.actions.start_replay", "Start Replay")
          enabled: connected
          backgroundColor: replayBuffer ? Color.mSecondary : Color.mSurfaceVariant
          textColor: replayBuffer ? Color.mOnSecondary : Color.mOnSurface
          onClicked: service && service.toggleReplay()
        }

        NButton {
          Layout.fillWidth: true
          icon: "device-floppy"
          text: root.tr("panel.actions.save_replay", "Save Replay")
          enabled: replayBuffer
          outlined: !replayBuffer
          onClicked: service && service.saveReplay()
        }

        NButton {
          Layout.fillWidth: true
          icon: "folder"
          text: root.tr("panel.actions.open_videos", "Open Videos")
          outlined: true
          onClicked: service && service.openVideos()
        }
      }

      NButton {
        Layout.fillWidth: true
        icon: "refresh"
        text: root.tr("panel.actions.refresh_status", "Refresh Status")
        outlined: true
        onClicked: service && service.refresh()
      }
    }
  }
}
