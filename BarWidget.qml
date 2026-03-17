import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "I18n.js" as I18n

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property string primaryActionText: service ? service.primaryActionText : "opens controls"
  readonly property string obsLogoSource: pluginApi ? ("file://" + pluginApi.pluginDir + "/assets/obs-logo.svg") : ""

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  readonly property string statusTooltip: replayBuffer
                                            ? tr("bar.tooltip.replay", "OBS replay buffer is active\nLeft click {primaryAction}\nRight click toggles recording\nMiddle click stops the replay buffer", { primaryAction: primaryActionText })
                                            : tr("bar.tooltip.recording", "OBS recording is active\nLeft click {primaryAction}\nRight click stops recording\nMiddle click toggles the replay buffer", { primaryAction: primaryActionText })
  readonly property color statusAccentColor: recording ? Color.mError : Color.mSecondary
  readonly property string statusLabel: recording
                                        ? root.tr("bar.recording_label", "REC")
                                        : root.tr("bar.replay_label", "RPL")

  readonly property bool showInBar: Boolean(service && service.showInBar)
  readonly property real contentWidth: showInBar ? (content.implicitWidth + Style.marginM * 2) : 0
  readonly property real contentHeight: showInBar ? capsuleHeight : 0

  visible: showInBar
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule

    visible: root.showInBar
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: content
      anchors.centerIn: parent
      spacing: Style.marginS

      Image {
        source: root.obsLogoSource
        sourceSize.width: Math.round(root.barFontSize * 1.3)
        sourceSize.height: Math.round(root.barFontSize * 1.3)
        width: Math.round(root.barFontSize * 1.3)
        height: Math.round(root.barFontSize * 1.3)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
      }

      Rectangle {
        Layout.alignment: Qt.AlignVCenter
        width: Math.max(8, Math.round(root.barFontSize * 0.48))
        height: width
        radius: width / 2
        color: root.statusAccentColor
      }

      NText {
        Layout.alignment: Qt.AlignVCenter
        text: root.statusLabel
        pointSize: root.barFontSize
        font.weight: Style.fontWeightSemiBold
        color: Color.mOnSurface
      }
    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    enabled: root.showInBar
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      TooltipService.show(root, root.statusTooltip, "auto");
    }

    onExited: {
      TooltipService.hide(root);
    }

    onPressed: {
      TooltipService.hide(root);
    }

    onClicked: function(mouse) {
      if (!service) {
        return;
      }

      if (mouse.button === Qt.LeftButton) {
        service.runPrimaryAction(screen, root);
      } else if (mouse.button === Qt.RightButton) {
        service.runSecondaryAction();
      } else if (mouse.button === Qt.MiddleButton) {
        service.runMiddleAction();
      }
    }
  }
}
