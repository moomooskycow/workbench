// HeadphoneModel.js — pure functions for headphone detection, battery telemetry, and bar formatting

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function batteryGlyph(level, charging) {
  var pct = clamp(Math.round(level <= 1.0 && level > 0 ? level * 100 : level), 0, 100)
  if (charging) {
    if (pct <= 15) return "󰢟"
    if (pct <= 25) return "󰢜"
    if (pct <= 35) return "󰂆"
    if (pct <= 45) return "󰂇"
    if (pct <= 55) return "󰂈"
    if (pct <= 65) return "󰢝"
    if (pct <= 75) return "󰂉"
    if (pct <= 85) return "󰢞"
    if (pct <= 95) return "󰂊"
    return "󰂅"
  } else {
    if (pct <= 10) return "󰂎"
    if (pct <= 20) return "󰁺"
    if (pct <= 30) return "󰁻"
    if (pct <= 40) return "󰁼"
    if (pct <= 50) return "󰁽"
    if (pct <= 60) return "󰁾"
    if (pct <= 70) return "󰁿"
    if (pct <= 80) return "󰂀"
    if (pct <= 90) return "󰂁"
    if (pct < 100) return "󰂂"
    return "󰁹"
  }
}

function isHeadphoneText(text) {
  if (!text) return false
  var s = String(text).toLowerCase()
  return s.indexOf("headphone") !== -1 ||
         s.indexOf("headset") !== -1 ||
         s.indexOf("bose") !== -1 ||
         s.indexOf("quietcomfort") !== -1 ||
         s.indexOf("wh-1000") !== -1 ||
         s.indexOf("airpods") !== -1 ||
         s.indexOf("earbuds") !== -1 ||
         s.indexOf("earphone") !== -1 ||
         s.indexOf("05a7:4082") !== -1 ||
         s.indexOf("05a7") !== -1
}

function isHeadphoneNode(node) {
  if (!node) return false
  if (node.isStream) return false
  if (!node.isSink) return false

  var name = String(node.name || "")
  var desc = String(node.description || "")
  var nick = String(node.nick || "")
  var props = node.properties || {}
  var cardName = String(props["alsa.card_name"] || "")
  var prodName = String(props["device.product.name"] || "")
  var prodId = String(props["device.product.id"] || "")
  var comp = String(props["alsa.components"] || "")

  if (prodId === "0x4082" || comp.indexOf("05a7:4082") !== -1) return true
  if (isHeadphoneText(name) || isHeadphoneText(desc) || isHeadphoneText(nick) || isHeadphoneText(cardName) || isHeadphoneText(prodName)) {
    return true
  }
  return false
}

function isAnalogHeadphoneSink(node) {
  if (!node) return false
  if (node.isStream) return false
  if (!node.isSink) return false
  var name = String(node.name || "").toLowerCase()
  var desc = String(node.description || "").toLowerCase()
  return (name.indexOf("analog-stereo") !== -1 || desc.indexOf("analog") !== -1) &&
         name.indexOf("usb-") === -1
}

function isHeadphoneBluetoothDevice(dev) {
  if (!dev) return false
  var name = String(dev.name || dev.deviceName || "")
  if (isHeadphoneText(name)) return true
  var uuids = dev.uuids ? (Array.isArray(dev.uuids) ? dev.uuids : (dev.uuids.values || [])) : []
  for (var i = 0; i < uuids.length; i++) {
    var u = String(uuids[i]).toLowerCase()
    if (u.indexOf("110b") !== -1 || u.indexOf("1108") !== -1 || u.indexOf("111e") !== -1) return true
  }
  return false
}

function isMatchingIdentity(devA, devB) {
  if (!devA || !devB) return false
  var a = String(devA.name || devA || "").toLowerCase()
  var b = String(devB.name || devB || "").toLowerCase()

  // Match brand and family
  var brands = [
    ["bose", "quietcomfort", "qc"],
    ["sony", "wh-1000", "wf-1000"],
    ["airpods", "apple"],
    ["sennheiser", "momentum"],
    ["pixel buds", "google"]
  ]

  for (var i = 0; i < brands.length; i++) {
    var group = brands[i]
    var aMatch = false
    var bMatch = false
    for (var j = 0; j < group.length; j++) {
      if (a.indexOf(group[j]) !== -1) aMatch = true
      if (b.indexOf(group[j]) !== -1) bMatch = true
    }
    if (aMatch && bMatch) return true
    if (aMatch !== bMatch) return false
  }

  // Generic fallback: if neither matched a known brand group, do not merge
  return false
}

function cleanDeviceName(raw) {
  if (!raw) return "Headphones"
  var s = String(raw)
  s = s.replace(/\s+Analog Stereo$/i, "")
  s = s.replace(/\s+Digital Stereo$/i, "")
  s = s.replace(/\s+Stereo$/i, "")
  s = s.replace(/^alsa_output\.[^.]+\./i, "")
  return s.trim() || "Headphones"
}

function resolveActiveHeadphone(btDevices, pwNodes, usbConnected, usbDetails, defaultSink) {
  var btArray = btDevices || []
  var activeBt = null

  for (var i = 0; i < btArray.length; i++) {
    var d = btArray[i]
    if (d && d.connected && isHeadphoneBluetoothDevice(d)) {
      activeBt = d
      break
    }
  }

  // Check PipeWire nodes for active USB audio headphone sink
  var pwArray = pwNodes || []
  var activeUsbSink = null
  for (var j = 0; j < pwArray.length; j++) {
    var n = pwArray[j]
    if (isHeadphoneNode(n) && isUsbSink(n)) {
      activeUsbSink = n
      break
    }
  }

  var isUsb = !!(usbConnected || activeUsbSink)
  var usbName = (usbDetails && usbDetails.name) ? usbDetails.name :
                (activeUsbSink ? (activeUsbSink.description || activeUsbSink.nick || "Bose QC Ultra 2") : "Bose QC Ultra 2")

  // Case 1: Both USB and Bluetooth connected with matching identity (Multipoint)
  if (isUsb && activeBt && isMatchingIdentity(usbName, activeBt.name)) {
    var hasBatt = !!activeBt.batteryAvailable
    var battLvl = hasBatt ? Math.round(activeBt.battery * 100) : -1
    return {
      connected: true,
      transport: "multipoint",
      name: cleanDeviceName(activeBt.name || usbName),
      charging: false,
      batteryAvailable: hasBatt,
      battery: battLvl,
      node: activeUsbSink,
      btDevice: activeBt
    }
  }

  // Case 2: USB Audio connected (Bluetooth not connected or unrelated)
  if (isUsb) {
    return {
      connected: true,
      transport: "usb",
      name: cleanDeviceName(usbName),
      charging: false,
      batteryAvailable: false,
      battery: -1,
      node: activeUsbSink,
      btDevice: null
    }
  }

  // Case 3: Bluetooth connected (USB unplugged)
  if (activeBt) {
    var hasBtBatt = !!activeBt.batteryAvailable
    var btLvl = hasBtBatt ? Math.round(activeBt.battery * 100) : -1
    return {
      connected: true,
      transport: "bluetooth",
      name: cleanDeviceName(activeBt.name || activeBt.deviceName || "Bose QC Ultra 2"),
      charging: false,
      batteryAvailable: hasBtBatt,
      battery: btLvl,
      node: null,
      btDevice: activeBt
    }
  }

  // Case 4: Audio routed to analog output (AUX 3.5mm jack active)
  var isAnalog = defaultSink && isAnalogHeadphoneSink(defaultSink)
  if (isAnalog) {
    return {
      connected: true,
      transport: "aux",
      name: "Bose QC Ultra 2",
      charging: false,
      batteryAvailable: false,
      battery: -1,
      node: defaultSink,
      btDevice: null
    }
  }

  // Case 5: Standby / persistent slot
  return {
    connected: false,
    transport: "standby",
    name: "Bose QC Ultra 2",
    charging: false,
    batteryAvailable: false,
    battery: -1,
    node: null,
    btDevice: null
  }
}

function isUsbSink(node) {
  if (!node) return false
  var bus = String((node.properties && node.properties["device.bus"]) || "")
  var name = String(node.name || "")
  return bus === "usb" || name.indexOf("usb-") !== -1
}

function barGlyph(headphone) {
  if (!headphone) return "󰋋"
  if (headphone.batteryAvailable && headphone.battery >= 0) {
    return batteryGlyph(headphone.battery, false)
  }
  return "󰋋"
}

function barText(headphone, showPercentage, vertical) {
  if (!headphone) return "󰋋"
  var glyph = barGlyph(headphone)

  if (vertical) {
    return glyph
  }

  if (headphone.batteryAvailable && headphone.battery >= 0) {
    return showPercentage ? Math.round(headphone.battery) + "% " + glyph : glyph
  }

  if (headphone.transport === "usb") {
    return showPercentage ? "󰋋 USB" : "󰋋"
  }

  if (headphone.transport === "aux") {
    return showPercentage ? "󰋋 AUX" : "󰋋"
  }

  if (headphone.transport === "standby" || !headphone.connected) {
    return showPercentage ? "󰋋 --%" : "󰋋"
  }

  return glyph
}

function statusSubtitle(headphone) {
  if (!headphone || !headphone.connected) return "Bluetooth disconnected"
  if (headphone.transport === "multipoint") {
    if (headphone.batteryAvailable) return "USB Audio & Bluetooth · " + headphone.battery + "%"
    return "USB Audio & Bluetooth · Battery unavailable"
  }
  if (headphone.transport === "usb") {
    return "USB-C Audio · Battery unavailable over USB"
  }
  if (headphone.transport === "aux") {
    return "3.5mm AUX · Bluetooth offline"
  }
  if (headphone.transport === "bluetooth") {
    if (headphone.batteryAvailable) return "Bluetooth 5.3 · " + headphone.battery + "% Remaining"
    return "Bluetooth Connected · Battery unavailable"
  }
  return "Connected"
}

function tooltipText(headphone, isDefaultSink) {
  if (!headphone) return "Bose QC Ultra 2\nBluetooth disconnected"
  var lines = []
  lines.push(headphone.name)
  lines.push(statusSubtitle(headphone))
  if (headphone.transport === "aux") {
    lines.push("󰓃 3.5mm Analog Audio (Active)")
  } else if (isDefaultSink) {
    lines.push("󰓃 Active Output Sink")
  } else {
    lines.push("󰓃 Available Output Device")
  }
  if (headphone.batteryAvailable) {
    lines.push("Click: Controls · Right-click: Toggle %")
  } else {
    lines.push("Click: Pair Bluetooth for live battery")
  }
  return lines.join("\n")
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    batteryGlyph: batteryGlyph,
    isHeadphoneText: isHeadphoneText,
    isHeadphoneNode: isHeadphoneNode,
    isAnalogHeadphoneSink: isAnalogHeadphoneSink,
    isHeadphoneBluetoothDevice: isHeadphoneBluetoothDevice,
    isMatchingIdentity: isMatchingIdentity,
    cleanDeviceName: cleanDeviceName,
    resolveActiveHeadphone: resolveActiveHeadphone,
    barGlyph: barGlyph,
    barText: barText,
    statusSubtitle: statusSubtitle,
    tooltipText: tooltipText
  }
}
