import QtQuick

Item {
  id: root

  property var pluginApi
  property var screen

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool showShortcut: Boolean(service && service.showInControlCenter)

  visible: showShortcut
  implicitWidth: showShortcut ? button.implicitWidth : 0
  implicitHeight: showShortcut ? button.implicitHeight : 0

  ObsButton {
    id: button
    anchors.fill: parent
    visible: root.showShortcut
    pluginApi: root.pluginApi
    screen: root.screen
  }
}
