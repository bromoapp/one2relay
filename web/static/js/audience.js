import { RTCCallee } from './callee'
import { RTCRelayer } from './relayer'

let channel, remoteVideoEl, btnWatch, socket, caller
let localStream, relayer
let connections = []

let servers = {
    "iceServers": [
        { url: "stun:stun.l.google.com:19302" }
    ]
}

let unique = "audience_" + Math.floor((Math.random() * 100) + 1)

let audience = {
    init(sock, element) {
        if (!element) {
            return
        } else {
            socket = sock
            audience.init_ui()
        }
    },
    init_ui() {
        btnWatch = document.getElementById("watch")
        btnWatch.onclick = audience.connect

        remoteVideoEl = document.getElementById("remoteVideo")
    },
    connect() {
        let user = { user: unique }
        socket.connect(user)
        channel = socket.channel("room")
        channel.on("anchor_sdp", payload => {
            caller = payload.origin
            audience.onAnchorDescription(JSON.parse(payload.body))
        })
        channel.on("relayer_sdp", payload => {
            caller = payload.origin
            audience.onRelayerDescription(JSON.parse(payload.body))
        })
        channel.on("audience_sdp", payload => {
            caller = payload.origin
            audience.onAudienceDescription(JSON.parse(payload.body))
        })
        channel.on("candidate", payload => {
            caller = payload.origin
            audience.onRemoteCandidate(caller, JSON.parse(payload.body))
        })
        channel.on("new_audience", payload => {
            audience.onNewAudience(payload)
        })
        channel.join()
            .receive("ok", () => {
                console.log("Successfully joined channel")
                btnWatch.disabled = true
            })
            .receive("error", () => { console.log("Unable to join") })
    },
    onAnchorDescription(desc) {
        console.log(">>> ANCHOR SDP... ")
        let callee = new RTCCallee(caller, channel, servers, remoteVideoEl, audience.onRemoteStream)
        callee.initiate()
        callee.onRemoteDescription(desc)

        let connection = {
            the_caller: caller,
            the_callee: callee
        }
        connections.push(connection)
    },
    onRelayerDescription(desc) {
        console.log(">>> RELAYER SDP...")
        let callee = new RTCCallee(caller, channel, servers, remoteVideoEl, audience.onRemoteStream)
        callee.initiate()
        callee.onRemoteDescription(desc)

        let connection = {
            the_caller: caller,
            the_callee: callee
        }
        connections.push(connection)
    },
    onAudienceDescription(desc) {
        relayer.onRemoteDescription(desc)
    },
    onRemoteCandidate(caller, event) {
        console.log(">>> REMOTE CANDIDATE FROM: ", caller)
        connections.forEach(function (x) {
            if (x.the_caller == caller) {
                if (event.candidate) {
                    x.the_callee.onRemoteCandidate(event.candidate);
                }
            }
        })
    },
    onRemoteStream(stream) {
        localStream = stream
    },
    onNewAudience(new_audience) {
        console.log(">>> NEW AUDIENCE: ", new_audience)
        relayer = new RTCRelayer(new_audience.user, channel, servers, localStream)
        relayer.initiate()
    },
}
export default audience