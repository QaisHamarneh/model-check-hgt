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

    function hasName(name, model) {
        for (var i = 0; i < model.count; i++) {
            if (model.get(i).name === name)
                return true
        }
        return false
    }
            
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

            name: "Test var."
            value: "0"

        }

    }

    ListModel {

        id: location_model

        ListElement {

            name: "loc"
            initial: true
            invariant: "x < 10"

        }

    }

    ColumnLayout {

        width: 500
        spacing: 20
        anchors { fill: parent; margins: 20 }

        Column {

            id: agents
            width: parent.width
            spacing: 10

            Text {
                text: "Agents"
            }

            ListView {

                id: agent_list
                width: (parent.width - parent.spacing) / 2
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

            Row {

                width: parent.width
                spacing: 10

                TextField {
                    id: agent_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Enter name"
                    onAccepted: {
                        var regex = /^[A-Za-z][A-Za-z0-9_]*$/;
                        if (regex.test(agent_text_field.text) && !hasName(agent_text_field.text, agent_model)) {
                            agent_model.append({name: agent_text_field.text});
                            agent_text_field.placeholderText = "Enter name";
                            agent_text_field.text = "";
                        } else {
                            agent_text_field.placeholderText = "Invalid name";
                            agent_text_field.text = "";
                        }
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter name";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add agent"
                    onClicked: {
                        var regex = /^[A-Za-z]\w*$/;
                        if (regex.test(agent_text_field.text) && !hasName(agent_text_field.text, agent_model)) {
                            agent_model.append({name: agent_text_field.text});
                            agent_text_field.placeholderText = "Enter name";
                            agent_text_field.text = "";
                        } else {
                            agent_text_field.placeholderText = "Invalid name";
                            agent_text_field.text = "";
                        }
                    }
                }

            }

        }

        Column {

            id: actions
            width: parent.width
            spacing: 10

            Text {
                text: "Actions"
            }

            ListView {

                id: action_list
                width: (parent.width - parent.spacing) / 2
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

            Row {

                width: parent.width
                spacing: 10

                TextField {
                    id: action_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Enter name"
                    onAccepted: {
                        var regex = /^[A-Za-z][A-Za-z0-9_]*$/;
                        if (regex.test(action_text_field.text) && !hasName(action_text_field.text, action_model)) {
                            action_model.append({name: action_text_field.text});
                            action_text_field.placeholderText = "Enter name";
                            action_text_field.text = "";
                        } else {
                            action_text_field.placeholderText = "Invalid name";
                            action_text_field.text = "";
                        }
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter name";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add action"
                    onClicked: {
                        var regex = /^[A-Za-z][A-Za-z0-9_]*$/;
                        if (regex.test(action_text_field.text) && !hasName(action_text_field.text, action_model)) {
                            action_model.append({name: action_text_field.text});
                            action_text_field.placeholderText = "Enter name";
                            action_text_field.text = "";
                        } else {
                            action_text_field.placeholderText = "Invalid name";
                            action_text_field.text = "";
                        }
                    }
                }

            }

        }

        Column {

            id: variables
            width: parent.width
            spacing: 10

            Text {
                text: "Variables"
            }

            Row {

                width: parent.width
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
                width: parent.width
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

                width: parent.width
                spacing: 10

                TextField {
                    id: variable_name_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Enter name"
                    onAccepted: {
                        var name_regex = /^[A-Za-z]\w*$/;
                        var value_regex = /(^[1-9]\d*(\.\d+)?$)|(^0(\.\d+)?$)/;
                        if (name_regex.test(variable_name_text_field.text) && !hasName(variable_name_text_field.text, variable_model)) {
                            if (value_regex.test(variable_value_text_field.text)) {
                                variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            } else {
                                variable_value_text_field.placeholderText = "Invalid value";
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            }
                        } else {
                            variable_name_text_field.placeholderText = "Invalid name";
                            variable_name_text_field.text = "";
                            variable_value_text_field.text = "";
                        }
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter name";
                    }
                }

                TextField {
                    id: variable_value_text_field
                    width: (parent.width - parent.spacing) / 2
                    placeholderText: "Enter value"
                    onAccepted: {
                        var name_regex = /^[A-Za-z]\w*$/;
                        var value_regex = /(^[1-9]\d*(\.\d+)?$)|(^0(\.\d+)?$)/;
                        if (name_regex.test(variable_name_text_field.text) && !hasName(variable_name_text_field.text, variable_model)) {
                            if (value_regex.test(variable_value_text_field.text)) {
                                variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            } else {
                                variable_value_text_field.placeholderText = "Invalid value";
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            }
                        } else {
                            variable_name_text_field.placeholderText = "Invalid name";
                            variable_name_text_field.text = "";
                            variable_value_text_field.text = "";
                        }
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter value";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add action"
                    onClicked: {
                        var name_regex = /^[A-Za-z]\w*$/;
                        var value_regex = /(^[1-9]\d*(\.\d+)?$)|(^0(\.\d+)?$)/;
                        if (name_regex.test(variable_name_text_field.text) && !hasName(variable_name_text_field.text, variable_model)) {
                            if (value_regex.test(variable_value_text_field.text)) {
                                variable_model.append({name: variable_name_text_field.text, value: variable_value_text_field.text});
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            } else {
                                variable_value_text_field.placeholderText = "Invalid value";
                                variable_name_text_field.text = "";
                                variable_value_text_field.text = "";
                            }
                        } else {
                            variable_name_text_field.placeholderText = "Invalid name";
                            variable_name_text_field.text = "";
                            variable_value_text_field.text = "";
                        }
                    }
                }

            }

        }

    }

}
