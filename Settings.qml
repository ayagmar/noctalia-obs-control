import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  width: 560

  required property var pluginApi

  readonly property var defaults: pluginApi && pluginApi.manifest && pluginApi.manifest.metadata
                                   ? (pluginApi.manifest.metadata.defaultSettings || {})
                                   : ({})

  property int valuePollIntervalMs: pluginApi.pluginSettings.pollIntervalMs !== undefined
                                    ? pluginApi.pluginSettings.pollIntervalMs
                                    : (defaults.pollIntervalMs !== undefined ? defaults.pollIntervalMs : 2500)
  property string valueLeftClickAction: pluginApi.pluginSettings.leftClickAction !== undefined
                                        ? pluginApi.pluginSettings.leftClickAction
                                        : (defaults.leftClickAction !== undefined ? defaults.leftClickAction : "panel")
  property string valueVideosPath: pluginApi.pluginSettings.videosPath !== undefined
                                   ? pluginApi.pluginSettings.videosPath
                                   : (defaults.videosPath !== undefined ? defaults.videosPath : "")
  property bool valueShowBarWhenRecording: pluginApi.pluginSettings.showBarWhenRecording !== undefined
                                           ? pluginApi.pluginSettings.showBarWhenRecording
                                           : (defaults.showBarWhenRecording !== undefined ? defaults.showBarWhenRecording : true)
  property bool valueShowBarWhenReplay: pluginApi.pluginSettings.showBarWhenReplay !== undefined
                                        ? pluginApi.pluginSettings.showBarWhenReplay
                                        : (defaults.showBarWhenReplay !== undefined ? defaults.showBarWhenReplay : false)
  property bool valueShowControlCenterWhenRecording: pluginApi.pluginSettings.showControlCenterWhenRecording !== undefined
                                                     ? pluginApi.pluginSettings.showControlCenterWhenRecording
                                                     : (defaults.showControlCenterWhenRecording !== undefined ? defaults.showControlCenterWhenRecording : true)
  property bool valueShowControlCenterWhenReplay: pluginApi.pluginSettings.showControlCenterWhenReplay !== undefined
                                                  ? pluginApi.pluginSettings.showControlCenterWhenReplay
                                                  : (defaults.showControlCenterWhenReplay !== undefined ? defaults.showControlCenterWhenReplay : true)
  property bool valueShowControlCenterWhenReady: pluginApi.pluginSettings.showControlCenterWhenReady !== undefined
                                                 ? pluginApi.pluginSettings.showControlCenterWhenReady
                                                 : (defaults.showControlCenterWhenReady !== undefined ? defaults.showControlCenterWhenReady : false)

  function saveSettings() {
    pluginApi.pluginSettings = {
      "pollIntervalMs": valuePollIntervalMs,
      "leftClickAction": valueLeftClickAction,
      "videosPath": valueVideosPath.trim(),
      "showBarWhenRecording": valueShowBarWhenRecording,
      "showBarWhenReplay": valueShowBarWhenReplay,
      "showControlCenterWhenRecording": valueShowControlCenterWhenRecording,
      "showControlCenterWhenReplay": valueShowControlCenterWhenReplay,
      "showControlCenterWhenReady": valueShowControlCenterWhenReady
    };
    pluginApi.saveSettings();
    return pluginApi.pluginSettings;
  }

  NHeader {
    label: "OBS Control"
    description: "Control how often the plugin polls OBS and when it becomes visible in the shell."
  }

  NSpinBox {
    label: "Poll Interval"
    description: "How often the plugin refreshes OBS state, in milliseconds."
    from: 750
    to: 10000
    stepSize: 250
    value: valuePollIntervalMs
    onValueChanged: {
      valuePollIntervalMs = value;
      saveSettings();
    }
  }

  NComboBox {
    label: "Left Click Action"
    description: "Choose whether left click opens the panel or toggles recording directly."
    model: [
      { "key": "panel", "name": "Open Controls" },
      { "key": "toggle-record", "name": "Toggle Recording" }
    ]
    currentKey: valueLeftClickAction
    minimumWidth: 220
    onSelected: key => {
      valueLeftClickAction = key;
      saveSettings();
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Videos Path"
    description: "Optional custom folder used by the panel and the toast action. Leave empty to use your default Videos directory."
    placeholderText: "~/Videos"
    text: valueVideosPath
    onTextChanged: valueVideosPath = text
    onEditingFinished: saveSettings()
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Bar While Recording"
    description: "Display the bar indicator while OBS is actively recording."
    checked: valueShowBarWhenRecording
    onToggled: checked => {
      valueShowBarWhenRecording = checked;
      saveSettings();
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Bar While Replay Is Active"
    description: "Keep the bar indicator visible when only the replay buffer is running."
    checked: valueShowBarWhenReplay
    onToggled: checked => {
      valueShowBarWhenReplay = checked;
      saveSettings();
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Control Center While Recording"
    description: "Show the Control Center shortcut while OBS is recording."
    checked: valueShowControlCenterWhenRecording
    onToggled: checked => {
      valueShowControlCenterWhenRecording = checked;
      saveSettings();
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Control Center While Replay Is Active"
    description: "Show the Control Center shortcut while the replay buffer is active."
    checked: valueShowControlCenterWhenReplay
    onToggled: checked => {
      valueShowControlCenterWhenReplay = checked;
      saveSettings();
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: "Show Control Center When OBS Is Ready"
    description: "Keep the shortcut visible when OBS is connected but idle."
    checked: valueShowControlCenterWhenReady
    onToggled: checked => {
      valueShowControlCenterWhenReady = checked;
      saveSettings();
    }
  }
}
