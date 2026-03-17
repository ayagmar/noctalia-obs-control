import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "I18n.js" as I18n

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

  function tr(key, fallback, interpolations) {
    return I18n.tr(pluginApi, key, fallback, interpolations)
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    pluginApi.pluginSettings.pollIntervalMs = valuePollIntervalMs;
    pluginApi.pluginSettings.leftClickAction = valueLeftClickAction;
    pluginApi.pluginSettings.videosPath = valueVideosPath.trim();
    pluginApi.pluginSettings.showBarWhenRecording = valueShowBarWhenRecording;
    pluginApi.pluginSettings.showBarWhenReplay = valueShowBarWhenReplay;
    pluginApi.pluginSettings.showControlCenterWhenRecording = valueShowControlCenterWhenRecording;
    pluginApi.pluginSettings.showControlCenterWhenReplay = valueShowControlCenterWhenReplay;
    pluginApi.pluginSettings.showControlCenterWhenReady = valueShowControlCenterWhenReady;
    pluginApi.saveSettings();
  }

  NHeader {
    label: tr("settings.header.label", "OBS Control")
    description: tr("settings.header.description", "Control how often the plugin polls OBS and when it becomes visible in the shell.")
  }

  NSpinBox {
    label: tr("settings.poll_interval.label", "Poll Interval")
    description: tr("settings.poll_interval.description", "How often the plugin refreshes OBS state, in milliseconds.")
    from: 750
    to: 10000
    stepSize: 250
    value: valuePollIntervalMs
    onValueChanged: valuePollIntervalMs = value
  }

  NComboBox {
    label: tr("settings.left_click_action.label", "Left Click Action")
    description: tr("settings.left_click_action.description", "Choose whether left click opens the panel or toggles recording directly.")
    model: [
      { "key": "panel", "name": tr("settings.left_click_action.options.open_controls", "Open Controls") },
      { "key": "toggle-record", "name": tr("settings.left_click_action.options.toggle_recording", "Toggle Recording") }
    ]
    currentKey: valueLeftClickAction
    minimumWidth: 220
    onSelected: key => valueLeftClickAction = key
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.videos_path.label", "Videos Path")
    description: tr("settings.videos_path.description", "Optional custom folder used by the panel and the toast action. Leave empty to use your default Videos directory.")
    placeholderText: "~/Videos"
    text: valueVideosPath
    onTextChanged: valueVideosPath = text
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_bar_recording.label", "Show Bar While Recording")
    description: tr("settings.show_bar_recording.description", "Display the bar indicator while OBS is actively recording.")
    checked: valueShowBarWhenRecording
    onToggled: checked => valueShowBarWhenRecording = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_bar_replay.label", "Show Bar While Replay Is Active")
    description: tr("settings.show_bar_replay.description", "Keep the bar indicator visible when only the replay buffer is running.")
    checked: valueShowBarWhenReplay
    onToggled: checked => valueShowBarWhenReplay = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_recording.label", "Show Control Center While Recording")
    description: tr("settings.show_control_center_recording.description", "Show the Control Center shortcut while OBS is recording.")
    checked: valueShowControlCenterWhenRecording
    onToggled: checked => valueShowControlCenterWhenRecording = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_replay.label", "Show Control Center While Replay Is Active")
    description: tr("settings.show_control_center_replay.description", "Show the Control Center shortcut while the replay buffer is active.")
    checked: valueShowControlCenterWhenReplay
    onToggled: checked => valueShowControlCenterWhenReplay = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: tr("settings.show_control_center_ready.label", "Show Control Center When OBS Is Ready")
    description: tr("settings.show_control_center_ready.description", "Keep the shortcut visible when OBS is connected but idle.")
    checked: valueShowControlCenterWhenReady
    onToggled: checked => valueShowControlCenterWhenReady = checked
  }
}
