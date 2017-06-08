defmodule One2relay.RoomManager do
    use GenServer
    alias One2relay.Room
    alias One2relay.Member
    import Process, only: [whereis: 1]
    require Logger

    def start_link(args \\ nil) do
        GenServer.start_link(__MODULE__, %Room{}, name: __MODULE__)
    end

    def init(map) do
        {:ok, map}
    end
    
    def put_anchor(member) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:put_anchor, member})
    end

    def get_anchor do
        pid = whereis(__MODULE__)
        GenServer.call(pid, :get_anchor)
    end

    def del_anchor do
        pid = whereis(__MODULE__)
        GenServer.call(pid, :del_anchor)
    end

    def add_audience(member) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:add_audience, member})
    end

    def del_audience(member) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:del_audience, member})
    end

    def get_audiences do
        pid = whereis(__MODULE__)
        GenServer.call(pid, :get_audiences)
    end

    def get_audience(name) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:get_audience, name})
    end

    def get_last_audience do
        pid = whereis(__MODULE__)
        GenServer.call(pid, :get_last_audience)
    end

    def set_audience_to_relayed(name) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:set_audience_to_relayed, name})
    end

    def set_audience_to_unrelayed(name) do
        pid = whereis(__MODULE__)
        GenServer.call(pid, {:set_audience_to_unrelayed, name})
    end

    def set_unrelayed_all_audiences do
        pid = whereis(__MODULE__)
        GenServer.call(pid, :set_unrelayed_all_audiences)
    end

    def handle_call({:put_anchor, member}, _from, room) do
        room = Map.put(room, :anchor, member)
        {:reply, :ok, room}
    end

    def handle_call(:get_anchor, _from, room) do
        {:reply, room.anchor, room}
    end

    def handle_call(:del_anchor, _from, room) do
        room = Map.put(room, :anchor, nil)
        {:reply, :ok, room}
    end

    def handle_call({:add_audience, member}, _from, room) do
        list = room.audiences
        room = Map.put(room, :audiences, list ++ [member])
        {:reply, :ok, room}
    end

    def handle_call({:del_audience, member}, _from, room) do
        list = room.audiences |>
            Enum.filter(fn(%Member{name: name}) -> name != member.name end)
        room = Map.put(room, :audiences, list)
        {:reply, :ok, room}
    end

    def handle_call(:get_audiences, _from, room) do
        {:reply, room.audiences, room}
    end

    def handle_call({:get_audience, audience_name}, _from, room) do
        result = room.audiences |>
            Enum.filter(fn(%Member{name: name}) -> name == audience_name end)
        cond do
            result == [] ->
                {:reply, nil, room}
            true ->
                [audience] = result
                {:reply, audience, room}
        end
        
    end

    def handle_call(:get_last_audience, _from, room) do
        result = room.audiences |>
            Enum.filter(fn(%Member{relaying: status}) -> status == false end)
        cond do
            result == [] ->
                {:reply, nil, room}
            true ->
                [audience | _rest] = result
                {:reply, audience, room}
        end
    end

    def handle_call({:set_audience_to_relayed, audience_name}, _from, room) do
        result = room.audiences |>
            Enum.filter(fn(%Member{name: name}) -> name == audience_name end)
        cond do
            result == [] ->
                {:reply, :not_found, room}
            true ->
                # removes selected audience from audiences list
                list = room.audiences |>
                    Enum.filter(fn(%Member{name: name}) -> name != audience_name end)

                # updates selected audience's relaying status
                [audience] = result
                updated_audience = %{audience | relaying: true}

                # return updated audience to audiences list
                room = Map.put(room, :audiences, list ++ [updated_audience])
                {:reply, :ok, room}
        end
    end

    def handle_call({:set_audience_to_unrelayed, audience_name}, _from, room) do
        result = room.audiences |>
            Enum.filter(fn(%Member{name: name}) -> name == audience_name end)
        cond do
            result == [] ->
                {:reply, :not_found, room}
            true ->
                # removes selected audience from audiences list
                list = room.audiences |>
                    Enum.filter(fn(%Member{name: name}) -> name != audience_name end)

                # updates selected audience's relaying status
                [audience] = result
                updated_audience = %{audience | relaying: false}

                # return updated audience to audiences list
                room = Map.put(room, :audiences, list ++ [updated_audience])
                {:reply, :ok, room}
        end
    end

    def handle_call(:set_unrelayed_all_audiences, _from, room) do
        list = room.audiences |>
            Enum.map(fn(%Member{name: name, socket: socket, relaying: true}) -> 
                %Member{name: name, socket: socket, relaying: false} 
            end)
        room = Map.put(room, :audiences, list)
        {:reply, :ok, room}
    end
end