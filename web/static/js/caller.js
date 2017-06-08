"use strict"

let _peerConnection, _channel, _callee, _stream, _servers

class RTCCaller {

    constructor(callee, channel, servers, stream) {
        _channel = channel
        _callee = callee
        _servers = servers
        _stream = stream
    }

    initiate() {
        _peerConnection = new RTCPeerConnection(_servers)
        _peerConnection.onicecandidate = this._getOnIceCandidate
        _peerConnection.oniceconnectionstatechange = this._onConnectionStateChange
        _peerConnection.addStream(_stream)

        this._getLocalDescription(null)
        _peerConnection.createOffer(this._getLocalDescription, this._onError)
    }

    onRemoteDescription(desc) {
        _peerConnection.setRemoteDescription(new RTCSessionDescription(desc.sdp))
    }

    _onConnectionStateChange(event) {
        if (_peerConnection.iceConnectionState === "completed") {
            _channel.push("anchor_relayed", {})
        }
    }

    _getOnIceCandidate(event) {
        if (event.candidate) {
            _channel.push("anchor_candidate", {
                to: _callee, body: JSON.stringify({
                    "candidate": event.candidate
                })
            });
        }
    }

    _getLocalDescription(desc) {
        _peerConnection.setLocalDescription(desc, () => {
            _channel.push("anchor_sdp", {
                to: _callee, body: JSON.stringify({
                    "sdp": _peerConnection.localDescription
                })
            })
        }, super.onError)
    }

    _onError(error) {
        console.log(">>> ERROR: ", error)
    }
}

export { RTCCaller }