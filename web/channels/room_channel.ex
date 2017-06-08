defmodule One2relay.RoomChannel do
    use One2relay.Web, :channel
    alias One2relay.RoomManager
    alias One2relay.Member
    require Logger

    def join("room", _params, socket) do
        user = socket.assigns.user
        cond do
            String.contains? user, "audience" ->
                send self(), "new_audience"
            true ->
                send self(), "new_anchor"
        end
        {:ok, socket}
    end

    ###################################################################
    # Anchor's related functions
    ###################################################################

    def handle_info("new_anchor", socket) do
        user = socket.assigns.user
        :ok = RoomManager.put_anchor(%Member{name: user, socket: socket})

        old_audiences = RoomManager.get_audiences
        cond do
            old_audiences == [] ->
                :ignore
            true ->
                # wait for 2 seconds for anchor's client app ready
                # to receives old audiences
                :timer.sleep(2000)
                #Logger.info(">>> INFO OLD AUDIENCES TO ANCHOR...")
                Enum.each(old_audiences, fn(%Member{name: name}) -> 
                    push socket, "old_audiences", %{"user" => name} 
                end)
        end
        {:noreply, socket}
    end

    def handle_in("anchor_sdp", %{"to" => name, "body" => body}, socket) do
        #Logger.info(">>> ANCHOR SDP, TO #{inspect member}")
        audience = RoomManager.get_audience(name)
        cond do
            audience != nil ->
                Logger.info(">>> FORWARD SDP...")
                user = socket.assigns.user
                push audience.socket, "anchor_sdp", %{"origin" => user, "body" => body}
            true ->
                Logger.info(">>> IGNORE SDP...")
                :ignore
        end
        {:noreply, socket}
    end

    def handle_in("anchor_candidate", %{"to" => name, "body" => body}, socket) do
        #Logger.info(">>> ANCHOR CANDIDATE, TO #{inspect name}")
        audience = RoomManager.get_audience(name)
        cond do
            audience != nil ->
                #Logger.info(">>> FORWARD CANDIDATE...")
                user = socket.assigns.user
                push audience.socket, "candidate", %{"origin" => user, "body" => body}
            true ->
                #Logger.info(">>> IGNORE CANDIDATE...")
                :ignore
        end
        {:noreply, socket}
    end

    def handle_in("anchor_relayed", %{}, socket) do
        Logger.info(">>> ANCHOR RELAYING...")
        user = socket.assigns.user
        :ok = RoomManager.put_anchor(%Member{name: user, socket: socket, relaying: true})
        {:noreply, socket}
    end

    ###################################################################
    # Audience's related functions
    ###################################################################

    def handle_info("new_audience", socket) do
        user = socket.assigns.user
        Logger.info(">>> AN AUDIENCE JOIN: #{user}")
        :ok = RoomManager.add_audience(%Member{name: user, socket: socket})

        anchor = RoomManager.get_anchor
        cond do
            anchor == nil ->
                :ignore
            true ->
                cond do
                    anchor.relaying == false ->
                        Logger.info(">>> FORWARD TO ANCHOR...")
                        push anchor.socket, "new_audience",  %{"user" => user}
                    true ->
                        Logger.info(">>> FORWARD TO OLD AUDIENCE...")
                        old_audience = RoomManager.get_last_audience
                        cond do
                            old_audience == nil ->
                                :ignore
                            true ->
                                push old_audience.socket, "new_audience",  %{"user" => user}
                        end
                end
        end
        {:noreply, socket}
    end

    def handle_in("audience_sdp", %{"to" => caller, "body" => body}, socket) do
        user = socket.assigns.user
        relayer = RoomManager.get_audience(caller)
        cond do
            relayer != nil ->
                push relayer.socket, "audience_sdp", %{"origin" => user, "body" => body}
            true ->
                anchor = RoomManager.get_anchor
                cond do
                    anchor != nil ->
                        push anchor.socket, "audience_sdp", %{"origin" => user, "body" => body}
                    true ->
                        :ignore
                end
        end
        {:noreply, socket}
    end

    ###################################################################
    # Relayer's related functions
    ###################################################################

    def handle_in("relayer_sdp", %{"to" => name, "body" => body}, socket) do
        Logger.info(">>> RELAYER SDP, TO #{inspect name}")
        audience = RoomManager.get_audience(name)
        cond do
            audience != nil ->
                Logger.info(">>> FORWARD SDP...")
                user = socket.assigns.user
                push audience.socket, "relayer_sdp", %{"origin" => user, "body" => body}
            true ->
                Logger.info(">>> IGNORE SDP...")
                :ignore
        end
        {:noreply, socket}
    end

    def handle_in("relayer_candidate", %{"to" => name, "body" => body}, socket) do
        Logger.info(">>> RELAYER CANDIDATE, TO #{inspect name}")
        audience = RoomManager.get_audience(name)
        cond do
            audience != nil ->
                Logger.info(">>> FORWARD CANDIDATE...")
                user = socket.assigns.user
                push audience.socket, "candidate", %{"origin" => user, "body" => body}
            true ->
                #Logger.info(">>> IGNORE CANDIDATE...")
                :ignore
        end
        {:noreply, socket}
    end

    def handle_in("relayer_relayed", %{}, socket) do
        user = socket.assigns.user
        audience = RoomManager.get_audience(user)
        cond do
            audience != nil ->
                Logger.info(">>> RELAYER RELAYING...")
                :ok = RoomManager.set_audience_to_relayed(user)
            true ->
                :ignore
        end
        {:noreply, socket}
    end

    def terminate(_reason, socket) do
        user = socket.assigns.user
        cond do
            user == "anchor" ->
                Logger.info(">>> DELETE ANCHOR")
                RoomManager.del_anchor()
            true ->
                Logger.info(">>> DELETE AUDIENCE #{user}")
                :ok = RoomManager.del_audience(%Member{name: user, socket: socket})
        end
        {:noreply, socket}
    end

end