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

    function has_name(name) {
        for (var i = 0; i < agent_model.count; i++) {
            if (agent_model.get(i).name === name)
                return true
        }
        for (var i = 0; i < action_model.count; i++) {
            if (action_model.get(i).name === name)
                return true
        }
        for (var i = 0; i < variable_model.count; i++) {
            if (variable_model.get(i).name === name)
                return true
        }
        return false
    }
            
    ListModel {

        id: agent_model

    }

    ListModel {

        id: action_model

    }

    ListModel {

        id: variable_model

    }

    ColumnLayout {

        width: 1000
        spacing: 20
        anchors { fill: parent; margins: 20 }

        Column {

            id: agents
            width: parent.width / 4 + 100
            spacing: 10

            function add_agent(agent) {
                var regex = /^[A-Za-z]\w*$/;
                if (regex.test(agent) && !has_name(agent, agent_model)) {
                    agent_model.append({name: agent});
                    agent_text_field.placeholderText = "Enter name";
                    agent_text_field.text = "";
                } else {
                    agent_text_field.placeholderText = "Invalid name";
                    agent_text_field.text = "";
                }
            }

            Text {
                text: "Agents"
            }

            ListView {

                id: agent_list
                width: parent.width
                height: Math.min(contentHeight, 100)
                clip: true

                model: agent_model
                delegate: Row {

                    width: agent_list.width
                    spacing: 10
                    
                    Text {

                        id: agent_name
                        width: parent.width - 100 - parent.spacing
                        text: model.name
                        color: "blue"
            
                    }

                    Button {
                        text: "-"
                        height: parent.height
                        onClicked: {
                            agent_model.remove(index, 1);
                        }
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
                    id: agent_text_field
                    width: parent.width - 100 - parent.spacing
                    placeholderText: "Enter name"
                    onAccepted: {
                        agents.add_agent(agent_text_field.text);
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
                        agents.add_agent(agent_text_field.text);
                    }
                }

            }

        }

        Column {

            id: actions
            width: parent.width / 4 + 100
            spacing: 10

            function add_action(action) {
                var regex = /^[A-Za-z][A-Za-z0-9_]*$/;
                if (regex.test(action) && !has_name(action, action_model)) {
                    action_model.append({name: action});
                    action_text_field.placeholderText = "Enter name";
                    action_text_field.text = "";
                } else {
                    action_text_field.placeholderText = "Invalid name";
                    action_text_field.text = "";
                }
            }

            Text {
                text: "Actions"
            }

            ListView {

                id: action_list
                width: parent.width
                height: Math.min(contentHeight, 100)
                clip: true

                model: action_model
                delegate: Row {

                    width: action_list.width
                    spacing: 10
                    
                    Text {

                        id: action_name
                        width: parent.width - 100 - parent.spacing
                        text: model.name 
                        color: "blue"

                    }

                    Button {
                        text: "-"
                        height: parent.height
                        onClicked: {
                            action_model.remove(index, 1);
                        }
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
                    id: action_text_field
                    width: parent.width - 100 - parent.spacing
                    placeholderText: "Enter name"
                    onAccepted: {
                        actions.add_action(action_text_field.text);
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
                        actions.add_action(action_text_field.text);
                    }
                }

            }

        }

        Column {

            id: variables
            width: parent.width / 2 + 100
            spacing: 10

            function add_variable(variable, value) {
                var name_regex = /^[A-Za-z]\w*$/;
                var value_regex = /(^[1-9]\d*(\.\d+)?$)|(^0(\.\d+)?$)/;
                if (name_regex.test(variable) && !has_name(variable, variable_model)) {
                    if (value_regex.test(value)) {
                        variable_model.append({name: variable, value: value});
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

            Text {
                text: "Variables"
            }

            Row {

                width: parent.width - 100
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

                    width: variable_list.width
                    spacing: 10

                    Text {
                        id: variable_name
                        width: (parent.width - 100 - parent.spacing) / 2
                        horizontalAlignment: Text.AlignLeft
                        text: model.name 
                        color: "blue"
                    }

                    Text {
                        id: variable_value
                        width: (parent.width - 100 - parent.spacing) / 2
                        horizontalAlignment: Text.AlignLeft
                        text: model.value 
                        color: "blue"
                    }

                    Button {
                        text: "-"
                        height: parent.height
                        onClicked: {
                            variable_model.remove(index, 1);
                        }
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
                    width: (parent.width - 100 - parent.spacing) / 2
                    placeholderText: "Enter name"
                    onAccepted: {
                        variables.add_variable(variable_name_text_field.text, variable_value_text_field.text);
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter name";
                    }
                }

                TextField {
                    id: variable_value_text_field
                    width: (parent.width - 100 - parent.spacing) / 2
                    placeholderText: "Enter value"
                    onAccepted: {
                        variables.add_variable(variable_name_text_field.text, variable_value_text_field.text);
                    }
                    onActiveFocusChanged: {
                        placeholderText = "Enter value";
                    }
                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "Add variable"
                    onClicked: {
                        variables.add_variable(variable_name_text_field.text, variable_value_text_field.text);
                    }
                }

            }

        }

    }

}
