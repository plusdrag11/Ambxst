pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.widgets.dashboard.wallpapers
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    property string currentSection: ""
    property string selectedVariant: "bg"
    property bool customIntervalActive: false

    component SectionButton: StyledRect {
        id: sectionBtn
        required property string text
        required property string sectionId

        property bool isHovered: false

        variant: isHovered ? "focus" : "pane"
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: Styling.radius(0)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Text {
                text: sectionBtn.text
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                font.bold: true
                color: Colors.overBackground
                Layout.fillWidth: true
            }

            Text {
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 20
                color: Colors.overSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: sectionBtn.isHovered = true
            onExited: sectionBtn.isHovered = false
            onClicked: root.currentSection = sectionBtn.sectionId
        }
    }

    component ToggleRow: RowLayout {
        id: toggleRowRoot
        property string label: ""
        property bool checked: false
        signal toggled(bool value)

        property bool _updating: false

        onCheckedChanged: {
            if (!_updating && toggleSwitch.checked !== checked) {
                _updating = true;
                toggleSwitch.checked = checked;
                _updating = false;
            }
        }

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: toggleRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        Switch {
            id: toggleSwitch
            checked: toggleRowRoot.checked

            onCheckedChanged: {
                if (!toggleRowRoot._updating && checked !== toggleRowRoot.checked) {
                    toggleRowRoot.toggled(checked);
                }
            }

            indicator: Rectangle {
                implicitWidth: 40
                implicitHeight: 20
                x: toggleSwitch.leftPadding
                y: parent.height / 2 - height / 2
                radius: height / 2
                color: toggleSwitch.checked ? Styling.srItem("overprimary") : Colors.surfaceBright
                border.color: toggleSwitch.checked ? Styling.srItem("overprimary") : Colors.outline

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration / 2
                    }
                }

                Rectangle {
                    x: toggleSwitch.checked ? parent.width - width - 2 : 2
                    y: 2
                    width: parent.height - 4
                    height: width
                    radius: width / 2
                    color: toggleSwitch.checked ? Colors.onPrimary : Colors.outline

                    Behavior on x {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    component SelectorRow: ColumnLayout {
        id: selectorRowRoot
        property string label: ""
        property var options: []
        property var value: ""
        property var selectedValue: value
        signal valueSelected(var newValue)

        function getIndexFromValue(val): int {
            for (let i = 0; i < options.length; i++) {
                if (options[i].value === val)
                    return i;
            }
            return -1;
        }

        Layout.fillWidth: true
        spacing: 4

        Text {
            text: selectorRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            font.weight: Font.Medium
            color: Colors.overSurfaceVariant
            visible: selectorRowRoot.label !== ""
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: selectorRowRoot.options

                delegate: StyledRect {
                    id: optionButton
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: selectorRowRoot.getIndexFromValue(selectorRowRoot.selectedValue) === index
                    property bool isHovered: false

                    variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                    enableShadow: true
                    Layout.fillWidth: true
                    height: 36
                    radius: isSelected ? Styling.radius(0) / 2 : Styling.radius(0)

                    Text {
                        anchors.centerIn: parent
                        text: optionButton.modelData.label
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        font.bold: true
                        color: optionButton.item
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: optionButton.isHovered = true
                        onExited: optionButton.isHovered = false

                        onClicked: selectorRowRoot.valueSelected(optionButton.modelData.value)
                    }
                }
            }
        }
    }

    // Color picker state
    property bool colorPickerActive: false
    property var colorPickerColorNames: []
    property string colorPickerCurrentColor: ""
    property string colorPickerDialogTitle: ""
    property var colorPickerCallback: null

    function openColorPicker(colorNames, currentColor, dialogTitle, callback) {
        colorPickerColorNames = colorNames;
        colorPickerCurrentColor = currentColor;
        colorPickerDialogTitle = dialogTitle;
        colorPickerCallback = callback;
        colorPickerActive = true;
    }

    function closeColorPicker() {
        colorPickerActive = false;
        colorPickerCallback = null;
    }

    function handleColorSelected(color) {
        if (colorPickerCallback) {
            colorPickerCallback(color);
        }
        colorPickerCurrentColor = color;
    }

    FileView {
        id: wallpaperConfig
        // QUICKSHELL-GIT: path: Quickshell.cachePath("wallpapers.json")
        path: Quickshell.env("HOME") + "/.cache/ambxst/wallpapers.json"

        JsonAdapter {
            property string currentWall: ""
            property string wallPath: ""
            property string matugenScheme: "scheme-tonal-spot"
            property string activeColorPreset: ""
            property string transitionType: "random"
            property int transitionDuration: 1000
            property int transitionWaveCount: 3
            property int transitionStripeCount: 0
            property int transitionHoneycombSize: 1
            property string transitionFillColor: "#000000"
            property string transitionEasing: "inOutCubic"
            property string transitionInterrupt: "freeze"
            property string transitionInterruptReplay: "same"
            property bool autochangeEnabled: false
            property int autochangeInterval: 1800000
            property string autochangeMode: "shuffle"
            property bool autochangeApplyPalette: true
        }
    }

    // Convert sr property name to variant id (srBg -> bg, srPrimaryFocus -> primaryfocus)
    function srNameToId(srName: string): string {
        return srName.substring(2).toLowerCase();
    }

    // Dynamically generate allVariants from Config.theme properties starting with "sr"
    // Reads the label property from each variant config
    readonly property var allVariants: {
        let variants = [];
        let theme = Config.theme;

        // Get all property names from theme that start with "sr"
        for (let prop in theme) {
            if (prop.startsWith("sr") && theme[prop] && typeof theme[prop] === "object") {
                // Read label from the variant config itself, fallback to property name
                let label = theme[prop].label || prop.substring(2);
                variants.push({
                    id: srNameToId(prop),
                    label: label
                });
            }
        }

        return variants;
    }

    function getVariantLabel(variantId: string): string {
        for (var i = 0; i < allVariants.length; i++) {
            if (allVariants[i].id === variantId) {
                return allVariants[i].label;
            }
        }
        return variantId;
    }

    // Main content - single Flickable for everything, fills entire width
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.colorPickerActive

        // Horizontal slide + fade animation
        opacity: root.colorPickerActive ? 0 : 1
        transform: Translate {
            id: mainTranslate
            x: root.colorPickerActive ? -30 : 0

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // Header wrapper
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: root.currentSection === "" ? "Theme" : (root.currentSection.charAt(0).toUpperCase() + root.currentSection.slice(1))
                    statusText: GlobalStates.themeHasChanges ? "Unsaved changes" : ""
                    statusColor: Colors.error

                    actions: {
                        let baseActions = [
                            {
                                icon: Icons.arrowCounterClockwise,
                                tooltip: "Discard changes",
                                enabled: GlobalStates.themeHasChanges,
                                onClicked: function () {
                                    GlobalStates.discardThemeChanges();
                                }
                            },
                            {
                                icon: Icons.disk,
                                tooltip: "Apply changes",
                                enabled: GlobalStates.themeHasChanges,
                                onClicked: function () {
                                    GlobalStates.applyThemeChanges();
                                }
                            }
                        ];

                        if (root.currentSection !== "") {
                            return [
                                {
                                    icon: Icons.arrowLeft,
                                    tooltip: "Back",
                                    onClicked: function () {
                                        root.currentSection = "";
                                    }
                                }
                            ].concat(baseActions);
                        }

                        return baseActions;
                    }
                }
            }

            // Content wrapper - centered
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    // ═══════════════════════════════════════════════════════════════
                    // MENU SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        visible: root.currentSection === ""
                        Layout.fillWidth: true
                        spacing: 8

                        SectionButton {
                            text: "General"
                            sectionId: "general"
                        }
                        SectionButton {
                            text: "Shadow"
                            sectionId: "shadow"
                        }
                        SectionButton {
                            text: "Colors"
                            sectionId: "colors"
                        }
                    }

                    // General section
                    Item {
                        visible: root.currentSection === "general"
                        Layout.fillWidth: true
                        Layout.preferredHeight: generalContent.implicitHeight

                        ColumnLayout {
                            id: generalContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 8

                            Text {
                                text: "General"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            // Wallpaper Path
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Wallpapers"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: wallPathInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter

                                        // Placeholder for default path
                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Default"
                                            font: parent.font
                                            color: Colors.overSurfaceVariant
                                            visible: !parent.text && !parent.activeFocus
                                        }

                                        text: wallpaperConfig.adapter.wallPath

                                        onEditingFinished: {
                                            if (wallpaperConfig.adapter.wallPath !== text) {
                                                wallpaperConfig.adapter.wallPath = text;
                                                wallpaperConfig.writeAdapter();
                                            }
                                        }
                                    }
                                }

                                // Browse button
                                StyledRect {
                                    variant: "common"
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    property bool isHovered: false

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.folder
                                        font.family: Icons.font
                                        font.pixelSize: 16
                                        color: Colors.overBackground
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: parent.isHovered = true
                                        onExited: parent.isHovered = false
                                        onClicked: themeWallDirDialog.open()
                                    }
                                }
                            }

                            // Autochange toggle
                            ToggleRow {
                                label: "Autochange"
                                checked: wallpaperConfig.adapter.autochangeEnabled
                                onToggled: function(value) {
                                    wallpaperConfig.adapter.autochangeEnabled = value;
                                    wallpaperConfig.writeAdapter();
                                }
                            }

                            // Autochange interval selector
                            SelectorRow {
                                id: intervalSelector
                                label: "Interval"
                                visible: wallpaperConfig.adapter.autochangeEnabled
                                options: [
                                    { label: "5m", value: 300000 },
                                    { label: "15m", value: 900000 },
                                    { label: "30m", value: 1800000 },
                                    { label: "1h", value: 3600000 },
                                    { label: "Custom", value: -1 }
                                ]
                                value: wallpaperConfig.adapter.autochangeInterval
                                selectedValue: root.customIntervalActive ? -1 : wallpaperConfig.adapter.autochangeInterval
                                onValueSelected: function(newValue) {
                                    if (newValue === -1) {
                                        root.customIntervalActive = true;
                                        return;
                                    }
                                    root.customIntervalActive = false;
                                    wallpaperConfig.adapter.autochangeInterval = newValue;
                                    wallpaperConfig.writeAdapter();
                                }
                            }

                            // Custom interval input
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.autochangeEnabled && root.customIntervalActive

                                Text {
                                    text: "Minutes"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: customIntervalInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        inputMethodHints: Qt.ImhDigitsOnly

                                        text: String(Math.round(wallpaperConfig.adapter.autochangeInterval / 60000))

                                        onEditingFinished: {
                                            var mins = parseInt(text);
                                            if (!isNaN(mins) && mins >= 5) {
                                                var ms = mins * 60000;
                                                if (wallpaperConfig.adapter.autochangeInterval !== ms) {
                                                    wallpaperConfig.adapter.autochangeInterval = ms;
                                                    wallpaperConfig.writeAdapter();
                                                }
                                            } else {
                                                // Revert to the current value if below the 5 minute floor
                                                customIntervalInput.text = String(Math.round(wallpaperConfig.adapter.autochangeInterval / 60000));
                                            }
                                        }
                                    }
                                }
                            }

                            // Autochange mode selector
                            SelectorRow {
                                label: "Mode"
                                visible: wallpaperConfig.adapter.autochangeEnabled
                                options: [
                                    { label: "Shuffle", value: "shuffle" },
                                    { label: "Sequential", value: "sequential" }
                                ]
                                value: wallpaperConfig.adapter.autochangeMode
                                onValueSelected: function(newValue) {
                                    wallpaperConfig.adapter.autochangeMode = newValue;
                                    wallpaperConfig.writeAdapter();
                                }
                            }

                            // Autochange palette update toggle (picture only mode)
                            ToggleRow {
                                label: "Update colors on change"
                                visible: wallpaperConfig.adapter.autochangeEnabled
                                checked: wallpaperConfig.adapter.autochangeApplyPalette
                                onToggled: function(value) {
                                    wallpaperConfig.adapter.autochangeApplyPalette = value;
                                    wallpaperConfig.writeAdapter();
                                }
                            }

                            // Wallpaper transition type
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Transition"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: transitionCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    readonly property var transitionValues: ["random", "none", "fade", "wipe", "grow", "outer", "wave", "diagonal", "stripes", "zoom", "honeycomb", "iris", "pixelate"]
                                    readonly property string configValue: wallpaperConfig.adapter.transitionType

                                    model: ["Random", "None", "Fade", "Wipe", "Grow", "Outer", "Wave", "Diagonal", "Stripes", "Zoom", "Honeycomb", "Iris", "Pixelate"]

                                    function syncIndex() {
                                        currentIndex = transitionValues.indexOf(configValue);
                                    }

                                    onConfigValueChanged: syncIndex()
                                    Component.onCompleted: syncIndex()

                                    // Custom grammar (e.g. "wipe-left", comma lists) set by hand shows raw
                                    displayText: currentIndex >= 0 ? currentText : configValue

                                    onActivated: index => {
                                        if (wallpaperConfig.adapter.transitionType !== transitionValues[index]) {
                                            wallpaperConfig.adapter.transitionType = transitionValues[index];
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }

                                    background: Rectangle {
                                        color: transitionCombo.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                        radius: Styling.radius(-2)
                                        border.color: Colors.outlineVariant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 32
                                        text: transitionCombo.displayText
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    indicator: Text {
                                        x: transitionCombo.width - width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 18
                                        color: Colors.overBackground
                                    }

                                    popup: Popup {
                                        y: transitionCombo.height + 4
                                        width: transitionCombo.width
                                        implicitHeight: Math.min(transitionListView.contentHeight + 8, 300)
                                        padding: 4

                                        background: Rectangle {
                                            color: Colors.surfaceContainerLow
                                            radius: Styling.radius(-1)
                                            border.color: Colors.outlineVariant
                                            border.width: 1
                                        }

                                        ListView {
                                            id: transitionListView
                                            anchors.fill: parent
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: transitionCombo.popup.visible ? transitionCombo.delegateModel : null
                                            currentIndex: transitionCombo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }
                                    }

                                    delegate: ItemDelegate {
                                        id: transitionDelegate
                                        required property var modelData
                                        required property int index

                                        width: ListView.view.width - 8
                                        height: 32

                                        background: Rectangle {
                                            color: transitionDelegate.highlighted ? Colors.surfaceContainerHigh : "transparent"
                                            radius: Styling.radius(-2)
                                        }

                                        contentItem: Text {
                                            text: transitionDelegate.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        highlighted: transitionCombo.highlightedIndex === index
                                    }
                                }
                            }

                            // Wallpaper transition duration slider
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Trans. Time"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: transitionDurationSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round(value * 3000)}ms`
                                    scroll: true
                                    stepSize: 0.01 // 30ms steps (1/100 of 3000ms)
                                    snapMode: "always"
                                    updateOnRelease: true

                                    readonly property real configValue: wallpaperConfig.adapter.transitionDuration / 3000

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newDuration = Math.round(value * 3000);
                                        if (newDuration !== wallpaperConfig.adapter.transitionDuration) {
                                            wallpaperConfig.adapter.transitionDuration = newDuration;
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }
                                }

                                Text {
                                    text: wallpaperConfig.adapter.transitionDuration + "ms"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 50
                                }
                            }

                            // Transition easing selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType !== "none" && wallpaperConfig.adapter.transitionDuration > 0

                                Text {
                                    text: "Easing"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: easingCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    readonly property var values: ["inOutCubic", "outCubic", "outExpo", "linear", "inCubic"]

                                    model: ["Smooth", "Snappy", "Punchy", "Linear", "Gentle start"]

                                    currentIndex: Math.max(0, values.indexOf(wallpaperConfig.adapter.transitionEasing))

                                    onActivated: index => {
                                        const val = values[index];
                                        if (val !== wallpaperConfig.adapter.transitionEasing) {
                                            wallpaperConfig.adapter.transitionEasing = val;
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }

                                    background: Rectangle {
                                        color: easingCombo.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                        radius: Styling.radius(-2)
                                        border.color: Colors.outlineVariant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 32
                                        text: easingCombo.displayText
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    indicator: Text {
                                        x: easingCombo.width - width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 18
                                        color: Colors.overBackground
                                    }

                                    popup: Popup {
                                        y: easingCombo.height + 4
                                        width: easingCombo.width
                                        implicitHeight: Math.min(easingListView.contentHeight + 8, 300)
                                        padding: 4

                                        background: Rectangle {
                                            color: Colors.surfaceContainerLow
                                            radius: Styling.radius(-1)
                                            border.color: Colors.outlineVariant
                                            border.width: 1
                                        }

                                        ListView {
                                            id: easingListView
                                            anchors.fill: parent
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: easingCombo.popup.visible ? easingCombo.delegateModel : null
                                            currentIndex: easingCombo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }
                                    }

                                    delegate: ItemDelegate {
                                        id: easingDelegate
                                        required property var modelData
                                        required property int index

                                        width: ListView.view.width - 8
                                        height: 32

                                        background: Rectangle {
                                            color: easingDelegate.highlighted ? Colors.surfaceContainerHigh : "transparent"
                                            radius: Styling.radius(-2)
                                        }

                                        contentItem: Text {
                                            text: easingDelegate.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        highlighted: easingCombo.highlightedIndex === index
                                    }
                                }
                            }

                            // Interrupt behavior selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType !== "none" && wallpaperConfig.adapter.transitionDuration > 0

                                Text {
                                    text: "When interrupted"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: interruptCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    readonly property var values: ["freeze", "reverse"]

                                    model: ["Freeze & restart", "Reverse first"]

                                    currentIndex: Math.max(0, values.indexOf(wallpaperConfig.adapter.transitionInterrupt))

                                    onActivated: index => {
                                        const val = values[index];
                                        if (val !== wallpaperConfig.adapter.transitionInterrupt) {
                                            wallpaperConfig.adapter.transitionInterrupt = val;
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }

                                    background: Rectangle {
                                        color: interruptCombo.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                        radius: Styling.radius(-2)
                                        border.color: Colors.outlineVariant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 32
                                        text: interruptCombo.displayText
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    indicator: Text {
                                        x: interruptCombo.width - width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 18
                                        color: Colors.overBackground
                                    }

                                    popup: Popup {
                                        y: interruptCombo.height + 4
                                        width: interruptCombo.width
                                        implicitHeight: Math.min(interruptListView.contentHeight + 8, 300)
                                        padding: 4

                                        background: Rectangle {
                                            color: Colors.surfaceContainerLow
                                            radius: Styling.radius(-1)
                                            border.color: Colors.outlineVariant
                                            border.width: 1
                                        }

                                        ListView {
                                            id: interruptListView
                                            anchors.fill: parent
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: interruptCombo.popup.visible ? interruptCombo.delegateModel : null
                                            currentIndex: interruptCombo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }
                                    }

                                    delegate: ItemDelegate {
                                        id: interruptDelegate
                                        required property var modelData
                                        required property int index

                                        width: ListView.view.width - 8
                                        height: 32

                                        background: Rectangle {
                                            color: interruptDelegate.highlighted ? Colors.surfaceContainerHigh : "transparent"
                                            radius: Styling.radius(-2)
                                        }

                                        contentItem: Text {
                                            text: interruptDelegate.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        highlighted: interruptCombo.highlightedIndex === index
                                    }
                                }
                            }

                            // Replay mode selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType !== "none" && wallpaperConfig.adapter.transitionDuration > 0

                                Text {
                                    text: "Replay with"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: replayCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    readonly property var values: ["same", "new"]

                                    model: ["Same transition", "New transition"]

                                    currentIndex: Math.max(0, values.indexOf(wallpaperConfig.adapter.transitionInterruptReplay))

                                    onActivated: index => {
                                        const val = values[index];
                                        if (val !== wallpaperConfig.adapter.transitionInterruptReplay) {
                                            wallpaperConfig.adapter.transitionInterruptReplay = val;
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }

                                    background: Rectangle {
                                        color: replayCombo.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                        radius: Styling.radius(-2)
                                        border.color: Colors.outlineVariant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 32
                                        text: replayCombo.displayText
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    indicator: Text {
                                        x: replayCombo.width - width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 18
                                        color: Colors.overBackground
                                    }

                                    popup: Popup {
                                        y: replayCombo.height + 4
                                        width: replayCombo.width
                                        implicitHeight: Math.min(replayListView.contentHeight + 8, 300)
                                        padding: 4

                                        background: Rectangle {
                                            color: Colors.surfaceContainerLow
                                            radius: Styling.radius(-1)
                                            border.color: Colors.outlineVariant
                                            border.width: 1
                                        }

                                        ListView {
                                            id: replayListView
                                            anchors.fill: parent
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: replayCombo.popup.visible ? replayCombo.delegateModel : null
                                            currentIndex: replayCombo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }
                                    }

                                    delegate: ItemDelegate {
                                        id: replayDelegate
                                        required property var modelData
                                        required property int index

                                        width: ListView.view.width - 8
                                        height: 32

                                        background: Rectangle {
                                            color: replayDelegate.highlighted ? Colors.surfaceContainerHigh : "transparent"
                                            radius: Styling.radius(-2)
                                        }

                                        contentItem: Text {
                                            text: replayDelegate.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        highlighted: replayCombo.highlightedIndex === index
                                    }
                                }
                            }

                            // Transition preview toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType !== "none"

                                Text {
                                    text: "Preview"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    id: previewToggle
                                    checked: false

                                    indicator: Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 20
                                        x: previewToggle.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: height / 2
                                        color: previewToggle.checked ? Styling.srItem("overprimary") : Colors.surfaceBright
                                        border.color: previewToggle.checked ? Styling.srItem("overprimary") : Colors.outline

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation { duration: Config.animDuration / 2 }
                                        }

                                        Rectangle {
                                            x: previewToggle.checked ? parent.width - width - 2 : 2
                                            y: 2
                                            width: parent.height - 4
                                            height: width
                                            radius: width / 2
                                            color: previewToggle.checked ? Colors.background : Colors.overSurfaceVariant

                                            Behavior on x {
                                                enabled: Config.animDuration > 0
                                                NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                    background: null
                                }
                            }

                            // Transition preview
                            StyledRect {
                                variant: "internalbg"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 180
                                Layout.topMargin: 4
                                Layout.bottomMargin: 4
                                radius: Styling.radius(-1)
                                visible: previewToggle.checked && wallpaperConfig.adapter.transitionType !== "none"

                                WallpaperTransitionPreview {
                                    id: transitionPreview
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    wallpaperPath: wallpaperConfig.adapter.currentWall
                                    type: {
                                        var t = wallpaperConfig.adapter.transitionType;
                                        if (t === "none" || t === "")
                                            return "fade";
                                        return t;
                                    }
                                    playing: previewToggle.checked && visible
                                    loop: true
                                    waveCount: wallpaperConfig.adapter.transitionWaveCount
                                    stripeCount: wallpaperConfig.adapter.transitionStripeCount
                                    honeycombSize: wallpaperConfig.adapter.transitionHoneycombSize
                                    transitionEasing: wallpaperConfig.adapter.transitionEasing
                                }

                                // Play button overlay
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        transitionPreview.playing = false;
                                        Qt.callLater(() => transitionPreview.playing = previewToggle.checked && visible);
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    text: Icons.play
                                    font.family: Icons.font
                                    font.pixelSize: 16
                                    color: Colors.overSurfaceVariant
                                    opacity: 0.6
                                }
                            }

                            // --- Advanced transition controls (visible per type) ---

                            // Wave count (0 = random, 1-8 = fixed count)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType === "wave" || wallpaperConfig.adapter.transitionType.indexOf("wave") !== -1

                                Text {
                                    text: "Waves"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: waveCountSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: _waveInt === 0 ? "Random" : `${_waveInt}`
                                    scroll: true
                                    stepSize: 0.01
                                    snapMode: "always"

                                    property int _waveInt: wallpaperConfig.adapter.transitionWaveCount
                                    readonly property real configValue: _waveInt / 8

                                    onConfigValueChanged: {
                                        let target = configValue;
                                        if (Math.abs(value - target) > 0.001) {
                                            value = target;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let v = Math.round(value * 8);
                                        if (v !== wallpaperConfig.adapter.transitionWaveCount) {
                                            wallpaperConfig.adapter.transitionWaveCount = v;
                                            wallpaperConfig.writeAdapter();
                                            _waveInt = v;
                                        }
                                    }
                                }

                                Text {
                                    text: waveCountSlider._waveInt === 0 ? "Rnd" : waveCountSlider._waveInt
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 30
                                }
                            }

                            // Stripe count (0 = random, 2-24 = fixed count, skip 1)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType === "stripes" || wallpaperConfig.adapter.transitionType.indexOf("stripes") !== -1

                                Text {
                                    text: "Stripes"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: stripeCountSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: _stripeInt === 0 ? "Random" : `${_stripeInt}`
                                    scroll: true
                                    stepSize: 0.01
                                    snapMode: "always"

                                    property int _stripeInt: wallpaperConfig.adapter.transitionStripeCount
                                    readonly property real configValue: _stripeInt <= 1 ? _stripeInt / 24 : (_stripeInt - 1) / 23

                                    onConfigValueChanged: {
                                        let target = configValue;
                                        if (Math.abs(value - target) > 0.001) {
                                            value = target;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        // Map 0-1 to 0,2-24 (skip 1)
                                        let raw = Math.round(value * 24);
                                        let v;
                                        if (raw <= 1) v = raw === 0 ? 0 : 2;
                                        else v = Math.min(24, raw);
                                        if (v !== wallpaperConfig.adapter.transitionStripeCount) {
                                            wallpaperConfig.adapter.transitionStripeCount = v;
                                            wallpaperConfig.writeAdapter();
                                            _stripeInt = v;
                                        }
                                    }
                                }

                                Text {
                                    text: stripeCountSlider._stripeInt === 0 ? "Rnd" : stripeCountSlider._stripeInt
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 30
                                }
                            }

                            // Honeycomb size
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType === "honeycomb" || wallpaperConfig.adapter.transitionType.indexOf("honeycomb") !== -1

                                Text {
                                    text: "Honeycomb"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: honeycombCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32

                                    readonly property var sizeValues: [0, 1, 2, 3]
                                    readonly property var sizeLabels: ["XS", "S", "M", "L"]
                                    readonly property int configValue: wallpaperConfig.adapter.transitionHoneycombSize

                                    model: sizeLabels

                                    function syncIndex() {
                                        currentIndex = sizeValues.indexOf(configValue);
                                    }

                                    onConfigValueChanged: syncIndex()
                                    Component.onCompleted: syncIndex()

                                    onActivated: index => {
                                        let v = sizeValues[index];
                                        if (v !== wallpaperConfig.adapter.transitionHoneycombSize) {
                                            wallpaperConfig.adapter.transitionHoneycombSize = v;
                                            wallpaperConfig.writeAdapter();
                                        }
                                    }

                                    background: Rectangle {
                                        color: honeycombCombo.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
                                        radius: Styling.radius(-2)
                                        border.color: Colors.outlineVariant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 32
                                        text: honeycombCombo.displayText
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    indicator: Text {
                                        x: honeycombCombo.width - width - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 18
                                        color: Colors.overBackground
                                    }

                                    popup: Popup {
                                        y: honeycombCombo.height + 4
                                        width: honeycombCombo.width
                                        implicitHeight: Math.min(honeycombListView.contentHeight + 8, 200)
                                        padding: 4

                                        background: Rectangle {
                                            color: Colors.surfaceContainerLow
                                            radius: Styling.radius(-1)
                                            border.color: Colors.outlineVariant
                                            border.width: 1
                                        }

                                        ListView {
                                            id: honeycombListView
                                            anchors.fill: parent
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: honeycombCombo.popup.visible ? honeycombCombo.delegateModel : null
                                            currentIndex: honeycombCombo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator {}
                                        }
                                    }

                                    delegate: ItemDelegate {
                                        id: hcDelegate
                                        required property var modelData
                                        required property int index

                                        width: ListView.view.width - 8
                                        height: 32

                                        background: Rectangle {
                                            color: hcDelegate.highlighted ? Colors.surfaceContainerHigh : "transparent"
                                            radius: Styling.radius(-2)
                                        }

                                        contentItem: Text {
                                            text: hcDelegate.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        highlighted: honeycombCombo.highlightedIndex === index
                                    }
                                }
                            }

                            // Fill color
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: wallpaperConfig.adapter.transitionType !== "none" && wallpaperConfig.adapter.transitionType !== "random" && wallpaperConfig.adapter.transitionType !== "fade"

                                Text {
                                    text: "Fill Color"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    id: fillColorButton
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    property bool isHovered: false

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            radius: 4
                                            color: wallpaperConfig.adapter.transitionFillColor
                                            border.width: 1
                                            border.color: Colors.outline
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: wallpaperConfig.adapter.transitionFillColor
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: Colors.overBackground
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Styling.srItem("overprimary")
                                        radius: fillColorButton.radius ?? 0
                                        opacity: fillColorButton.isHovered ? 0.15 : 0

                                        Behavior on opacity {
                                            enabled: (Config.animDuration ?? 0) > 0
                                            NumberAnimation {
                                                duration: (Config.animDuration ?? 0) / 2
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: fillColorButton.isHovered = true
                                        onExited: fillColorButton.isHovered = false

                                        onClicked: {
                                            root.openColorPicker(Colors.availableColorNames, wallpaperConfig.adapter.transitionFillColor, "Select Fill Color", function (color) {
                                                wallpaperConfig.adapter.transitionFillColor = color;
                                                wallpaperConfig.writeAdapter();
                                            });
                                        }
                                    }
                                }
                            }

                            // Tint Icons toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Tint Icons"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    id: tintIconsSwitch
                                    checked: Config.theme.tintIcons

                                    readonly property bool configValue: Config.theme.tintIcons

                                    onConfigValueChanged: {
                                        if (checked !== configValue) {
                                            checked = configValue;
                                        }
                                    }

                                    onCheckedChanged: {
                                        if (checked !== Config.theme.tintIcons) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.tintIcons = checked;
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 20
                                        x: tintIconsSwitch.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: height / 2
                                        color: tintIconsSwitch.checked ? Styling.srItem("overprimary") : Colors.surfaceBright
                                        border.color: tintIconsSwitch.checked ? Styling.srItem("overprimary") : Colors.outline

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                            }
                                        }

                                        Rectangle {
                                            x: tintIconsSwitch.checked ? parent.width - width - 2 : 2
                                            y: 2
                                            width: parent.height - 4
                                            height: width
                                            radius: width / 2
                                            color: tintIconsSwitch.checked ? Colors.background : Colors.overSurfaceVariant

                                            Behavior on x {
                                                enabled: Config.animDuration > 0
                                                NumberAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                    background: null
                                }
                            }

                            // Enable Corners toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Enable Corners"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.fillWidth: true
                                }

                                Switch {
                                    id: enableCornersSwitch
                                    checked: Config.theme.enableCorners

                                    readonly property bool configValue: Config.theme.enableCorners

                                    onConfigValueChanged: {
                                        if (checked !== configValue) {
                                            checked = configValue;
                                        }
                                    }

                                    onCheckedChanged: {
                                        if (checked !== Config.theme.enableCorners) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.enableCorners = checked;
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 20
                                        x: enableCornersSwitch.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: height / 2
                                        color: enableCornersSwitch.checked ? Styling.srItem("overprimary") : Colors.surfaceBright
                                        border.color: enableCornersSwitch.checked ? Styling.srItem("overprimary") : Colors.outline

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                            }
                                        }

                                        Rectangle {
                                            x: enableCornersSwitch.checked ? parent.width - width - 2 : 2
                                            y: 2
                                            width: parent.height - 4
                                            height: width
                                            radius: width / 2
                                            color: enableCornersSwitch.checked ? Colors.background : Colors.overSurfaceVariant

                                            Behavior on x {
                                                enabled: Config.animDuration > 0
                                                NumberAnimation {
                                                    duration: Config.animDuration / 2
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                    background: null
                                }
                            }

                            // Animation Duration slider
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Animation"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: animDurationSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round(value * 1000)}ms`
                                    scroll: true
                                    stepSize: 0.01  // 10ms steps (1/100 of 1000ms)
                                    snapMode: "always"

                                    readonly property real configValue: Config.theme.animDuration / 1000

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newDuration = Math.round(value * 1000);
                                        if (newDuration !== Config.theme.animDuration) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.animDuration = newDuration;
                                        }
                                    }
                                }

                                Text {
                                    text: Config.theme.animDuration + "ms"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 50
                                }
                            }

                            Separator {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Fonts"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            // UI Font row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "UI Font"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: fontInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter

                                        readonly property string configValue: Config.theme.font

                                        onConfigValueChanged: {
                                            if (text !== configValue) {
                                                text = configValue;
                                            }
                                        }

                                        Component.onCompleted: text = configValue

                                        onEditingFinished: {
                                            if (text !== Config.theme.font && text.trim() !== "") {
                                                GlobalStates.markThemeChanged();
                                                Config.theme.font = text.trim();
                                            }
                                        }
                                    }
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: fontSizeInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator {
                                            bottom: 8
                                            top: 32
                                        }

                                        readonly property int configValue: Config.theme.fontSize

                                        onConfigValueChanged: {
                                            if (text !== configValue.toString()) {
                                                text = configValue.toString();
                                            }
                                        }

                                        Component.onCompleted: text = configValue.toString()

                                        onEditingFinished: {
                                            let newSize = parseInt(text);
                                            if (!isNaN(newSize) && newSize >= 8 && newSize <= 32 && newSize !== Config.theme.fontSize) {
                                                GlobalStates.markThemeChanged();
                                                Config.theme.fontSize = newSize;
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: "px"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overSurfaceVariant
                                }
                            }

                            // Mono Font row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Mono Font"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: monoFontInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.monoFont
                                        font.pixelSize: Styling.monoFontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter

                                        readonly property string configValue: Config.theme.monoFont

                                        onConfigValueChanged: {
                                            if (text !== configValue) {
                                                text = configValue;
                                            }
                                        }

                                        Component.onCompleted: text = configValue

                                        onEditingFinished: {
                                            if (text !== Config.theme.monoFont && text.trim() !== "") {
                                                GlobalStates.markThemeChanged();
                                                Config.theme.monoFont = text.trim();
                                            }
                                        }
                                    }
                                }

                                StyledRect {
                                    variant: "common"
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    TextInput {
                                        id: monoFontSizeInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        font.family: Config.theme.monoFont
                                        font.pixelSize: Styling.monoFontSize(0)
                                        color: Colors.overBackground
                                        selectByMouse: true
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator {
                                            bottom: 8
                                            top: 32
                                        }

                                        readonly property int configValue: Config.theme.monoFontSize

                                        onConfigValueChanged: {
                                            if (text !== configValue.toString()) {
                                                text = configValue.toString();
                                            }
                                        }

                                        Component.onCompleted: text = configValue.toString()

                                        onEditingFinished: {
                                            let newSize = parseInt(text);
                                            if (!isNaN(newSize) && newSize >= 8 && newSize <= 32 && newSize !== Config.theme.monoFontSize) {
                                                GlobalStates.markThemeChanged();
                                                Config.theme.monoFontSize = newSize;
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: "px"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overSurfaceVariant
                                }
                            }

                            Separator {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Roundness"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledSlider {
                                    id: roundnessSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round(value * 20)}`
                                    scroll: true
                                    stepSize: 0.05  // 1/20 = 0.05 for integer steps in 0-20 range
                                    snapMode: "always"

                                    // Use a computed property that always reads from Config
                                    readonly property real configValue: Config.theme.roundness / 20

                                    // Sync value when configValue changes (e.g., after discard)
                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newRoundness = Math.round(value * 20);
                                        if (newRoundness !== Config.theme.roundness) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.roundness = newRoundness;
                                        }
                                    }
                                }

                                Text {
                                    text: Math.round(roundnessSlider.value * 20)
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 24
                                }
                            }
                        }
                    }

                    // Shadow section
                    Item {
                        visible: root.currentSection === "shadow"
                        Layout.fillWidth: true
                        Layout.preferredHeight: shadowContent.implicitHeight

                        ColumnLayout {
                            id: shadowContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 8

                            Text {
                                text: "Shadow"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            // Opacity row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Opacity"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: shadowOpacitySlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round(value * 100)}%`
                                    scroll: true
                                    stepSize: 0.01
                                    snapMode: "always"

                                    readonly property real configValue: Config.theme.shadowOpacity

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        if (Math.abs(value - Config.theme.shadowOpacity) > 0.001) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.shadowOpacity = value;
                                        }
                                    }
                                }

                                Text {
                                    text: Math.round(shadowOpacitySlider.value * 100) + "%"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 40
                                }
                            }

                            // Blur row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Blur"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: shadowBlurSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${(value * 4).toFixed(1)}`
                                    scroll: true
                                    stepSize: 0.01
                                    snapMode: "always"

                                    readonly property real configValue: Config.theme.shadowBlur / 4

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newBlur = value * 4;
                                        if (Math.abs(newBlur - Config.theme.shadowBlur) > 0.01) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.shadowBlur = newBlur;
                                        }
                                    }
                                }

                                Text {
                                    text: Config.theme.shadowBlur.toFixed(1)
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 40
                                }
                            }

                            // Offset row (X and Y)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Offset X"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: shadowXOffsetSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round((value - 0.5) * 40)}`
                                    scroll: true
                                    stepSize: 0.025  // 1/40 for integer steps in -20 to +20 range
                                    snapMode: "always"

                                    readonly property real configValue: (Config.theme.shadowXOffset + 20) / 40

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newOffset = Math.round((value - 0.5) * 40);
                                        if (newOffset !== Config.theme.shadowXOffset) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.shadowXOffset = newOffset;
                                        }
                                    }
                                }

                                Text {
                                    text: Config.theme.shadowXOffset
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 40
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Offset Y"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledSlider {
                                    id: shadowYOffsetSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    progressColor: Styling.srItem("overprimary")
                                    tooltipText: `${Math.round((value - 0.5) * 40)}`
                                    scroll: true
                                    stepSize: 0.025  // 1/40 for integer steps in -20 to +20 range
                                    snapMode: "always"

                                    readonly property real configValue: (Config.theme.shadowYOffset + 20) / 40

                                    onConfigValueChanged: {
                                        if (Math.abs(value - configValue) > 0.001) {
                                            value = configValue;
                                        }
                                    }

                                    Component.onCompleted: value = configValue

                                    onValueChanged: {
                                        let newOffset = Math.round((value - 0.5) * 40);
                                        if (newOffset !== Config.theme.shadowYOffset) {
                                            GlobalStates.markThemeChanged();
                                            Config.theme.shadowYOffset = newOffset;
                                        }
                                    }
                                }

                                Text {
                                    text: Config.theme.shadowYOffset
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignRight
                                    Layout.preferredWidth: 40
                                }
                            }

                            // Color row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Color"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    Layout.preferredWidth: 80
                                }

                                StyledRect {
                                    id: shadowColorButton
                                    variant: "common"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: Styling.radius(-2)

                                    property bool isHovered: false

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            radius: 4
                                            color: Config.resolveColor(Config.theme.shadowColor)
                                            border.width: 1
                                            border.color: Colors.outline
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: Config.theme.shadowColor
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            color: shadowColorButton.item
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Styling.srItem("overprimary")
                                        radius: shadowColorButton.radius ?? 0
                                        opacity: shadowColorButton.isHovered ? 0.15 : 0

                                        Behavior on opacity {
                                            enabled: (Config.animDuration ?? 0) > 0
                                            NumberAnimation {
                                                duration: (Config.animDuration ?? 0) / 2
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: shadowColorButton.isHovered = true
                                        onExited: shadowColorButton.isHovered = false

                                        onClicked: {
                                            root.openColorPicker(Colors.availableColorNames, Config.theme.shadowColor, "Select Shadow Color", function (color) {
                                                GlobalStates.markThemeChanged();
                                                Config.theme.shadowColor = color;
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Variant selector section
                    Item {
                        id: variantSelectorPane
                        visible: root.currentSection === "colors"
                        property string settingsSection: "colors"
                        Layout.fillWidth: true
                        Layout.preferredHeight: variantSelectorContent.implicitHeight

                        property bool variantExpanded: false

                        Behavior on Layout.preferredHeight {
                            enabled: (Config.animDuration ?? 0) > 0
                            NumberAnimation {
                                duration: (Config.animDuration ?? 0) / 2
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            id: variantSelectorContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 8

                            Text {
                                text: "Variant"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Layout.alignment: Qt.AlignTop

                                // Collapsed mode: horizontal scrollable row with scrollbar
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    visible: !variantSelectorPane.variantExpanded

                                    Flickable {
                                        id: variantFlickable
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        contentWidth: variantRow.width
                                        flickableDirection: Flickable.HorizontalFlick
                                        clip: true
                                        boundsBehavior: Flickable.StopAtBounds

                                        Row {
                                            id: variantRow
                                            spacing: 4

                                            Repeater {
                                                model: root.allVariants

                                                delegate: StyledRect {
                                                    id: variantTagRow
                                                    required property var modelData
                                                    required property int index

                                                    property bool isSelected: root.selectedVariant === modelData.id
                                                    property bool isHovered: false

                                                    variant: modelData.id
                                                    enableShadow: true

                                                    width: tagContentRow.width + 24 + (isSelected ? checkIconRow.width + 4 : 0)
                                                    height: 32
                                                    radius: isSelected ? Styling.radius(0) / 2 : Styling.radius(0)

                                                    Behavior on width {
                                                        enabled: (Config.animDuration ?? 0) > 0
                                                        NumberAnimation {
                                                            duration: (Config.animDuration ?? 0) / 3
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }

                                                    Item {
                                                        anchors.fill: parent
                                                        anchors.margins: 8

                                                        Row {
                                                            anchors.centerIn: parent
                                                            spacing: variantTagRow.isSelected ? 4 : 0

                                                            Item {
                                                                width: checkIconRow.visible ? checkIconRow.width : 0
                                                                height: checkIconRow.height
                                                                clip: true

                                                                Text {
                                                                    id: checkIconRow
                                                                    text: Icons.accept
                                                                    font.family: Icons.font
                                                                    font.pixelSize: 16
                                                                    color: variantTagRow.item
                                                                    visible: variantTagRow.isSelected
                                                                    opacity: variantTagRow.isSelected ? 1 : 0

                                                                    Behavior on opacity {
                                                                        enabled: (Config.animDuration ?? 0) > 0
                                                                        NumberAnimation {
                                                                            duration: (Config.animDuration ?? 0) / 3
                                                                            easing.type: Easing.OutCubic
                                                                        }
                                                                    }
                                                                }

                                                                Behavior on width {
                                                                    enabled: (Config.animDuration ?? 0) > 0
                                                                    NumberAnimation {
                                                                        duration: (Config.animDuration ?? 0) / 3
                                                                        easing.type: Easing.OutCubic
                                                                    }
                                                                }
                                                            }

                                                            Text {
                                                                id: tagContentRow
                                                                text: variantTagRow.modelData.label
                                                                font.family: Config.theme.font
                                                                font.pixelSize: Config.theme.fontSize
                                                                font.bold: true
                                                                color: variantTagRow.item

                                                                Behavior on color {
                                                                    enabled: (Config.animDuration ?? 0) > 0
                                                                    ColorAnimation {
                                                                        duration: (Config.animDuration ?? 0) / 3
                                                                        easing.type: Easing.OutCubic
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        color: Styling.srItem("overprimary")
                                                        radius: variantTagRow.radius ?? 0
                                                        opacity: variantTagRow.isHovered ? 0.15 : 0

                                                        Behavior on opacity {
                                                            enabled: (Config.animDuration ?? 0) > 0
                                                            NumberAnimation {
                                                                duration: (Config.animDuration ?? 0) / 2
                                                            }
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor

                                                        onEntered: variantTagRow.isHovered = true
                                                        onExited: variantTagRow.isHovered = false

                                                        onClicked: root.selectedVariant = variantTagRow.modelData.id
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ScrollBar {
                                        id: variantScrollBar
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 8
                                        orientation: Qt.Horizontal

                                        position: variantFlickable.contentWidth > 0 ? variantFlickable.contentX / variantFlickable.contentWidth : 0
                                        size: variantFlickable.contentWidth > 0 ? variantFlickable.width / variantFlickable.contentWidth : 1

                                        property bool scrollBarPressed: false

                                        background: Rectangle {
                                            implicitHeight: 8
                                            color: Colors.surface
                                            radius: 4
                                        }

                                        contentItem: Rectangle {
                                            implicitHeight: 8
                                            color: Styling.srItem("overprimary")
                                            radius: 4
                                        }

                                        onPressedChanged: {
                                            scrollBarPressed = pressed;
                                        }

                                        onPositionChanged: {
                                            if (scrollBarPressed && variantFlickable.contentWidth > variantFlickable.width) {
                                                variantFlickable.contentX = position * variantFlickable.contentWidth;
                                            }
                                        }
                                    }
                                }

                                // Expanded mode: Flow grid
                                Flow {
                                    id: variantsFlow
                                    Layout.fillWidth: true
                                    spacing: 4
                                    visible: variantSelectorPane.variantExpanded

                                    Repeater {
                                        model: root.allVariants

                                        delegate: StyledRect {
                                            id: variantTag
                                            required property var modelData
                                            required property int index

                                            property bool isSelected: root.selectedVariant === modelData.id
                                            property bool isHovered: false

                                            variant: modelData.id
                                            enableShadow: true

                                            width: tagContent.width + 24 + (isSelected ? checkIcon.width + 4 : 0)
                                            height: 32
                                            radius: isSelected ? Styling.radius(0) / 2 : Styling.radius(0)

                                            Behavior on width {
                                                enabled: (Config.animDuration ?? 0) > 0
                                                NumberAnimation {
                                                    duration: (Config.animDuration ?? 0) / 3
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Item {
                                                anchors.fill: parent
                                                anchors.margins: 8

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: variantTag.isSelected ? 4 : 0

                                                    Item {
                                                        width: checkIcon.visible ? checkIcon.width : 0
                                                        height: checkIcon.height
                                                        clip: true

                                                        Text {
                                                            id: checkIcon
                                                            text: Icons.accept
                                                            font.family: Icons.font
                                                            font.pixelSize: 16
                                                            color: variantTag.item
                                                            visible: variantTag.isSelected
                                                            opacity: variantTag.isSelected ? 1 : 0

                                                            Behavior on opacity {
                                                                enabled: (Config.animDuration ?? 0) > 0
                                                                NumberAnimation {
                                                                    duration: (Config.animDuration ?? 0) / 3
                                                                    easing.type: Easing.OutCubic
                                                                }
                                                            }
                                                        }

                                                        Behavior on width {
                                                            enabled: (Config.animDuration ?? 0) > 0
                                                            NumberAnimation {
                                                                duration: (Config.animDuration ?? 0) / 3
                                                                easing.type: Easing.OutCubic
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        id: tagContent
                                                        text: variantTag.modelData.label
                                                        font.family: Config.theme.font
                                                        font.pixelSize: Config.theme.fontSize
                                                        font.bold: true
                                                        color: variantTag.item

                                                        Behavior on color {
                                                            enabled: (Config.animDuration ?? 0) > 0
                                                            ColorAnimation {
                                                                duration: (Config.animDuration ?? 0) / 3
                                                                easing.type: Easing.OutCubic
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: hoverOverlay
                                                anchors.fill: parent
                                                color: Styling.srItem("overprimary")
                                                radius: variantTag.radius ?? 0
                                                opacity: variantTag.isHovered ? 0.15 : 0

                                                Behavior on opacity {
                                                    enabled: (Config.animDuration ?? 0) > 0
                                                    NumberAnimation {
                                                        duration: (Config.animDuration ?? 0) / 2
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onEntered: variantTag.isHovered = true
                                                onExited: variantTag.isHovered = false

                                                onClicked: root.selectedVariant = variantTag.modelData.id
                                            }
                                        }
                                    }
                                }

                                // Toggle expand/collapse button
                                StyledRect {
                                    id: expandToggleButton
                                    variant: isHovered ? "focus" : "common"
                                    width: 32
                                    height: 32
                                    radius: Styling.radius(-2)
                                    Layout.alignment: Qt.AlignTop
                                    enableShadow: true

                                    property bool isHovered: false

                                    Text {
                                        anchors.centerIn: parent
                                        text: variantSelectorPane.variantExpanded ? Icons.caretUp : Icons.caretDown
                                        font.family: Icons.font
                                        font.pixelSize: 16
                                        color: expandToggleButton.item
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: expandToggleButton.isHovered = true
                                        onExited: expandToggleButton.isHovered = false

                                        onClicked: variantSelectorPane.variantExpanded = !variantSelectorPane.variantExpanded
                                    }
                                }
                            }
                        }
                    }

                    // Editor section
                    Item {
                        visible: root.currentSection === "colors"
                        property string settingsSection: "colors"
                        Layout.fillWidth: true
                        Layout.preferredHeight: editorContent.implicitHeight

                        ColumnLayout {
                            id: editorContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 8

                            Text {
                                text: "Editor - " + root.getVariantLabel(root.selectedVariant)
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                                Layout.bottomMargin: -4
                            }

                            VariantEditor {
                                Layout.fillWidth: true
                                variantId: root.selectedVariant
                                onClose: {}
                                onOpenColorPickerRequested: (colorNames, currentColor, dialogTitle, callback) => {
                                    root.openColorPicker(colorNames, currentColor, dialogTitle, callback);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Color picker view (shown when colorPickerActive)
    Item {
        id: colorPickerContainer
        anchors.fill: parent
        clip: true

        // Horizontal slide + fade animation (enters from right)
        opacity: root.colorPickerActive ? 1 : 0
        transform: Translate {
            id: pickerTranslate
            x: root.colorPickerActive ? 0 : 30

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        // Prevent interaction when hidden
        enabled: root.colorPickerActive

        // Block interaction with elements behind when active
        MouseArea {
            anchors.fill: parent
            enabled: root.colorPickerActive
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            // Consume all mouse events to prevent pass-through
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onWheel: event => event.accepted = true
        }

        ColorPickerView {
            id: colorPickerContent
            anchors.fill: parent
            anchors.leftMargin: root.sideMargin
            anchors.rightMargin: root.sideMargin
            colorNames: root.colorPickerColorNames
            currentColor: root.colorPickerCurrentColor
            dialogTitle: root.colorPickerDialogTitle

            onColorSelected: color => root.handleColorSelected(color)
            onClosed: root.closeColorPicker()
        }
    }

    // Directory picker dialog for wallpaper path
    FolderDialog {
        id: themeWallDirDialog
        title: "Select Wallpaper Directory"
        currentFolder: wallpaperConfig.adapter.wallPath ? "file://" + wallpaperConfig.adapter.wallPath : ""
        onAccepted: {
            var path = selectedFolder.toString().replace("file://", "");
            if (wallpaperConfig.adapter.wallPath !== path) {
                wallpaperConfig.adapter.wallPath = path;
                wallpaperConfig.writeAdapter();
            }
        }
    }
}
