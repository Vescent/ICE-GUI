import QtQuick 2.0

Item {
    id: widget
    height: text1.contentHeight + 10
    width: text1.contentWidth + 10
    property alias text: text1.text
    property alias radius: rect1.radius
    property string textColor: "#ffffff"
    property alias pointSize: text1.font.pointSize
    property color background: "#202020"
    property int decimal: 2
    property int precision: 4
    property real minVal: -100.0
    property real maxVal: 100.0
    property bool useInt: true
    property bool fixedPrecision: false
    property bool useBorder: true
    property bool active: true
    property double value: 0
    signal valueEntered(real newVal)
    onValueChanged: {
        if (fixedPrecision) {
            text1.text = widget.value.toPrecision(precision);
        }
        else {
            text1.text = widget.value.toFixed(decimal);
        }
    }

    function setValue(text) {
        var number = parseFloat(text);

        if (isNaN(number)) {
            console.log('Result NaN:' + text);
            return;
        }
		
		//console.log(number)
		
		// TODO: This fixed bug where number '100.000000' doesn't
		// display properly.
		if (number == 100.000000) {
			number += 0.0000001;
		}

        widget.value = number;
    }

    function getValue() {
        return widget.value;
    }

    Rectangle {
        id: rect1
        anchors.fill: parent
        clip: false
        color: (useBorder) ? background : 'transparent';
        border.color: text1.cursorVisible ? '#3399ff' : '#cccccc'
        border.width: (useBorder) ? 1 : 0;
        radius: 10

        TextInput {
            id: text1
            color: (acceptableInput) ? textColor : '#ff0000'
            text: "0"
            font.family: "Helvetica"
            font.bold: true
            font.pointSize: 30
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            clip: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.fill: parent
            validator: DoubleValidator{decimals: decimal; bottom: minVal; top: maxVal}
            maximumLength: precision
            selectByMouse: true
            selectionColor: '#3399ff'
            onAccepted: {
                if (text1.acceptableInput === true) {
                    widget.value = parseFloat(text1.text);
                    text1.focus = false;
                    widget.valueEntered(widget.value);
                }
                else {
                    console.log('Value out of range');
                }
            }
            readOnly: (widget.active) ? false : true
            onFocusChanged: {
                if (text1.focus === false) {
                    text1.text = widget.value.toFixed(widget.decimal);
                }
            }
        }
    }
}
