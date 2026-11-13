pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property real bytesReceivedPerSec: 0
    property real bytesSentPerSec: 0
    property string downFormatted: "0 B/s"
    property string upFormatted: "0 B/s"
    readonly property string text: "↓ " + downFormatted + "  ↑ " + upFormatted

    // Private measurement state
    property double lastRx: -1
    property double lastTx: -1
    property double lastTime: 0

    FileView {
        id: procNet
        path: "/proc/net/dev"
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: Config.barNetworkSpeed
        onRunningChanged: {
            if (running) {
                root.lastTime = 0;
                root.lastRx = -1;
                root.lastTx = -1;
                root.update();
            }
        }
        onTriggered: {
            procNet.reload();
            root.update();
        }
    }

    Component.onCompleted: root.update()

    function formatSpeed(bytes) {
        if (!bytes || bytes <= 0 || isNaN(bytes))
            return "0 B/s";
        if (bytes < 1024)
            return Math.round(bytes) + " B/s";
        if (bytes < 1024 * 1024) {
            const kb = bytes / 1024;
            return (kb >= 100 ? Math.round(kb) : kb.toFixed(1)) + " KB/s";
        }
        if (bytes < 1024 * 1024 * 1024) {
            const mb = bytes / (1024 * 1024);
            return (mb >= 100 ? Math.round(mb) : mb.toFixed(1)) + " MB/s";
        }
        const gb = bytes / (1024 * 1024 * 1024);
        return (gb >= 100 ? Math.round(gb) : gb.toFixed(1)) + " GB/s";
    }

    function update() {
        const raw = procNet.text();
        if (!raw)
            return;

        let totalRx = 0;
        let totalTx = 0;
        const lines = raw.split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const colon = line.indexOf(":");
            if (colon === -1)
                continue;

            const iface = line.slice(0, colon).trim();
            if (iface === "lo" || iface.startsWith("veth") || iface.startsWith("docker") || iface.startsWith("br-"))
                continue;

            const fields = line.slice(colon + 1).trim().split(/\s+/);
            if (fields.length >= 9) {
                const rx = Number(fields[0]);
                const tx = Number(fields[8]);
                if (!isNaN(rx) && !isNaN(tx)) {
                    totalRx += rx;
                    totalTx += tx;
                }
            }
        }

        const now = Date.now();
        if (root.lastTime > 0 && now > root.lastTime && root.lastRx >= 0 && root.lastTx >= 0) {
            const elapsed = (now - root.lastTime) / 1000;
            if (elapsed > 0) {
                const deltaRx = totalRx - root.lastRx;
                const deltaTx = totalTx - root.lastTx;
                const rxRate = deltaRx >= 0 ? deltaRx / elapsed : 0;
                const txRate = deltaTx >= 0 ? deltaTx / elapsed : 0;

                root.bytesReceivedPerSec = rxRate;
                root.bytesSentPerSec = txRate;
                root.downFormatted = formatSpeed(rxRate);
                root.upFormatted = formatSpeed(txRate);
            }
        }

        root.lastRx = totalRx;
        root.lastTx = totalTx;
        root.lastTime = now;
    }
}
