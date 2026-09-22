import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs.Ui
import qs.Commons
import "HeadphoneModel.js" as Model

Panel {
  id: root
  moduleName: "phaedrus.headphone-battery"
  ipcTarget: "phaedrus.headphone-battery"

  readonly property bool showPercentage: setting("showPercentage", true) === true
  readonly property bool autoHide: setting("autoHide", false) === true

  property var usbDetails: ({ usbConnected: false, usbName: "", usbSerial: "" })
  property var headphone: null
  property bool pairingActive: false
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal
  readonly property var defaultSink: Pipewire.defaultAudioSink
  property var activeVolumeNode: null
  readonly property real listeningVolume: (activeVolumeNode && activeVolumeNode.audio && activeVolumeNode.audio.volume !== undefined) ? Number(activeVolumeNode.audio.volume) : 1.0

  function setListeningVolume(v) {
    if (activeVolumeNode && activeVolumeNode.audio) {
      activeVolumeNode.audio.volume = Math.max(0, Math.min(1.0, v))
    }
  }

  function toggleListeningMute() {
    if (activeVolumeNode && activeVolumeNode.audio) {
      activeVolumeNode.audio.muted = !activeVolumeNode.audio.muted
    }
  }
  readonly property color mutedForeground: Util.alpha(bar ? bar.barForeground : Color.foreground, 0.88)
  readonly property var bluetoothDevices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []

  function updateHeadphoneState() {
    root.headphone = Model.resolveActiveHeadphone(
      root.bluetoothDevices,
      root.pipewireNodes,
      root.usbDetails ? root.usbDetails.usbConnected : false,
      root.usbDetails,
      root.defaultSink
    )
    root.activeVolumeNode = root.headphone && root.headphone.node ? root.headphone.node : root.defaultSink
  }

  onBluetoothDevicesChanged: updateHeadphoneState()
  onPipewireNodesChanged: updateHeadphoneState()
  onUsbDetailsChanged: updateHeadphoneState()
  onDefaultSinkChanged: updateHeadphoneState()

  readonly property bool hasBatteryTelemetry: root.headphone !== null && root.headphone.batteryAvailable && root.headphone.battery >= 0
  readonly property bool isDefaultSink: {
    if (!root.headphone || !root.headphone.node || !root.defaultSink) return false
    return (root.defaultSink.id !== undefined && root.defaultSink.id === root.headphone.node.id) ||
           (root.defaultSink.name !== undefined && root.defaultSink.name === root.headphone.node.name)
  }

  readonly property string displayText: Model.barText(root.headphone, showPercentage, vertical)
  readonly property string tooltip: Model.tooltipText(root.headphone, isDefaultSink)

  function togglePercentage() {
    root.settings = Object.assign({}, root.settings, { showPercentage: !root.showPercentage })
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, root.settings)
    }
  }

  function setDefaultAudioSink(sink) {
    if (!sink) return
    Pipewire.preferredDefaultAudioSink = sink
    if (sink.id !== undefined && sink.name) {
      Quickshell.execDetached([
        "omarchy-audio-output-set-default",
        String(sink.id),
        String(sink.name)
      ])
    }
  }

  function startBluetoothPairing() {
    if (pairingProc.running) return
    root.pairingActive = true
    pairingProc.running = true
  }

  // Periodic refresh of USB and Bluetooth DBus telemetry
  Process {
    id: statusProc
    command: [Quickshell.env("HOME") + "/.config/omarchy/plugins/phaedrus.headphone-battery/status.sh"]
    running: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.usbDetails = data
          root.updateHeadphoneState()
        } catch (e) {
        }
      }
    }
  }

  Process {
    id: pairingProc
    command: [Quickshell.env("HOME") + "/.config/omarchy/plugins/phaedrus.headphone-battery/pair.sh"]
    onExited: {
      root.pairingActive = false
      if (!statusProc.running) statusProc.running = true
      root.updateHeadphoneState()
    }
  }

  Timer {
    interval: 3500
    running: true
    repeat: true
    onTriggered: {
      if (!statusProc.running) statusProc.running = true
    }
  }

  Component.onCompleted: {
    updateHeadphoneState()
  }

  // Bar dimensions and visibility
  visible: !autoHide || (headphone && headphone.connected)
  implicitWidth: visible ? (vertical ? barSize : button.implicitWidth) : 0
  implicitHeight: visible ? (vertical ? button.implicitHeight : barSize) : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    labelVisible: true
    tooltipText: root.tooltip
    active: root.hasBatteryTelemetry || (root.headphone && root.headphone.transport === "aux")
    useActiveColor: false
    foreground: {
      if (root.hasBatteryTelemetry) {
        if (root.headphone.battery <= 20) return bar ? bar.urgent : Color.urgent
        if (root.headphone.battery <= 35) return Color.accent
        return bar ? bar.barForeground : Color.foreground
      }
      if (root.headphone && root.headphone.transport === "aux") {
        return bar ? bar.barForeground : Color.foreground
      }
      if (root.headphone && root.headphone.transport === "usb") {
        return bar ? bar.barForeground : Color.foreground
      }
      return root.mutedForeground
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        root.togglePercentage()
      } else {
        root.toggle()
      }
    }

    onWheelMoved: function(delta) {
      var targetNode = root.headphone && root.headphone.node ? root.headphone.node : root.defaultSink
      if (!targetNode || !targetNode.audio) return
      var step = delta > 0 ? 0.05 : -0.05
      var cur = targetNode.audio.volume
      targetNode.audio.volume = Math.max(0, Math.min(1.0, cur + step))
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      width: parent.width
      spacing: Style.spacing.md

      // Hero: Headphone Identity Card
      Row {
        width: parent.width
        spacing: Style.spacing.md

        Rectangle {
          width: Style.space(44)
          height: Style.space(44)
          radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(8)
          color: Style.hoverFillFor(bar ? bar.foreground : Color.foreground, Color.accent)
          border.width: 1
          border.color: root.hasBatteryTelemetry ? Color.accent : Color.popups.border

          Text {
            anchors.centerIn: parent
            text: "󰋋"
            font.pixelSize: Style.font.title
            font.family: bar ? bar.fontFamily : Style.font.family
            color: root.hasBatteryTelemetry ? Color.accent : (bar ? bar.barForeground : Color.foreground)
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(56)
          spacing: Style.spacing.xs

          Text {
            text: root.headphone ? root.headphone.name : "Bose QC Ultra 2"
            font.pixelSize: Style.font.body
            font.bold: true
            font.family: bar ? bar.fontFamily : Style.font.family
            color: bar ? bar.barForeground : Color.foreground
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: root.headphone ? Model.statusSubtitle(root.headphone) : "Bluetooth disconnected"
            font.pixelSize: Style.font.caption
            font.family: bar ? bar.fontFamily : Style.font.family
            color: root.mutedForeground
            elide: Text.ElideRight
            width: parent.width
          }
        }
      }

      // Battery Status Section
      Rectangle {
        width: parent.width
        height: root.hasBatteryTelemetry ? Style.space(64) : Style.space(110)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(6)
        color: Style.hoverFillFor(bar ? bar.foreground : Color.foreground, Color.accent)
        border.width: 1
        border.color: Color.popups.border

        Column {
          anchors.fill: parent
          anchors.margins: Style.spacing.md
          spacing: Style.spacing.sm

          // When Battery Telemetry is ACTIVE:
          Column {
            width: parent.width
            spacing: Style.spacing.xs
            visible: root.hasBatteryTelemetry

            Item {
              width: parent.width
              height: Style.space(18)

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Battery Level (Bluetooth Telemetry)"
                font.pixelSize: Style.font.caption
                font.family: bar ? bar.fontFamily : Style.font.family
                color: root.mutedForeground
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.hasBatteryTelemetry ? (root.headphone.battery + "%") : ""
                font.pixelSize: Style.font.body
                font.bold: true
                font.family: bar ? bar.fontFamily : Style.font.family
                color: root.headphone && root.headphone.battery <= 20 ? Color.urgent : Color.accent
              }
            }

            Rectangle {
              width: parent.width
              height: Style.space(8)
              radius: Style.space(4)
              color: Color.popups.border

              Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1.0, (root.hasBatteryTelemetry ? root.headphone.battery : 0) / 100))
                color: {
                  if (!root.headphone) return Color.accent
                  if (root.headphone.battery <= 20) return Color.urgent
                  return Color.accent
                }
              }
            }
          }

          // When Battery Telemetry is INACTIVE (e.g. AUX or USB without Bluetooth):
          Column {
            width: parent.width
            spacing: Style.spacing.sm
            visible: !root.hasBatteryTelemetry

            Row {
              spacing: Style.spacing.xs
              width: parent.width

              Text {
                text: "󰂯"
                font.pixelSize: Style.font.body
                color: Color.accent
              }

              Text {
                text: "Live battery readout requires Bluetooth link"
                font.pixelSize: Style.font.caption
                font.bold: true
                color: bar ? bar.barForeground : Color.foreground
              }
            }

            Text {
              width: parent.width
              text: "3.5mm AUX and USB carry audio only. Pair Bluetooth to stream battery percentage directly to this bar."
              font.pixelSize: Style.font.caption
              color: root.mutedForeground
              wrapMode: Text.WordWrap
            }

            // Quick Pair Button
            Rectangle {
              width: parent.width
              height: Style.space(32)
              radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(4)
              color: root.pairingActive ? Color.accent : Style.selectedFillFor(bar ? bar.foreground : Color.foreground, Color.accent)
              border.width: 1
              border.color: Color.accent

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.pairingActive
                onClicked: root.startBluetoothPairing()
              }

              Row {
                anchors.centerIn: parent
                spacing: Style.spacing.xs

                Text {
                  text: root.pairingActive ? "󱥸" : "󰂯"
                  font.pixelSize: Style.font.body
                  color: root.pairingActive ? Color.background : Color.accent
                }

                Text {
                  text: root.pairingActive ? "Pairing… (Hold headphone button)" : "Pair Bose QC Ultra 2 via Bluetooth"
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  color: root.pairingActive ? Color.background : Color.accent
                }
              }
            }
          }
        }
      }
      // Audio Output Routing Card
      Rectangle {
        width: parent.width
        height: Style.space(36)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(6)
        color: Style.hoverFillFor(bar ? bar.foreground : Color.foreground, Color.accent)
        border.width: 1
        border.color: root.isDefaultSink ? Color.accent : Color.popups.border

        Row {
          anchors.centerIn: parent
          spacing: Style.spacing.sm

          Text {
            text: root.headphone && root.headphone.transport === "aux" ? "󰓃" : (root.isDefaultSink ? "󰄬" : "󰓃")
            font.pixelSize: Style.font.body
            font.family: bar ? bar.fontFamily : Style.font.family
            color: Color.accent
          }

          Text {
            text: {
              if (root.headphone && root.headphone.transport === "aux")
                return "Audio Output: 3.5mm AUX (Active)"
              if (root.isDefaultSink)
                return "Audio Output: Headphones (Default)"
              return "Audio Output: Active"
            }
            font.pixelSize: Style.font.caption
            font.bold: true
            font.family: bar ? bar.fontFamily : Style.font.family
            color: bar ? bar.barForeground : Color.foreground
          }
        }
      }

      // Volume Control Slider
      Column {
        width: parent.width
        spacing: Style.spacing.xs

        Item {
          width: parent.width
          height: Style.space(16)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Listening Volume"
            font.pixelSize: Style.font.caption
            font.family: bar ? bar.fontFamily : Style.font.family
            color: root.mutedForeground
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.listeningVolume * 100) + "%"
            font.pixelSize: Style.font.caption
            font.bold: true
            font.family: bar ? bar.fontFamily : Style.font.family
            color: bar ? bar.barForeground : Color.foreground
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm

          Rectangle {
            width: Style.space(28)
            height: Style.space(28)
            radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(4)
            color: root.listeningMuted
              ? (bar ? bar.urgent : Color.urgent)
              : Style.hoverFillFor(bar ? bar.foreground : Color.foreground, Color.accent)

            Text {
              anchors.centerIn: parent
              text: root.listeningMuted ? "󰝟" : "󰕾"
              font.pixelSize: Style.font.body
              font.family: bar ? bar.fontFamily : Style.font.family
              color: bar ? bar.barForeground : Color.foreground
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleListeningMute()
            }
          }

          PanelSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(36)
            bar: root.bar
            minimum: 0
            maximum: 1.0
            step: 0.05
            value: root.listeningVolume
            onMoved: function(v) { root.setListeningVolume(v) }
          }
        }
      }

      // Settings Row: Toggle percentage display
      Item {
        width: parent.width
        height: Style.space(24)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Show percentage on bar"
          font.pixelSize: Style.font.caption
          font.family: bar ? bar.fontFamily : Style.font.family
          color: root.mutedForeground
        }

        Rectangle {
          width: Style.space(32)
          height: Style.space(18)
          radius: Style.space(9)
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          color: root.showPercentage ? Color.accent : Color.popups.border

          Rectangle {
            width: Style.space(14)
            height: Style.space(14)
            radius: Style.space(7)
            anchors.verticalCenter: parent.verticalCenter
            x: root.showPercentage ? parent.width - width - Style.space(2) : Style.space(2)
            color: Color.foreground

            Behavior on x {
              NumberAnimation { duration: 120 }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglePercentage()
          }
        }
      }
    }
  }
}
