import QtQuick 2.0

Item {
    height: text1.contentHeight + 10
    width: text1.contentWidth + 10
    property alias text: text1.text
    property string textColor: "#ff0000"
    property alias pointSize: text1.font.pointSize
    property alias background: rect1.color
    property int decimal: 2
    property int precision: 4
    property bool fixedPrecision: false
    property bool useBorder: true
    property bool showUnits: false
    property string units: 'V'
    property bool active: true

    function setValue(text) {
        var number = parseFloat(text);

        if (isNaN(number)) {
            console.log('Result NaN:' + text);
            return false;
        }

        if (fixedPrecision) {
            text1.text = number.toPrecision(precision);
        }
        else {
            text1.text = number.toFixed(decimal);
        }

        if (showUnits) {
            text1.text += ' ' + units;
        }

        return true;
    }

    Rectangle {
        id: rect1
        anchors.fill: parent
        clip: false
        color: (useBorder) ? '#333333' : 'transparent';
        border.color: '#cccccc'
        border.width: (useBorder) ? 1 : 0;
        radius: 10

        Text {
            id: text1
            color: (active) ? textColor : '#666666'
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
        }
    }
}
