import QtQuick
import Quickshell.Networking
import ".."
import "../components"
import "../services"

ToggleTile {
    id: root
    readonly property var device: Networking.devices.values.find(d => d.connected)
    readonly property var network: device?.networks.values.find(n => n.connected)
    icon: NetworkInfo.icon(root.network)
    title: I18n.tr("network.label")
    status: network?.name || (Networking.wifiEnabled ? I18n.tr("network.notConnected") : I18n.tr("network.wifiOff"))
    checked: Networking.wifiEnabled
    hasDetails: true
    detailsIcon: "chevron-right"
    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    onDetailsRequested: ShellState.push("network")
}
