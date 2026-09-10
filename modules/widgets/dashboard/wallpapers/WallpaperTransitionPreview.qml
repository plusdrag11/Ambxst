pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.theme
import qs.config

Item {
    id: root

    property string type: "fade"
    property string wallpaperPath: ""
    property bool playing: false
    property bool loop: true
    property real restProgress: 0.4
    property Item fromItem: wallSource
    property Item toItem: gradientB
    property real progress: restProgress
    property point effCentre: Qt.point(0.5, 0.5)
    property vector4d effParams: Qt.vector4d(0, 0, 0, 0)
    property int waveCount: 3
    property int stripeCount: 0
    property int honeycombSize: 1
    property string transitionEasing: "inOutCubic"

    readonly property var transitionTypes: ["fade", "wipe", "grow", "outer", "wave", "diagonal", "stripes", "zoom", "honeycomb", "iris", "pixelate"]
    readonly property bool isRandom: type === "random"
    property string activeType: isRandom ? transitionTypes[Math.floor(Math.random() * transitionTypes.length)] : type

    readonly property var shaderMap: ({
            "fade": "transitions/wp_fade.frag.qsb",
            "wipe": "transitions/wp_wipe.frag.qsb",
            "grow": "transitions/wp_disc.frag.qsb",
            "outer": "transitions/wp_disc.frag.qsb",
            "wave": "transitions/wp_wave.frag.qsb",
            "diagonal": "transitions/wp_diagonal.frag.qsb",
            "stripes": "transitions/wp_stripes.frag.qsb",
            "zoom": "transitions/wp_zoom.frag.qsb",
            "honeycomb": "transitions/wp_honeycomb.frag.qsb",
            "iris": "transitions/wp_iris.frag.qsb",
            "pixelate": "transitions/wp_pixelate.frag.qsb"
        })

    signal finished

    function pickRandomType(): void {
        activeType = transitionTypes[Math.floor(Math.random() * transitionTypes.length)];
    }

    function baseOf(t: string): string {
        const i = t.indexOf("-");
        if (i < 0)
            return t;
        const b = t.slice(0, i);
        return ["wipe", "grow", "outer", "diagonal", "stripes", "wave"].includes(b) ? b : t;
    }

    function roll(): void {
        const active = activeType;
        const base = baseOf(active);
        const suffix = active.length > base.length ? active.slice(base.length + 1) : "";
        const edgeCentre = {
            "left": Qt.point(0, 0.5),
            "right": Qt.point(1, 0.5),
            "top": Qt.point(0.5, 0),
            "bottom": Qt.point(0.5, 1)
        };
        const randomCentre = () => Qt.point(Math.random(), Math.random());

        let centre = Qt.point(0.5, 0.5);
        let params = Qt.vector4d(0, 0, 0, 0);

        switch (base) {
        case "wipe": {
            const dirs = { "left": 0, "right": 1, "top": 2, "bottom": 3 };
            params = Qt.vector4d(dirs[suffix] ?? Math.floor(Math.random() * 4), 0.1, 0, 0);
            break;
        }
        case "grow":
            centre = edgeCentre[suffix] ?? randomCentre();
            params = Qt.vector4d(0, 0.1, 0, 0);
            break;
        case "outer":
            centre = edgeCentre[suffix] ?? randomCentre();
            params = Qt.vector4d(1, 0.1, 0, 0);
            break;
        case "wave": {
            const angles = {
                "left": 0, "right": Math.PI, "top": Math.PI / 2,
                "bottom": Math.PI * 1.5, "tl": Math.PI / 4,
                "tr": Math.PI * 0.75, "br": Math.PI * 1.25, "bl": Math.PI * 1.75
            };
            const keys = Object.keys(angles);
            const angle = angles[suffix] ?? angles[keys[Math.floor(Math.random() * keys.length)]];
            const waves = root.waveCount > 0 ? Math.min(8, root.waveCount) : 1 + Math.floor(Math.random() * 8);
            params = Qt.vector4d(0.16 / waves, 1 / waves, 0, angle);
            break;
        }
        case "diagonal": {
            const corners = { "tl": 0, "tr": 1, "bl": 2, "br": 3 };
            params = Qt.vector4d(corners[suffix] ?? Math.floor(Math.random() * 4), 0, 0, 0);
            break;
        }
        case "stripes": {
            const angles = { "top": 0, "bottom": Math.PI, "left": Math.PI / 2, "right": Math.PI * 1.5 };
            const angle = angles[suffix] ?? Math.random() * 2 * Math.PI;
            const count = root.stripeCount > 0 ? Math.max(2, Math.min(24, root.stripeCount)) : Math.round(Math.random() * 20 + 4);
            params = Qt.vector4d(count, angle, 0.1, 0);
            break;
        }
        case "honeycomb": {
            centre = randomCentre();
            const bands = [[0.012, 0.03], [0.02, 0.06], [0.05, 0.12], [0.1, 0.2]];
            const band = bands[Math.max(0, Math.min(3, root.honeycombSize))];
            params = Qt.vector4d(band[0] + Math.random() * (band[1] - band[0]), 0, 0, 0);
            break;
        }
        case "iris":
            centre = Qt.point(0.5, 0.5);
            params = Qt.vector4d(0.1, 0, 0, 0);
            break;
        case "pixelate":
            params = Qt.vector4d(0.1, 0, root.width, root.height);
            break;
        default:
            centre = Qt.point(0.5, 0.5);
            params = Qt.vector4d(0, 0, 0, 0);
            break;
        }

        root.effCentre = centre;
        root.effParams = params;
    }

    onWaveCountChanged: roll()
    onStripeCountChanged: roll()
    onHoneycombSizeChanged: roll()
    Component.onCompleted: roll()
    onTypeChanged: {
        if (isRandom)
            pickRandomType();
        else
            activeType = type;
        roll();
    }
    onActiveTypeChanged: roll()

    onPlayingChanged: {
        if (!playing)
            progress = restProgress;
    }

    Image {
        id: wallSource
        anchors.fill: parent
        visible: false
        source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        mipmap: true
    }

    Rectangle {
        id: gradientB
        anchors.fill: parent
        visible: false
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Colors.tertiary }
            GradientStop { position: 1; color: Colors.surfaceContainerLow }
        }
    }

    ShaderEffectSource {
        id: fromSrc
        anchors.fill: parent
        sourceItem: root.fromItem
        visible: false
    }

    ShaderEffectSource {
        id: toSrc
        anchors.fill: parent
        sourceItem: root.toItem
        visible: false
    }

    function shaderFor(type: string): url {
        return Qt.resolvedUrl(root.shaderMap[root.baseOf(type)] ?? root.shaderMap["fade"]);
    }

    ShaderEffect {
        id: shaderEffect
        readonly property variant fromTex: fromSrc
        readonly property variant toTex: toSrc
        readonly property real progress: root.progress
        readonly property real aspectRatio: root.height > 0 ? root.width / root.height : 1
        readonly property point centre: root.effCentre
        readonly property vector4d params: root.effParams
        readonly property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)

        anchors.fill: parent
        blending: false
        fragmentShader: root.shaderFor(root.activeType)
    }

    SequentialAnimation {
        id: anim
        running: root.playing
        loops: root.loop ? Animation.Infinite : 1

        onFinished: {
            if (!root.loop)
                root.finished();
        }

        ScriptAction {
            script: {
                if (root.isRandom)
                    root.pickRandomType();
                root.roll();
                shaderEffect.fragmentShader = root.shaderFor(root.activeType);
            }
        }
        PropertyAction { target: root; property: "progress"; value: 0 }
        NumberAnimation {
            target: root
            property: "progress"
            from: 0
            to: 1
            duration: 1100
            easing.type: {
                switch (root.transitionEasing) {
                case "outCubic": return Easing.OutCubic;
                case "outExpo": return Easing.OutExpo;
                case "linear": return Easing.Linear;
                case "inCubic": return Easing.InCubic;
                default: return Easing.InOutCubic;
                }
            }
        }
        PauseAnimation { duration: 400 }
    }
}
