pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."

// Airplane mode: controls rfkill state across all wireless transmitters (Wi-Fi, Bluetooth).
// Toggling on blocks all radio devices; toggling off unblocks them and restores Wi-Fi and Bluetooth.
Singleton {
    id: root

    property bool active: false
    property bool available: true

    function toggle() {
        setAirplaneMode(!active);
    }

    function setAirplaneMode(enable) {
        active = enable;
        if (enable) {
            blockProcess.running = true;
            Networking.wifiEnabled = false;
            for (const adapter of Bluetooth.adapters.values)
                adapter.enabled = false;
            Osd.showState("airplane", I18n.tr("network.airplaneMode"), I18n.tr("common.on"));
        } else {
            unblockProcess.running = true;
            Networking.wifiEnabled = true;
            Osd.showState("airplane", I18n.tr("network.airplaneMode"), I18n.tr("common.off"));
        }
    }

    function unblockBluetooth() {
        unblockBtProcess.running = true;
    }

    function blockBluetooth() {
        blockBtProcess.running = true;
    }

    function checkState() {
        if (!reader.running)
            reader.running = true;
    }

    Process {
        id: blockProcess
        command: ["rfkill", "block", "all"]
        onExited: root.checkState()
    }

    Process {
        id: unblockProcess
        command: ["rfkill", "unblock", "all"]
        onExited: {
            Networking.wifiEnabled = true;
            for (const adapter of Bluetooth.adapters.values)
                adapter.enabled = true;
            root.checkState();
        }
    }

    Process {
        id: unblockBtProcess
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: {
            for (const adapter of Bluetooth.adapters.values)
                adapter.enabled = true;
            root.checkState();
        }
    }

    Process {
        id: blockBtProcess
        command: ["rfkill", "block", "bluetooth"]
        onExited: {
            for (const adapter of Bluetooth.adapters.values)
                adapter.enabled = false;
            root.checkState();
        }
    }

    Process {
        id: reader
        command: ["rfkill", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const devs = data.rfkilldevices || [];
                    if (devs.length > 0) {
                        const allBlocked = devs.every(d => d.soft === "blocked" || d.hard === "blocked");
                        root.active = allBlocked;
                    }
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: root.checkState()
    }

    Component.onCompleted: root.checkState()
}
