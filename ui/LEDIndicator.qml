import QtQuick 2.0

Rectangle {
	height: 20
	width: 65
	color: "transparent"

	property string labelText: "test"
	property color labelTextColor: "#CCCCCC"
	property bool currentState: true

	function setState(newState){
		if(newState == true){
			light.color = "#00CC00"
			currentState = true
		}
		else{
			light.color = "#CC0000"
			currentState = false
		}
	}

	Rectangle {
		id: light
		width: 15
		height: 15
		radius: 7
		color: "#00CC00"
		border.color: "#CCCCCC"
		border.width: 1
		anchors {
			left: parent.left
			verticalCenter: parent.verticalCenter
			margins: 5
		}
	}

	Text {
		id: labelTextItem
		width: 40
		color: labelTextColor
		anchors {
			left: light.right
			right: parent.right
			verticalCenter: parent.verticalCenter
			margins: 5
		}
		text: labelText
	}
}