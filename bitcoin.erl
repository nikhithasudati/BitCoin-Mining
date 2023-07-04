-module(bitcoin).
-import(string,[to_lower/1]).
-import(string,[sub_string/3]).
-import(io, [format/2,format/1]).
-export([server_start/0, master/1, minecoin/1, worker/1, create_worker/2, spawn_worker/2,time/2]).


%% generating random string of length 400 and allowed characters list
get_random_string(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
                        [lists:nth(rand:uniform(length(AllowedChars)),
                                   AllowedChars)]
                            ++ Acc
                end, [], lists:seq(1, Length)).


%%leading zeros,because erlang doesnot generate the hash value with leading zeros, we have to explicitly add.            
leading_zeroes(0) -> "";  
leading_zeroes(N) -> 
    "0"++leading_zeroes(N-1).

%% Mining the bitcoin
minecoin(K) ->
    receive
        {mine, From, Node} ->
            Randomstring = "sudatinikhitha;"++get_random_string(15,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"),
            Hash_value = to_lower(integer_to_list(binary:decode_unsigned(crypto:hash(sha256,Randomstring)),16)),
            HashLength = string:len(Hash_value),
            if 
                HashLength =< (64-K) ->
                    format("Found Coin ~n"),
                    client ! got,
                    {From, Node} ! {got_coin,{Randomstring, leading_zeroes(K)++Hash_value}};
                true ->
                    spawn(bitcoin, minecoin,[K]) ! {mine, From, Node}
            end
    end.

%%It server as a server node
    master(K)->
    receive
        hello ->
            format(" Hello~n");
        {i_am_worker, WorkerPid} ->
            format("Master Received a Worker~n"),
            format("Worker Node ~p ~n",[WorkerPid]),
            WorkerPid ! hello;
        {got_coin, {Coin,Hash_value}} ->
            format("Coin : Hash ---> ~p  :  ~p~n",[Coin,Hash_value]);
        {mine, WPid} ->
            WPid ! {zcount, K};
        {time,CPU_time,Real_time, Ratio} ->
            format("CPU TIME : ~p ~n REAL TIME : ~p ~n RATIO : ~p ~n",[CPU_time,Real_time, Ratio]);
        terminate ->
            exit("Exited")
    end,
    master(K).

worker(Node) ->
    
    {serverPid, Node} ! {mine, self()},
    receive
        {zcount, K} ->
            spawn(bitcoin, minecoin,[K]) ! {mine, serverPid, Node}
    end.


    spawn_worker(1, Node) ->
    spawn(bitcoin, worker, [Node]);
    
spawn_worker(N, Node) ->
    spawn(bitcoin, worker, [Node]),
    spawn_worker(N-1, Node).

time(S,C) ->
    register(client,spawn(bitcoin,create_worker,[S,C])).

create_worker(Node,C) ->
    {_,_}=statistics(runtime),
    {_,_}=statistics(wall_clock),
    format("Creating Worker~n"),
    spawn_worker(C, Node),
    listen(1,Node).

listen(N,Node) ->
    receive 
        got ->
            format("B : ~p" , [N]), 
            if 
                N == 10->
                    {_,CPU_time}=statistics(runtime),
                    {_,Real_time}=statistics(wall_clock),
                    {serverPid,Node} ! {time,CPU_time, Real_time, CPU_time/Real_time};
                true ->
                    listen(N+1,Node)
            end
    end.

server_start() ->
    {ok, K} = io:read("Enter number of leading zeros: "),
    register(serverPid,spawn(bitcoin, master,[K])),
    {_,_}=statistics(runtime),
    {_,_}=statistics(wall_clock).


