import { RTCCaller } from './caller'

let channel, localVideoEl, btnBroadcast, localStream, socket, caller

let servers = {
    "iceServers": [
        { url: "stun:stun.l.google.com:19302" }
    ]
}

let anchor = {
    init(sock, element) {
        if (!element) {
            return
        } else {
            socket = sock
            anchor.init_ui()
        }
    },
    init_ui() {
        btnBroadcast = document.getElementById("broadcast")
        btnBroadcast.onclick = anchor.connect

        localVideoEl = document.getElementById("localVideo")
    },
    connect() {
        let user = { user: "anchor" }
        socket.connect(user)
        channel = socket.channel("room")
        channel.on("new_audience", payload => {
            anchor.onNewAudience(payload)
        })
        channel.on("old_audiences", payload => {
            anchor.onOldAudience(payload)
        })
        channel.on("audience_sdp", payload => {
            anchor.onAudienceDescription(JSON.parse(payload.body))
        })
        channel.join()
            .receive("ok", () => {
                console.log("Successfully joined channel")
                // Initiates camera
                navigator.getUserMedia = (navigator.getUserMedia
                    || navigator.webkitGetUserMedia || navigator.mozGetUserMedia
                    || navigator.msGetUserMedia || navigator.oGetUserMedia)
                navigator.getUserMedia({ video: true }, anchor.onSucceed, anchor.onError)
                btnBroadcast.disabled = true
            })
            .receive("error", () => { console.log("Unable to join") })
    },
    onSucceed(stream) {
        localVideoEl.srcObject = stream
        localStream = stream
    },
    onError(error) {
        console.log(">>> ERROR: ", error)
    },
    onNewAudience(callee) {
        console.log(">>> NEW AUDIENCE: ", callee)
        caller = new RTCCaller(callee.user, channel, servers, localStream)
        caller.initiate()
    },
    onOldAudience(payload) {
        console.log(">>> OLD AUDIENCE: ", payload)
    },
    onAudienceDescription(desc) {
        console.log("AUDIENCE DESC: ", desc);
        caller.onRemoteDescription(desc)
    }
}
export default anchor