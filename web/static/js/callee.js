"use strict"

let _peerConnection, _channel, _caller, _stream, _servers, _videoEl
let _listener

class RTCCallee {

    constructor(caller, channel, servers, videoEl, listener) {
        _caller = caller
        _channel = channel
        _servers = servers
        _videoEl = videoEl
        _listener = listener
    }

    initiate() {
        _peerConnection = new RTCPeerConnection(_servers)
        _peerConnection.onaddstream = this._onRemoteStream
    }

    onRemoteDescription(desc) {
        console.log(">>> GET CALLER DESC...")
        _peerConnection.setRemoteDescription(new RTCSessionDescription(desc.sdp))
        _peerConnection.createAnswer(this._getLocalDescription, this._onError)
    }

    onRemoteCandidate(candidate) {
        _peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
    }

    _onRemoteStream(event) {
        _stream = event.stream
        _videoEl.srcObject = _stream
        _listener(_stream)
    }

    _getLocalDescription(desc) {
        console.log(">>> SEND CALLEE DESC...")
        _peerConnection.setLocalDescription(desc, () => {
            _channel.push("audience_sdp", {
                to: _caller, body: JSON.stringify({
                    "sdp": _peerConnection.localDescription
                })
            });
        }, super.onError);
    }

    _onError(error) {
        console.log(">>> ERROR: ", error)
    }
}

export { RTCCallee }
