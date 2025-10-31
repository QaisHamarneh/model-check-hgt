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
    minimumWidth: 1920
    maximumWidth: 1920
    height: 1080
    minimumHeight: 1080
    maximumHeight: 1080

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
        for (var i = 0; i < location_model.count; i++) {
            if (location_model.get(i).name === name)
                return true
        }
        for (var i = 0; i < edge_model.count; i++) {
            if (edge_model.get(i).name === name)
                return true
        }
        return false
    }

    function get_variables() {
        var variables = []
        for (var i = 0; i < variable_model.count; i++) {
            variables.push(variable_model.get(i).name)
        }
        return variables
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

    ListModel {

        id: location_model

    }

    ListModel {

        id: edge_model

    }

    Row {

        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Column {

            id: left_column
            width: (parent.width - 2 * parent.spacing - page_separator.width) / 2
            height: parent.height
            spacing: 20

            Row {

                width: parent.width
                spacing: 20
                
                // agents
                Column {

                    id: agents
                    width: (parent.width - parent.spacing) / 2 
                    spacing: 10

                    function add_agent(agent) {
                        var regex = /^[A-Za-z]\w*$/;
                        if (regex.test(agent) && !has_name(agent)) {
                            agent_model.append({name: agent});
                            agent_text_field.placeholderText = "Enter name";
                            agent_text_field.text = "";
                        } else {
                            agent_text_field.placeholderText = "Invalid name";
                            agent_text_field.text = "";
                        }
                    }

                    Text {
                        width: parent.width
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
                                width: parent.width - parent.spacing - agent_button.width
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
                            width: parent.width - parent.spacing - agent_button.width
                            placeholderText: "Enter name"
                            onAccepted: {
                                agents.add_agent(agent_text_field.text);
                            }
                            onActiveFocusChanged: {
                                placeholderText = "Enter name";
                            }
                        }

                        Button {
                            id: agent_button
                            Layout.fillHeight: false
                            Material.foreground: "white"
                            Material.background: Material.DeepOrange
                            text: "+"
                            onClicked: {
                                agents.add_agent(agent_text_field.text);
                            }
                        }

                    }

                }

                // actions
                Column {

                    id: actions
                    width: (parent.width - parent.spacing) / 2
                    spacing: 10

                    function add_action(action) {
                        var regex = /^[A-Za-z][A-Za-z0-9_]*$/;
                        if (regex.test(action) && !has_name(action)) {
                            action_model.append({name: action});
                            action_text_field.placeholderText = "Enter name";
                            action_text_field.text = "";
                        } else {
                            action_text_field.placeholderText = "Invalid name";
                            action_text_field.text = "";
                        }
                    }

                    Text {
                        width: parent.width
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
                                width: parent.width - parent.spacing - action_button.width
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
                            width: parent.width - parent.spacing - action_button.width
                            placeholderText: "Enter name"
                            onAccepted: {
                                actions.add_action(action_text_field.text);
                            }
                            onActiveFocusChanged: {
                                placeholderText = "Enter name";
                            }
                        }

                        Button {
                            id: action_button
                            Layout.fillHeight: false
                            Material.foreground: "white"
                            Material.background: Material.DeepOrange
                            text: "+"
                            onClicked: {
                                actions.add_action(action_text_field.text);
                            }
                        }

                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 4
                color: "black"
            }

            // variables
            Column {

                id: variables
                width: parent.width
                spacing: 10

                function add_variable(variable, value) {
                    var name_regex = /^[A-Za-z]\w*$/;
                    var value_regex = /(^[1-9]\d*(\.\d+)?$)|(^0(\.\d+)?$)/;
                    if (name_regex.test(variable) && !has_name(variable)) {
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
                    width: parent.width
                    text: "Variables"
                }

                Row {

                    width: parent.width - parent.spacing - variable_button.width
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
                            width: (parent.width - 2 * parent.spacing - variable_button.width) / 2
                            horizontalAlignment: Text.AlignLeft
                            text: model.name 
                            color: "blue"
                        }

                        Text {
                            width: (parent.width - 2 * parent.spacing - variable_button.width) / 2
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
                        width: (parent.width - 2 * parent.spacing - variable_button.width) / 2
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
                        width: (parent.width - 2 * parent.spacing - variable_button.width) / 2
                        placeholderText: "Enter value"
                        onAccepted: {
                            variables.add_variable(variable_name_text_field.text, variable_value_text_field.text);
                        }
                        onActiveFocusChanged: {
                            placeholderText = "Enter value";
                        }
                    }

                    Button {
                        id: variable_button
                        Layout.fillHeight: false
                        Material.foreground: "white"
                        Material.background: Material.DeepOrange
                        text: "+"
                        onClicked: {
                            variables.add_variable(variable_name_text_field.text, variable_value_text_field.text);
                        }
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 4
                color: "black"
            }

            // triggers
            Column {

                id: triggers
                width: parent.width
                visible: agent_model.count > 0
                spacing: 10

                Text {
                    width: parent.width
                    text: "Triggers"
                }

                ListView {

                    id: trigger_list
                    width: parent.width
                    height: Math.min(contentHeight, 300)
                    clip: true

                    model: agent_model
                    delegate: Column {

                        width: trigger_list.width
                        spacing: 10

                        function add_trigger(trigger) {
                            if (Julia.is_valid_constraint(trigger, get_variables())) {
                                agent_trigger_model.append({trigger: trigger});
                                trigger_text_field.placeholderText = "Enter trigger";
                                trigger_text_field.text = "";
                            } else {
                                trigger_text_field.placeholderText = "Invalid trigger";
                                trigger_text_field.text = "";
                            }
                        }

                        Rectangle {
                            
                            width: parent.width
                            height: 3
                            visible: index != 0
                            radius: 4
                            color: "grey"

                        }

                        Text {
                            width: parent.width
                            text: model.name
                        }

                        ListView {

                            id: agent_trigger_list
                            width: parent.width
                            height: Math.min(contentHeight, 100)
                            clip: true

                            model: ListModel {

                                id: agent_trigger_model

                            }
                            delegate: Row {

                                width: agent_trigger_list.width
                                spacing: 10

                                Text {
                                    width: parent.width -parent.spacing - trigger_button.width
                                    text: model.trigger
                                }

                                Button {
                                    text: "-"
                                    height: parent.height
                                    onClicked: {
                                        agent_trigger_model.remove(index, 1);
                                    }
                                }

                            }

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            TextField {
                                id: trigger_text_field
                                width: parent.width - parent.spacing - trigger_button.width
                                placeholderText: "Enter trigger"
                                onAccepted: {
                                    add_trigger(text);
                                    focus = false;
                                }
                            }

                            Button {
                                id: trigger_button
                                Material.foreground: "white"
                                Material.background: Material.DeepOrange
                                Layout.fillHeight: false
                                text: "+"
                                onClicked: {
                                    add_trigger(trigger_text_field.text);
                                }
                            }

                        }

                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                }

            }

        }

        Rectangle {
            id: page_separator
            width: 5
            height: parent.height
            radius: 4
            color: "black"
        }

        Column {

            width: (parent.width - 2 * parent.spacing - page_separator.width) / 2
            height: parent.height
            spacing: 20

            // locations
            Column {

                id: locations
                width: parent.width
                spacing: 10

                function add_location() {
                    if (location_model.count == 0) {
                        location_model.append({
                            name: "",
                            inv: "",
                            initial: true
                        });
                    } else {
                        location_model.append({
                            name: "",
                            inv: "",
                            initial: false
                        });   
                    }
                }

                ButtonGroup {
                    id: initial_button
                }

                Text {
                    width: parent.width
                    text: "Locations"
                }

                ListView {

                    id: location_list
                    width: parent.width
                    height: Math.min(contentHeight, 400)
                    spacing: 10
                    clip: true

                    model: location_model
                    delegate: Column {

                        width: location_list.width
                        spacing: 10

                        Rectangle {
                            
                            width: parent.width
                            height: 3
                            visible: index != 0
                            radius: 4
                            color: "grey"

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            Text {
                                id: location_name_text
                                width: contentWidth
                                height: parent.height
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                text: "Name"
                            }

                            TextField {
                                id: location_name_text_field
                                width: (
                                    parent.width - 5 * parent.spacing - location_name_text.width - location_inv_text.width - initial_location.width - location_remove.width
                                ) / 2
                                placeholderText: "Enter name"
                                onAccepted: {
                                    var regex = /^[A-Za-z]\w*$/;
                                    if (regex.test(location_name_text_field.text) && !has_name(location_name_text_field.text)) {
                                        model.name = location_name_text_field.text;
                                        placeholderText = "";
                                    } else {
                                        model.name = "";
                                        location_name_text_field.text = "";
                                        placeholderText = "Invalid name";
                                    }
                                    focus = false;
                                }
                            }

                            Text {
                                id: location_inv_text
                                width: contentWidth
                                height: parent.height
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                text: "Invariant"
                            }

                            TextField {
                                id: invariant_text_field
                                width: (
                                    parent.width - 5 * parent.spacing - location_name_text.width - location_inv_text.width - initial_location.width - location_remove.width
                                ) / 2
                                placeholderText: "Enter invariant"
                                onAccepted: {
                                    if (Julia.is_valid_constraint(text, get_variables())) {
                                        model.inv = text;
                                        placeholderText = "";
                                    } else {
                                        model.inv = "";
                                        text = "";
                                        placeholderText = "Invalid invariant";
                                    }
                                    focus = false;
                                }
                            }

                            RadioButton {
                                id: initial_location
                                ButtonGroup.group: initial_button
                                text: "Initial"
                                checked: model.initial
                                onCheckedChanged: {
                                    if (model.initial != checked) {
                                        model.initial = checked;
                                    }
                                }
                            }

                            Button {
                                id: location_remove
                                text: "-"
                                height: parent.height
                                onClicked: {
                                    location_model.remove(index, 1);
                                }
                            }

                        }

                        Text {
                            text: "Flow"
                            visible: variable_model.count > 0
                        }

                        ListView {

                            id: flow
                            width: parent.width
                            height: contentHeight
                            spacing: 10
                            clip: true
                            interactive: false

                            model: variable_model
                            delegate: Row {

                                width: flow.width
                                spacing: 10

                                Text {
                                    height: parent.height
                                    width: location_name_text.width
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    text: model.name
                                }

                                TextField {
                                    id: flow_text_field
                                    width: parent.width - 2 * parent.spacing - location_name_text.width - initial_location.width
                                    placeholderText: "Enter expression"
                                    onAccepted: {
                                        if (Julia.is_valid_expression(text, get_variables())) {
                                            placeholderText = "";
                                        } else {
                                            text = "";
                                            placeholderText = "Invalid expression";
                                        }
                                        focus = false;
                                    }
                                }

                            }

                        }

                    }

                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "+"
                    onClicked: {
                        locations.add_location();
                    }
                }

            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 4
                color: "black"
            }

            // edges
            Column {

                id: edges
                width: parent.width
                spacing: 10

                Text {
                    width: parent.width
                    text: "Edges"
                }

                ListView {

                    id: edge_list
                    width: parent.width
                    height: Math.min(contentHeight, 400)
                    spacing: 10
                    clip: true

                    model: edge_model
                    delegate: Column {

                        width: edge_list.width
                        spacing: 10

                        property int edge_index: index

                        Rectangle {
                            
                            width: parent.width
                            height: 3
                            visible: index != 0
                            radius: 4
                            color: "grey"

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            Text {
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                horizontalAlignment: Text.AlignLeft
                                text: "Name"
                            }

                            Text {
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                horizontalAlignment: Text.AlignLeft
                                text: "Start location"
                            }

                            Text {
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                horizontalAlignment: Text.AlignLeft
                                text: "End location"
                            }

                            Button {
                                id: edge_remove
                                text: "-"
                                height: parent.height
                                onClicked: {
                                    edge_model.remove(index, 1);
                                }
                            }

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            TextField {
                                id: edge_name_text_field
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                placeholderText: "Enter name"
                                onAccepted: {
                                    var regex = /^[A-Za-z]\w*$/;
                                    if (regex.test(text) && !has_name(text)) {
                                        model.name = text;
                                        placeholderText = "";
                                    } else {
                                        model.name = "";
                                        text = "";
                                        placeholderText = "Invalid name";
                                    }
                                    focus = false;
                                }
                            }

                            ComboBox {
                                
                                id: edge_start_menu
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                enabled: location_model.count > 0

                                model: location_model

                                textRole: "name"
                                valueRole: "name"
                                onActivated: {
                                    edge_list.model.setProperty(edge_index, "start", currentValue);
                                }

                                popup.closePolicy: Popup.CloseOnPressOutside

                            }

                            ComboBox {
                                
                                id: edge_end_menu
                                width: (parent.width - 3 * parent.spacing - edge_remove.width) / 3
                                enabled: location_model.count > 0

                                model: location_model

                                textRole: "name"
                                valueRole: "name"
                                onActivated: {
                                    edge_list.model.setProperty(edge_index, "end", currentValue);
                                }
                                popup.closePolicy: Popup.CloseOnPressOutside

                            }

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            Text {
                                width: contentWidth
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                id: guard_text
                                text: "Guard"
                            }

                            TextField {
                                id: guard_text_field
                                width: parent.width - parent.spacing - guard_text.width
                                placeholderText: "Enter guard"
                                onAccepted: {
                                    if (Julia.is_valid_constraint(text, get_variables())) {
                                        model.guard = text;
                                        placeholderText = "";
                                    } else {
                                        model.guard = "";
                                        text = "";
                                        placeholderText = "Invalid guard";
                                    }
                                    focus = false;
                                }
                            }

                        }

                        Row {

                            width: parent.width
                            spacing: 10

                            Text {
                                width: guard_text.width
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                id: edge_agent_text
                                text: "Agent"
                            }

                            ComboBox {
                                id: agent_menu
                                width: (parent.width - 3 * parent.spacing - edge_agent_text.width - edge_action_text.width) / 2
                                enabled: agent_model.count > 0
                                
                                model: agent_model

                                textRole: "name"
                                valueRole: "name"
                                onActivated: {
                                    edge_list.model.setProperty(edge_index, "agent", currentValue);
                                }
                                popup.closePolicy: Popup.CloseOnPressOutside
                            }

                            Text {
                                width: contentWidth
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                id: edge_action_text
                                text: "Action"
                            }

                            ComboBox {
                                id: action_menu
                                width: (parent.width - 3 * parent.spacing - edge_agent_text.width - edge_action_text.width) / 2
                                enabled: action_model.count > 0
                                
                                model: action_model

                                textRole: "name"
                                valueRole: "name"
                                onActivated: {
                                    edge_list.model.setProperty(edge_index, "action", currentValue);
                                }
                                popup.closePolicy: Popup.CloseOnPressOutside
                            }
                        }

                        Text {
                            text: "Jump"
                            visible: variable_model.count > 0
                        }

                        ListView {

                            id: jump
                            width: parent.width
                            height: contentHeight
                            spacing: 10
                            clip: true
                            interactive: false

                            model: variable_model
                            delegate: Row {

                                width: jump.width
                                spacing: 10

                                Text {
                                    height: parent.height
                                    width: guard_text.width
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    text: model.name
                                }

                                TextField {
                                    id: jump_text_field
                                    width: parent.width - parent.spacing - guard_text.width
                                    placeholderText: "Enter expression"
                                    onAccepted: {
                                        if (Julia.is_valid_expression(text, get_variables())) {
                                            placeholderText = "";
                                        } else {
                                            text = "";
                                            placeholderText = "Invalid expression";
                                        }
                                        focus = false;
                                    }
                                }

                            }

                        }

                    }

                }

                Button {
                    Material.foreground: "white"
                    Material.background: Material.DeepOrange
                    Layout.fillHeight: false
                    text: "+"
                    onClicked: {
                        edge_model.append({
                            name: "",
                            start: "",
                            end: "",
                            guard: "",
                            agent: "",
                            action: ""
                        });
                    }
                }

            }

        }

    }

}
