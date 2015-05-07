import QtQuick 2.0

Item {
    id: widget
    anchors.centerIn: parent
    width: widget.height
    height: 100
    property color background: '#202020'
    property bool drawOuterRing: true
    property color colorOuter: (dataInput.focus) ? '#39f': '#aaa'
    property int lineWidthOuter: 2
    property color colorInner: '#39f'
    property double dataWidthRatio: 0.2
    property color displayTextColor: '#fff'
    property double displayTextRatio: 0.20
    property double zeroAngle: 270
    property double maxAngle: 270
    property double minValue: 0
    property double maxValue: 1
    property double value: 0
    property double stepSize: 1
    property int decimalPlaces: 0
    property bool useArc: true
    property bool useCursor: true
    property bool displayInput: true
    property bool showFineControl: false
    property bool showLabel: false
    property bool showRange: false
    property bool readOnly: false
    property bool useStepValues: true
    property var stepValues: []

    signal newValue(double value)

    onValueChanged: {
        update();
        dataInput.text = getValue().toFixed(widget.decimalPlaces);
    }
    onMaxValueChanged: update()
    onMinValueChanged: update()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            widget.draw(getContext("2d"));
        }

        Text {
            id: textInc
            x: 46
            y: 16
            text: "+"
            anchors.bottom: dataInput.top
            anchors.bottomMargin: 0
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 0.2*widget.height-5
            color: widget.displayTextColor

            MouseArea {
                 anchors.fill: parent
                 onClicked: {
                     var newVal = widget.value;
                     newVal += widget.stepSize;
                     if (newVal <= widget.maxValue) {
                        widget.value = newVal;
                        widget.newValue(getValue());
                     }
                 }

             }
        }

        Text {
            id: textDec
            x: 46
            y: 16
            text: "-"
            anchors.top: dataInput.bottom
            anchors.topMargin: -2
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 0.2*widget.height-3
            color: widget.displayTextColor

            MouseArea {
                 anchors.fill: parent
                 onClicked: {
                     var newVal = widget.value;
                     newVal -= widget.stepSize;
                     if (newVal >= widget.minValue) {
                        widget.value = newVal;
                        widget.newValue(getValue());
                     }
                 }

             }
        }

        TextInput {
            id: dataInput
            x: 12
            y: widget.height/2*(1 + widget.displayTextRatio)
            color: (acceptableInput) ? widget.displayTextColor : '#ff0000'
            text: widget.stepValues[0]
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            cursorVisible: false
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: widget.displayTextRatio*widget.height
            selectByMouse: true
            selectionColor: '#3399ff'
            readOnly: true
            onFocusChanged: {
                canvas.requestPaint();

                if (dataInput.focus === false) {
                    dataInput.text = getValue().toFixed(widget.decimalPlaces);
                }
            }
        }

    }

    MouseArea {
        id: mousearea1
        anchors.fill: parent
        hoverEnabled: true
        enabled: !widget.readOnly
        property bool ringClick
        property bool centerClick

        onWheel: {
            if (ringClick === false) {
                return;
            }

            var newVal = widget.value;

            if (wheel.angleDelta.y > 0) {
                newVal += widget.stepSize;
            }
            else {
                newVal -= widget.stepSize;
            }

            // Check if value is already at limits
            if (newVal >= widget.maxValue || newVal <= widget.minValue) {
                return;
            }

            widget.value = newVal;
            //widget.newValue(getValue());
        }

        onPressed: {
            if (widget.isInRing(mouse.x, mouse.y)) {
                ringClick = true;
                mouse.accepted = true;
            }
            else if (widget.isInCenter(mouse.x, mouse.y)) {
                centerClick = true;
                mouse.accepted = false;
            }
            else {
                dataInput.focus = false;
            }
        }

        onReleased: {
            if (ringClick === true) {
                widget.newValue(getValue());
                mouse.accepted = true;
            }
            else {
                mouse.accepted = false;
            }

            ringClick = false;
            centerClick = false;
        }

        onPositionChanged: {
            if (mouse.buttons === Qt.LeftButton) {
                if (ringClick === true) {
                    widget.value = widget.xy2val(mouse.x, mouse.y);
                    mouse.accepted = true;
                }
                else {
                    mouse.accepted = false;
                }
            }
        }
    }


    function setValue(text) {
        var number = parseFloat(text);

        if (isNaN(number)) {
            console.log('Result NaN:' + text);
            return;
        }

        if (widget.useStepValues === true) {
            var pos = widget.stepValues.indexOf(number);
            if (pos === -1) {
                console.log("Couldn't find index of " + text + " in StepControl");
            }
            else {
                widget.value = pos;
            }
        }
        else {
            widget.value = number.toFixed(widget.decimalPlaces);
        }
    }

    function getValue() {
        if (widget.useStepValues === true) {
            return widget.stepValues[widget.value];
        }
        else {
            return widget.value;
        }
    }

    function update() {
        canvas.requestPaint();
    }

    function xy2val(x, y) {
        var x1 = -(widget.width/2 - x);
        var y1 = widget.height/2 - y;
        var angle = -Math.atan2(y1, x1) + Math.PI;
        var value, ratio;
        var convertedAngle;

        if (widget.useArc === true) {
            if (angle >= 1.75*Math.PI) {
                convertedAngle = angle - 1.75*Math.PI;
            }
            else if (angle < 1.25*Math.PI) {
                convertedAngle = angle + 0.25*Math.PI;
            }
            else {
                return widget.value;
            }
            ratio = convertedAngle/(1.5*Math.PI);
        }
        else {
            if (angle >= 0 && angle < 0.5*Math.PI) {
                convertedAngle = 1.5*Math.PI + angle;
            }
            else {
                convertedAngle = angle - 0.5*Math.PI;
            }
            ratio = convertedAngle/(2*Math.PI);
        }

        // Quantize fractional angle to stepSize by rounding ratio to nearest step.
        var steps = (widget.maxValue - widget.minValue)/widget.stepSize;
        value = Math.round(ratio*steps)*widget.stepSize + widget.minValue;

        return value;
    }

    function isInRing(x, y) {
        var radius, d;
        var maxRadius = widget.height/2;
        var x1 = Math.pow((widget.width/2 - x), 2);
        var y1 = Math.pow((widget.height/2 - y), 2);

        if (widget.drawOuterRing === true) {
            radius = maxRadius - widget.lineWidthOuter - 2;
        }
        else {
            radius = maxRadius;
        }

        radius -= maxRadius*widget.dataWidthRatio;
        d = Math.sqrt(x1 + y1);

        return (d > radius && d < maxRadius);
    }

    function isInCenter(x, y) {
        var radius, d;
        var maxRadius = widget.height/2;
        var x1 = Math.pow((widget.width/2 - x), 2);
        var y1 = Math.pow((widget.height/2 - y), 2);

        if (widget.drawOuterRing === true) {
            radius = maxRadius - widget.lineWidthOuter - 2;
        }
        else {
            radius = maxRadius;
        }

        radius -= maxRadius*widget.dataWidthRatio;
        d = Math.sqrt(x1 + y1);

        return (d < radius);
    }

    function draw(ctx) {
        var x0 = widget.width/2;
        var y0 = widget.height/2;
        var width;
        var color;
        var radius;
        var maxRadius = widget.height/2;
        var minAngleRad;
        var maxAngleRad;
        var sAngle;
        var eAngle;
        var valueFract = (widget.value - widget.minValue)/(widget.maxValue - widget.minValue);

        if (widget.useArc === true) {
            minAngleRad = 0.75*Math.PI;
            maxAngleRad = minAngleRad + 1.5*Math.PI;
        }
        else {
            minAngleRad = 1.5*Math.PI;
            maxAngleRad = minAngleRad + 2*Math.PI;
        }

        // Fill in background
        ctx.beginPath();
        ctx.fillStyle = widget.background;
        ctx.arc(x0, y0, maxRadius, 0, 2*Math.PI);
        ctx.fill();

        // Draw Outer Ring
        if (widget.drawOuterRing === true) {
            radius = maxRadius - widget.lineWidthOuter/2;
            sAngle = minAngleRad;
            eAngle = sAngle + 2*Math.PI;

            ctx.beginPath();
            ctx.lineWidth = widget.lineWidthOuter;
            ctx.strokeStyle = widget.colorOuter;
            ctx.arc(x0, y0, radius, sAngle, eAngle);
            ctx.stroke();

            if (widget.showRange && widget.useArc) {
                radius = maxRadius - widget.lineWidthOuter - 1;
                radius -= (maxRadius*widget.dataWidthRatio)/2
                sAngle = 0.26*Math.PI;
                eAngle = 0.28*Math.PI;
                ctx.strokeStyle = widget.colorOuter;

                ctx.beginPath();
                ctx.lineWidth = maxRadius*(widget.dataWidthRatio) + 4;
                ctx.arc(x0, y0, radius, sAngle, eAngle);
                ctx.stroke();

                sAngle = 0.72*Math.PI;
                eAngle = 0.74*Math.PI;
                ctx.beginPath();
                ctx.lineWidth = maxRadius*(widget.dataWidthRatio) + 4;
                ctx.arc(x0, y0, radius, sAngle, eAngle);
                ctx.stroke();
            }
        }

        // Draw Inner Ring
        if (widget.useCursor === true) {
            var curAngle = sAngle + valueFract*(maxAngleRad - minAngleRad);
            sAngle = curAngle - 0.1*Math.PI;
            eAngle = curAngle + 0.1*Math.PI;
        }
        else {
            sAngle = minAngleRad;
            eAngle = sAngle + valueFract*(maxAngleRad - minAngleRad);
        }

        if (widget.drawOuterRing === true) {
            radius = maxRadius - widget.lineWidthOuter - 2;
        }
        else {
            radius = maxRadius;
        }

        radius -= (maxRadius*widget.dataWidthRatio)/2

        ctx.beginPath();
        ctx.lineWidth = maxRadius*(widget.dataWidthRatio);
        ctx.strokeStyle = widget.colorInner;
        ctx.arc(x0, y0, radius, sAngle, eAngle);
        ctx.stroke();
    }

}
