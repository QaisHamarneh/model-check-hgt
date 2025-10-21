import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import org.julialang

ApplicationWindow {

    visible: true
    width: 640
    height: 480
    Material.accent: Material.DeepOrange

    ListModel {
        id: messageModel
    }

    ColumnLayout {
        anchors { fill: parent; margins: 8 }
        spacing: 16
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            model: messageModel
            delegate: ItemDelegate { 
                RowLayout {
                    Text {
                        id: name
                        text: model.message 
                        color: "blue"
                        x:parent.width / 4
                        y:parent.height / 4
                    }
                    TextField {
                        id: textField
                        Layout.fillWidth: true; Layout.fillHeight: true
                    }
                }
            }
        }
        RowLayout {
            spacing: 16
            Layout.fillWidth: true; Layout.fillHeight: false
            TextField {
                id: textField
                Layout.fillWidth: true; Layout.fillHeight: true
            }
            Button {
                Material.foreground: "white"; Material.background: Material.DeepOrange
                Layout.fillHeight: true
                text: "Send"
                onClicked: {
                    messageModel.append({message: textField.text});
                    textField.text = "";
                }
            }
        }
    }
}