import QtQuick 2.0

/*
This is a fork of the GraphComponent widget, which is menat for a stream of data.  I'm
modifying this component to behave more like a 2D plot, where points are explicitly defined.
Many of the features of the GraphComponent will be removed.
*/

Rectangle {
    id: graphWidget
    width: 500
    height: 300
    color: '#000'

    property color graphBackground: '#000'
    property bool rollMode: false
    property bool showScale : false
    property bool autoScale : false
    property color scaleLineColor : '#fff'
    property real scaleLineWidth : 2
    property bool axisShowLabels : true
    property string axisXLabel : 'X Axis'
    property string axisYLabel : 'Y Axis'
    property string axisXUnits : 'V'
    property string axisYUnits : 'V'
    property string axisFont : '12px Arial'
    property string axisFontColor : "#ddd"
    property bool showAxes : true
    property bool showXAxes : true
    property bool showYAxes : true
    property string axesLineColor : "#aaa"
    property bool showGrid : true
    property string gridLineColor : "#333"
    property real gridLineWidth : 1
    property real gridXDiv: 10
    property real gridYDiv: 8
    property real xMaximum: 100
    property real xMinimum: -100
    property real yMaximum: 100
    property real yMinimum: -100
    property int yPadding: 16
    property int xPadding: 16
    property string datasetLineColor: "#39f"
    property bool datasetStroke : true
    property real datasetStrokeWidth : 2
    property bool datasetFill : true
    property int minDatasetSize: 50
    property var datasets: []
    property bool adjustableVdiv: true
    property bool adjustableYOffset: false
    property var vDivSteps: [0.01,0.02,0.05,0.1,0.2,0.5,1.0,2.0,5.0,10.0]
    property int vDivSetting: 4
    property real yOffset: 0.0

    function draw(ctx) {
        var axes={};
        axes.pixelWidth = graph.width - 2*xPadding;
        axes.pixelHeight = graph.height - 2*yPadding;
        axes.xmin = xPadding;
        axes.xmax = xPadding + axes.pixelWidth;
        axes.ymin = yPadding;
        axes.ymax = yPadding + axes.pixelHeight;
        axes.x0 = 0.5 + 0.5*axes.pixelWidth + xPadding;  // x0 pixels from left to x=0
        axes.y0 = 0.5 + 0.5*axes.pixelHeight + yPadding; // y0 pixels from top to y=0        

        // Clear graph
        ctx.fillStyle = graphWidget.graphBackground;
        ctx.fillRect(0,0,graph.width,graph.height);

        if (showGrid)
            drawGrid(ctx, axes);

        if (showAxes)
            drawAxes(ctx, axes);

        if (showScale)
            drawScale(ctx, axes);

        if (adjustableVdiv) {
            setVdiv(graphWidget.vDivSetting);
            ctx.font = axisFont;
            ctx.fillStyle = '#fff';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'top';

            // Draw label
            ctx.fillText('[-] V/Div [+]', 2, 0);
        }

        if (adjustableYOffset) {
            ctx.font = axisFont;
            ctx.fillStyle = '#fff';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'top';

            // Draw  label
            ctx.fillText('[-] V Pos. [+] : ' + graphWidget.yOffset.toFixed(2) + graphWidget.axisYUnits, 80, 0);
        }

        for (var i = 0; i < datasets.length; i++) {
            dataGraph(ctx, axes, i);
        }
    }

    function clearData() {
        datasets = [];
        graph.requestPaint();
    }

    function addPoint(dataPoint, series) {
        var point = parseFloat(dataPoint);

        if (datasets.length < (series + 1)) {
            datasets.push({
                data: [],
                size: minDatasetSize,
                yMaximum: yMaximum,
                yMinimum: yMinimum
            });
        }

        if (isNaN(point)) {
            //python.log('Data Point NaN:' + dataPoint);
            return;
        }

        if (autoScale) {
            var min = 0;
            var max = 0;
            var value;

            for (var i = 0; i < datasets[series].data.length; i++) {
                value = datasets[series].data[i];

                if (value > max) {
                    max = value;
                }
                if (value < min) {
                    min = value;
                }
            }

            datasets[series].yMaximum = max*1.1;
            datasets[series].yMinimum = min*1.1;

            python.log('yMax: ' + datasets[series].yMaximum);
            python.log('yMin: ' + datasets[series].yMinimum);
        }
        else {
            datasets[series].yMaximum = yMaximum;
            datasets[series].yMinimum = yMinimum;
        }

        var index = datasets[series].data.push(point);

        if (datasets[series].data.length > datasets[series].size) {
            datasets[series].data.shift();
        }

        graph.requestPaint();
    }

    function plotData(data, series) {
        datasets[series] = {
            data: data,
            size: data.length
        }

        if (autoScale) {
            var min = 0;
            var max = 0;
            var value;

            for (var i = 0; i < datasets[series].size; i++) {
                value = datasets[series].data[i];

                if (value > max) {
                    max = value;
                }
                if (value < min) {
                    min = value;
                }
            }

            datasets[series].yMaximum = max*1.1;
            datasets[series].yMinimum = min*1.1;

            python.log('yMax: ' + datasets[series].yMaximum);
            python.log('yMin: ' + datasets[series].yMinimum);
        }
        else {
            datasets[series].yMaximum = yMaximum;
            datasets[series].yMinimum = yMinimum;
        }

        graph.requestPaint();
    }

    function refresh() {
        graph.requestPaint();
    }

    function dataGraph (ctx, axes, series) {
        var xx, yy, x0;
        var di = axes.pixelWidth/datasets[series].size;
        var y0 = axes.y0;
        //var scale = (axes.pixelHeight - 0.5)/Math.abs(datasets[series].yMaximum - datasets[series].yMinimum); // 40 pixels from x=0 to x=1
		var scale = (axes.pixelHeight - 0.5)/Math.abs(graphWidget.yMaximum - graphWidget.yMinimum); // 40 pixels from x=0 to x=1
        var length = datasets[series].data.length;

        ctx.beginPath();
        ctx.lineWidth = datasetStrokeWidth;
        ctx.strokeStyle = datasetLineColor;

        if (rollMode) {
            x0 = axes.xmax - length*di;
        }
        else {
            x0 = axes.xmin;
        }

        for (var i = 0; i < length; i++) {
            xx = x0 + i*di;
            yy = y0 - scale*(datasets[series].data[i] + graphWidget.yOffset);

            if (yy > axes.ymax) {
                yy = axes.ymax;
            }

            if (yy < axes.ymin) {
                yy = axes.ymin;
            }

            if (i == 0)
                ctx.moveTo(xx,yy);
            else
                ctx.lineTo(xx,yy);
        }

        ctx.stroke();
    }

    function drawAxes(ctx,axes) {
        ctx.beginPath();
        ctx.lineWidth = 1;
        ctx.strokeStyle = axesLineColor;

        if (showXAxes) {
            ctx.moveTo(axes.xmin,axes.y0);
            ctx.lineTo(axes.xmax,axes.y0);  // X axis
        }

        if (showYAxes) {
            ctx.moveTo(axes.x0,axes.ymin);
            ctx.lineTo(axes.x0,axes.ymax);  // Y axis
        }

        ctx.stroke();

        if (axisShowLabels) {
            ctx.font = axisFont;
            ctx.fillStyle = axisFontColor;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';

            // Draw X axis label
            ctx.fillText(axisXLabel, axes.x0, axes.ymax);

            // Draw Y axis label
            if (graphWidget.adjustableVdiv) {
                var ylabel = axisYLabel + ' [';
                ylabel += graphWidget.vDivSteps[graphWidget.vDivSetting].toString();
                ylabel += ' ' + graphWidget.axisYUnits + '/Div]'
            }
            else {
                var ylabel = axisYLabel;
            }

            ctx.rotate(-90*Math.PI/180);
            ctx.fillText(ylabel, -axes.y0, 0);
            ctx.rotate(90*Math.PI/180);
        }
    }

    function drawGrid(ctx, axes) {
        var dx = axes.pixelWidth/gridXDiv;
        var dy = axes.pixelHeight/gridYDiv;
        var xx, yy;

        ctx.beginPath();
        ctx.lineWidth = gridLineWidth;
        ctx.strokeStyle = gridLineColor;

        for (var i = 0; i <= gridYDiv; i++) {
            yy = Math.round(axes.ymin + i*dy)+0.5;
            ctx.moveTo(axes.xmin,yy);
            ctx.lineTo(axes.xmax,yy);  // X axis
        }

        for (var j = 0; j <= gridXDiv; j++) {
            xx = Math.round(axes.xmin + j*dx)+0.5;
            ctx.moveTo(xx,axes.ymin);
            ctx.lineTo(xx,axes.ymax);  // Y axis
        }

        ctx.stroke();
    }

    function drawScale(ctx, axes) {
        ctx.beginPath();
        ctx.lineWidth = scaleLineWidth;
        ctx.strokeStyle = scaleLineColor;

        ctx.moveTo(axes.xmin,axes.ymax);
        ctx.lineTo(axes.xmax,axes.ymax);

        ctx.moveTo(axes.xmin,axes.ymin);
        ctx.lineTo(axes.xmin,axes.ymax);

        ctx.stroke();
    }

    function setVdiv(step) {
        graphWidget.yMaximum = graphWidget.vDivSteps[step];
        graphWidget.yMinimum = -graphWidget.yMaximum;
        //refresh();
		//python.log(graphWidget.vDivSteps[step]);
    }

    MouseArea {
         id: vDivDecArea
         anchors.top: parent.top
         anchors.left: parent.left
         width: 20
         height: 20
         enabled: graphWidget.adjustableVdiv
         onClicked: {
             if (graphWidget.vDivSetting > 0) {
                graphWidget.vDivSetting--;
				//setVdiv(graphWidget.vDivSetting);
				refresh();
             }
         }
    }

    MouseArea {
         id: vDivIncArea
         anchors.top: parent.top
         anchors.left: vDivDecArea.right
         anchors.leftMargin: 20
         enabled: graphWidget.adjustableVdiv
         width: 20
         height: 20
         onClicked: {
             if (graphWidget.vDivSetting < (graphWidget.vDivSteps.length - 1)) {
                graphWidget.vDivSetting++;
				//setVdiv(graphWidget.vDivSetting);
				refresh();
             }
         }
    }

    MouseArea {
         id: yOffsetDecArea
         x: 80
         y: 0
         width: 20
         height: 20
         enabled: graphWidget.adjustableYOffset
         onClicked: {
             var stepSize = graphWidget.vDivSteps[graphWidget.vDivSetting]/5.0;
             graphWidget.yOffset -= stepSize;
             refresh();
             //python.log(graphWidget.yOffset);
         }
    }

    MouseArea {
         id: yOffsetReset
         anchors.top: parent.top
         anchors.left: yOffsetDecArea.right
         anchors.leftMargin: 2.5
         width: 20
         height: 20
         enabled: graphWidget.adjustableYOffset
         onDoubleClicked: {
             graphWidget.yOffset = 0.0;
             refresh();
             //python.log(graphWidget.yOffset);
         }
    }

    MouseArea {
         id: yOffsetIncArea
         anchors.top: parent.top
         anchors.left: yOffsetReset.right
         anchors.leftMargin: 0
         width: 20
         height: 20
         enabled: graphWidget.adjustableYOffset
         onClicked: {
             var stepSize = graphWidget.vDivSteps[graphWidget.vDivSetting]/5.0;
             graphWidget.yOffset += stepSize;
             refresh();
             //python.log(graphWidget.yOffset);
         }
    }

    Canvas {
        id: graph
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            draw(ctx);
        }

    }
}

