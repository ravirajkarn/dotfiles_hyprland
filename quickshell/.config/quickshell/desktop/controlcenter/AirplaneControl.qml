import QtQuick
import ".."
import "../services"

SwitchRow {
    icon: "airplane"
    title: I18n.tr("network.airplaneMode")
    status: AirplaneMode.active ? I18n.tr("common.on") : I18n.tr("common.off")
    checked: AirplaneMode.active
    onToggled: checked => AirplaneMode.setAirplaneMode(checked)
}
