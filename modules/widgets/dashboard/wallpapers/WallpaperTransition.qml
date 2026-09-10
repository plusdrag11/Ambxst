pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.theme
import qs.config

Item {
    id: root

    property string source
    property bool tintEnabled: false
    property real targetWidth: width
    property real targetHeight: height

    // "none" | type | type-suffix | comma-separated list | "random"
    property string transitionType: "random"
    property int transitionDuration: 1000
    property int waveCount: 3
    property int stripeCount: 0
    property int honeycombSize: 1
    property color fillColor: "#000000"
    property string transitionEasing: "inOutCubic"
    property string transitionInterrupt: "freeze"
    property string transitionInterruptReplay: "same"
    // One-shot override consumed on the next source change (set via IPC)
    property string transitionOverride: ""

    property Item current: one
    property bool completed: false
    // True once at least one source has been displayed in `current`; until then
    // source changes plain-load instead of running a transition (covers the
    // loader instantiating us before the source binding has settled).
    property bool settled: false

    // Transition state
    property bool transitioning: false
    property bool redirecting: false
    property bool redirectPending: false
    property bool reversed: false
    property real transitionProgress: 0
    property bool _startPending: false
    property bool _fromReady: false
    property Item _pendingFrom: null
    property Item outgoingSlot
    property Item incomingSlot
    property Item activeFrom: bufA
    readonly property Item inactiveFrom: activeFrom === bufA ? bufB : bufA
    property string activeTransitionType: ""
    property string queuedReplayType: ""
    property point transitionCentre: Qt.point(0.5, 0.5)
    property vector4d transitionParams: Qt.vector4d(0, 0, 0, 0)

    readonly property bool hasTransition: transitionType !== "none" && transitionType.length > 0 && transitionDuration > 0 && Config.animDuration > 0

    readonly property list<string> transitionTypes: ["fade", "wipe", "grow", "outer", "wave", "diagonal", "stripes", "zoom", "honeycomb", "iris", "pixelate"]

    readonly property var optimizedPalette: ["background", "overBackground", "shadow", "surface", "surfaceBright", "surfaceDim", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceContainerLow", "surfaceContainerLowest", "primary", "secondary", "tertiary", "red", "lightRed", "green", "lightGreen", "blue", "lightBlue", "yellow", "lightYellow", "cyan", "lightCyan", "magenta", "lightMagenta"]

    // Every shader shares one uniform layout, so a single ShaderEffect drives them all
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

    // Direction variants use a suffix, e.g. wipe-left, grow-top, diagonal-tl;
    // a bare directional name means "random" per switch
    function baseOf(type: string): string {
        const i = type.indexOf("-");
        if (i < 0)
            return type;
        const b = type.slice(0, i);
        return ["wipe", "grow", "outer", "diagonal", "stripes", "wave"].includes(b) ? b : type;
    }

    function shaderFor(type: string): url {
        return Qt.resolvedUrl(shaderMap[baseOf(type)] ?? shaderMap["fade"]);
    }

    function resolveTransitionType(): string {
        const raw = transitionOverride !== "" ? transitionOverride : transitionType;
        if (raw === "none" || raw === "")
            return "none";
        if (raw === "random")
            return transitionTypes[Math.floor(Math.random() * transitionTypes.length)];
        const types = raw.split(",").map(t => t.trim());
        if (types.length === 1)
            return types[0];
        return types[Math.floor(Math.random() * types.length)];
    }

    function randomizeParams(type: string): void {
        const base = baseOf(type);
        const suffix = type.length > base.length ? type.slice(base.length + 1) : "";
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
            const dirs = {
                "left": 0,
                "right": 1,
                "top": 2,
                "bottom": 3
            };
            params.x = suffix in dirs ? dirs[suffix] : Math.floor(Math.random() * 4);
            params.y = 0.1;
            break;
        }
        case "grow":
            centre = edgeCentre[suffix] ?? randomCentre();
            params.y = 0.1;
            break;
        case "outer":
            params.x = 1;
            params.y = 0.1;
            centre = edgeCentre[suffix] ?? randomCentre();
            break;
        case "wave": {
            const angles = {
                "left": 0,
                "right": Math.PI,
                "top": Math.PI / 2,
                "bottom": Math.PI * 1.5,
                "tl": Math.PI / 4,
                "tr": Math.PI * 0.75,
                "br": Math.PI * 1.25,
                "bl": Math.PI * 1.75
            };
            const keys = Object.keys(angles);
            const angle = suffix in angles ? angles[suffix] : angles[keys[Math.floor(Math.random() * keys.length)]];
            const waves = waveCount > 0 ? Math.min(8, waveCount) : 1 + Math.floor(Math.random() * 8);
            params = Qt.vector4d(0.16 / waves, 1 / waves, 0, angle);
            break;
        }
        case "diagonal": {
            const corners = {
                "tl": 0,
                "tr": 1,
                "bl": 2,
                "br": 3
            };
            params.x = suffix in corners ? corners[suffix] : Math.floor(Math.random() * 4);
            break;
        }
        case "stripes": {
            const angles = {
                "top": 0,
                "bottom": Math.PI,
                "left": Math.PI / 2,
                "right": Math.PI * 1.5
            };
            const angle = suffix in angles ? angles[suffix] : Math.random() * 2 * Math.PI;
            const count = stripeCount > 0 ? Math.max(2, Math.min(24, stripeCount)) : Math.round(Math.random() * 20 + 4);
            params = Qt.vector4d(count, angle, 0.1, 0);
            break;
        }
        case "honeycomb": {
            centre = randomCentre();
            const bands = [[0.012, 0.03], [0.02, 0.06], [0.05, 0.12], [0.1, 0.2]];
            const band = bands[Math.max(0, Math.min(3, honeycombSize))];
            params.x = band[0] + Math.random() * (band[1] - band[0]);
            break;
        }
        case "iris":
            centre = Qt.point(0.5, 0.5);
            params.x = 0.1;
            break;
        case "pixelate":
            params = Qt.vector4d(0.1, 0, root.width, root.height);
            break;
        }

        transitionCentre = centre;
        transitionParams = params;
    }

    function runAnim(from: real, to: real): void {
        if (transitionAnim.running) {
            redirecting = true;
            transitionAnim.stop();
            redirecting = false;
        }
        transitionAnim.from = from;
        transitionAnim.to = to;
        transitionAnim.duration = transitionDuration * Math.abs(to - from);
        transitionAnim.start();
    }

    function startTransition(outgoing: Item, incoming: Item, type: string, fromItem: Item): void {
        outgoingSlot = outgoing;
        incomingSlot = incoming;
        activeTransitionType = type;
        randomizeParams(type);
        reversed = false;
        _startPending = true;
        _fromReady = fromItem !== null;
        transitionProgress = 0;
        incomingSlot.update();

        if (fromItem) {
            activeFrom = fromItem;
            _pendingFrom = null;
        } else {
            const buf = inactiveFrom;
            buf.sourceItem = outgoing;
            buf.sourceRect = Qt.rect(0, 0, outgoing?.width ?? 0, outgoing?.height ?? 0);
            buf.scheduleUpdate();
            _pendingFrom = buf;
        }

        _tryStartTransition();
    }

    function _tryStartTransition(): void {
        // Keep the plain outgoing wallpaper on screen until BOTH the frozen
        // outgoing grab has completed and the incoming image is decoded.
        // Raising the overlay earlier makes the composite sample an invalid
        // live:false buffer, rendering black/stale "frozen" first frames.
        if (!_startPending || !_fromReady || !incomingSlot?.slotReady)
            return;
        _startPending = false;
        _fromReady = false;
        if (_pendingFrom)
            activeFrom = _pendingFrom;
        _pendingFrom = null;
        transitioning = true;
        runAnim(0, 1);
    }

    function finishTransition(): void {
        cancelRedirect();
        _startPending = false;
        _fromReady = false;
        _pendingFrom = null;
        settled = true;
        if (reversed && outgoingSlot) {
            current = outgoingSlot;
            if (incomingSlot)
                incomingSlot.path = "";
        } else if (incomingSlot) {
            current = incomingSlot;
            if (outgoingSlot)
                outgoingSlot.path = "";
        }
        queuedReplayType = source && source !== current.path && transitionInterruptReplay !== "new" ? activeTransitionType : "";
        transitioning = false;
        transitionProgress = 0;
        reversed = false;
        outgoingSlot = null;
        incomingSlot = null;
        activeTransitionType = "";
        bufA.sourceItem = null;
        bufB.sourceItem = null;

        if (source && source !== current.path)
            Qt.callLater(() => applySourceChange());
    }

    function cancelRedirect(): void {
        redirectPending = false;
        redirectTimer.stop();
    }

    function finalizeRedirect(): void {
        cancelRedirect();

        if (!transitioning) {
            applySourceChange();
            return;
        }

        const savedOutgoing = outgoingSlot;
        const savedType = transitionInterruptReplay === "new" ? resolveTransitionType() : activeTransitionType;
        redirecting = true;
        transitionAnim.stop();
        redirecting = false;

        const frozen = inactiveFrom;
        startTransition(savedOutgoing, savedOutgoing === one ? two : one, savedType, frozen);
    }

    function applySourceChange(): void {
        if (!hasTransition || !completed || !settled || !current.path) {
            if (current === one)
                two.update();
            else
                one.update();
            return;
        }

        if (!transitioning) {
            if (source && source !== current.path) {
                const type = queuedReplayType !== "" ? queuedReplayType : resolveTransitionType();
                queuedReplayType = "";
                startTransition(current, current === one ? two : one, type, null);
            }
            return;
        }

        if (!incomingSlot || !outgoingSlot)
            return;

        if (!source) {
            redirecting = true;
            transitionAnim.stop();
            redirecting = false;
            finishTransition();
        } else if (source === outgoingSlot.path) {
            // Switching back to the outgoing wallpaper: play the transition backwards
            reversed = true;
            runAnim(transitionProgress, 0);
        } else if (source === incomingSlot.path) {
            cancelRedirect();
            if (reversed) {
                reversed = false;
                runAnim(transitionProgress, 1);
            }
        } else if (transitionInterrupt === "reverse") {
            // A third wallpaper: play the transition backwards, then finishTransition
            // kicks off a fresh transition to the latest source
            cancelRedirect();
            reversed = true;
            runAnim(transitionProgress, 0);
        } else if (!redirectPending) {
            // A third wallpaper: freeze the current composite into the inactive
            // buffer, then restart the transition from it once the grab completes
            redirectPending = true;
            if (transitionAnim.running)
                transitionAnim.pause();
            const buf = inactiveFrom;
            buf.sourceItem = compositeEffect;
            buf.sourceRect = Qt.rect(0, 0, root.width, root.height);
            buf.scheduleUpdate();
            redirectTimer.restart();
        }
    }

    onSourceChanged: applySourceChange()

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
        else
            completed = true;
    }

    // Shared palette texture for the tint shader (identical for both slots)
    Item {
        id: paletteSourceItem
        visible: true
        width: root.optimizedPalette.length
        height: 1
        opacity: 0

        Row {
            anchors.fill: parent
            Repeater {
                model: root.optimizedPalette
                Rectangle {
                    required property string modelData
                    width: 1
                    height: 1
                    color: Colors[modelData]
                }
            }
        }
    }

    ShaderEffectSource {
        id: paletteTextureSource
        sourceItem: paletteSourceItem
        hideSource: true
        visible: false
        smooth: false
        recursive: false
    }

    Slot {
        id: one
    }

    Slot {
        id: two
    }

    // Transition overlay
    Item {
        anchors.fill: parent
        // Stay in the render tree while a grab is scheduled for a pending start;
        // only the composite shader is shown once the transition actually begins.
        visible: root.transitioning || root._startPending || root.redirectPending
        z: 10

        // Frozen texture of the outgoing wallpaper (or interrupt composite); two
        // buffers so a redirect can grab the composite without a feedback loop
        component FromBuffer: ShaderEffectSource {
            id: buf

            anchors.fill: parent
            live: false
            // A ShaderEffectSource only produces its frozen texture while it is
            // actually rendered, so during a pending start the buffer holding the
            // scheduled grab of the outgoing wallpaper must be visible: it shows
            // the same pixels as the plain outgoing slot until the grab lands.
            visible: {
                if (root.transitioning || root.redirectPending)
                    return false;
                return root._startPending && root._pendingFrom === buf;
            }

            onScheduledUpdateCompleted: {
                if (root.redirectPending && root.inactiveFrom === buf)
                    root.finalizeRedirect();
                if (root._startPending && root._pendingFrom === buf) {
                    root._fromReady = true;
                    root._tryStartTransition();
                }
            }
        }

        FromBuffer { id: bufA }
        FromBuffer { id: bufB }

        // Live texture of the incoming wallpaper
        ShaderEffectSource {
            id: toSource

            anchors.fill: parent
            sourceItem: root.incomingSlot
            live: true
            visible: false
        }

        ShaderEffect {
            id: compositeEffect

            readonly property variant fromTex: root.activeFrom
            readonly property variant toTex: toSource
            readonly property real progress: root.transitionProgress
            readonly property real aspectRatio: height > 0 ? width / height : 1
            readonly property point centre: root.transitionCentre
            readonly property vector4d params: root.transitionParams
            readonly property vector4d fillColor: Qt.vector4d(root.fillColor.r, root.fillColor.g, root.fillColor.b, root.fillColor.a)

            anchors.fill: parent
            visible: root.transitioning
            blending: false
            fragmentShader: root.shaderFor(root.activeTransitionType)
        }

        NumberAnimation {
            id: transitionAnim

            target: root
            property: "transitionProgress"
            easing.type: {
                switch (root.transitionEasing) {
                case "outCubic": return Easing.OutCubic;
                case "outExpo": return Easing.OutExpo;
                case "linear": return Easing.Linear;
                case "inCubic": return Easing.InCubic;
                default: return Easing.InOutCubic;
                }
            }

            onRunningChanged: {
                if (!running && root.transitioning && !root.redirecting)
                    root.finishTransition();
            }
        }

        // Fallback in case a scheduled grab never completes
        Timer {
            id: redirectTimer

            interval: 250

            onTriggered: {
                if (root.redirectPending)
                    root.finalizeRedirect();
            }
        }
    }

    component Slot: Item {
        id: slot

        property string path
        property bool slotReady: false
        readonly property bool imageReady: img.status === Image.Ready

        function update(): void {
            if (path === root.source) {
                slotReady = imageReady;
                if (slotReady && !root.transitioning)
                    root.current = slot;
            } else {
                slotReady = false;
                path = root.source;
                if (imageReady)
                    slotReady = true;
            }
        }

        anchors.fill: parent
        z: root.current === slot ? 1 : 0

        opacity: {
            if (root.transitioning) {
                if (root.incomingSlot === slot || root.outgoingSlot === slot)
                    return 1;
            }
            return root.current === slot ? 1 : 0;
        }

        onPathChanged: slotReady = false

        onImageReadyChanged: {
            if (imageReady && path === root.source) {
                slotReady = true;
                if (!root.hasTransition || !root.settled) {
                    root.current = slot;
                    root.settled = true;
                } else if (root._startPending) {
                    root._tryStartTransition();
                } else if (root.transitioning && root.incomingSlot === slot && !transitionAnim.running) {
                    root.runAnim(0, 1);
                }
            }
        }

        Image {
            id: img
            mipmap: true
            anchors.fill: parent
            source: slot.path ? "file://" + slot.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            sourceSize.width: root.targetWidth
            sourceSize.height: root.targetHeight
            layer.enabled: root.tintEnabled
            layer.effect: ShaderEffect {
                property var paletteTexture: paletteTextureSource
                property real paletteSize: root.optimizedPalette.length
                property real texWidth: img.width
                property real texHeight: img.height

                vertexShader: "palette.vert.qsb"
                fragmentShader: "palette.frag.qsb"
            }
        }
    }
}
