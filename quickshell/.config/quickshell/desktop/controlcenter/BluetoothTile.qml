import QtQuick
import Quickshell.Bluetooth
import ".."
import "../components"
import "../services"

ToggleTile {
    id: root
    readonly property int connected: Bluetooth.devices.values.filter(d => d.connected).length
    readonly property bool bluetoothOn: (Bluetooth.defaultAdapter?.enabled ?? false) && Bluetooth.adapters.values.length > 0
    icon: "bluetooth"
    title: I18n.tr("bluetooth.title")
    status: !Bluetooth.defaultAdapter ? I18n.tr("common.unavailable") : !Bluetooth.defaultAdapter.enabled ? I18n.tr("common.off") : connected > 0 ? I18n.plural("bluetooth.connectedCount.one", "bluetooth.connectedCount.other", connected) : I18n.tr("common.on")
    checked: root.bluetoothOn
    available: Bluetooth.defaultAdapter !== null || Bluetooth.adapters.values.length > 0 || AirplaneMode.available
    hasDetails: true
    detailsIcon: "chevron-right"
    onToggled: {
        if (checked) {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = false;
            AirplaneMode.blockBluetooth();
        } else {
            AirplaneMode.unblockBluetooth();
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = true;
        }
    }
    onDetailsRequested: ShellState.push("bluetooth")
}
