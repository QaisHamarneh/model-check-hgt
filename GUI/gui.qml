import QtQml.Models
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import org.julialang

ApplicationWindow {

    id: window

    visible: true
    width: 1920
    height: 1080
            
    ListModel {

        id: agent_model

        ListElement {

            name: "Test agent."

        }

    }

    ListModel {

        id: action_model

        ListElement {

            name: "Test action."

        }

    }

    ListModel {

        id: variable_model

        ListElement {

            name: "Test action."
            value: "0"

        }

    }

    ColumnLayout {

        width: window.width
        Layout.fillHeight: true
        anchors { fill: parent; margins: 20 }
        spacing: 20

        Column {

            id: agents
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Agents"
            }

            ListView {

                id: agent_list
                width: parent.width
                height: Math.min(contentHeight, 100)
                clip: true

                model: agent_model
                delegate: Text {
                    id: agent_name
                    text: model.name 
                    color: "blue"
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

            }

            RowLayout {

                TextField {
                    id: agent_text_field
                    Layout.fillWidth: true
                    placeholderText: "Agent"
                    onAccepted: {
                        agent_model.append({name: agent_text_field.text});
                        agent_text_field.text = "";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add agent"
                    onClicked: {
                        agent_model.append({name: agent_text_field.text});
                        agent_text_field.text = "";
                    }
                }

            }

        }

        Column {

            id: actions
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Actions"
            }

            ListView {

                id: action_list
                width: parent.width
                height: Math.min(contentHeight, 100)
                clip: true

                model: action_model
                delegate: Text {
                    id: action_name
                    text: model.name 
                    color: "blue"
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

            }

            RowLayout {

                TextField {
                    id: action_text_field
                    Layout.fillWidth: true
                    placeholderText: "Action"
                    onAccepted: {
                        action_model.append({name: action_text_field.text});
                        action_text_field.text = "";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add action"
                    onClicked: {
                        action_model.append({name: action_text_field.text});
                        action_text_field.text = "";
                    }
                }

            }

        }

        Column {

            id: variables
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Variables"
            }

            Row {

                width: 500
                spacing: 10

                Text {
                    width: (parent.width - parent.spacing) / 2
                    horizontalAlignment: Text.AlignLeft
                    text: "Name"
                }
                Text {
                    width: (parent.width - parent.spacing) / 2
                    horizontalAlignment: Text.AlignLeft
                    text: "Initial value"
                }
            }

            ListView {

                id: variable_list
                width: 500
                height: Math.min(contentHeight, 100)
                clip: true

                model: variable_model
                delegate: Row {

                    width: parent.width
                    spacing: 10

                    Text {
                        id: variable_name
                        width: (parent.width - parent.spacing) / 2
                        horizontalAlignment: Text.AlignLeft
                        text: model.name 
                        color: "blue"
                    }
                    Text {
                        id: variable_value
                        width: (parent.width - parent.spacing) / 2
                        horizontalAlignment: Text.AlignLeft
                        text: model.value 
                        color: "blue"
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }

            }

            Row {

                width: 500
                spacing: 10

                TextField {
                    id: variable_name_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Name"
                    onAccepted: {
                        variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                        variable_name_text_field.text = "";
                        variable_value_text_field.text = "";
                    }
                }

                TextField {
                    id: variable_value_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Value"
                    onAccepted: {
                        variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                        variable_name_text_field.text = "";
                        variable_value_text_field.text = "";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add action"
                    onClicked: {
                        variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                        variable_name_text_field.text = "";
                        variable_value_text_field.text = "";
                    }
                }

            }

        }

    }

}
