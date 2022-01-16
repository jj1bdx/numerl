-module(benchmark).
-compile(export_all).
-import(math, [log10/1]).
-import(timer, [sleep/1, tc/3]).


%Used to measure the average run time required for a function to run.
%Measure in micro seconds.
bench_nano(_,_,_,0,R)->
    R;
bench_nano(F,Arg,N,I,R)->
    T = erlang:system_time(nanosecond),
    F(Arg),
    bench_nano(F,Arg, N,I-1, R+((erlang:system_time(nanosecond)-T)/float(N))).
%Run the function N time to get its average performance.
bench_nano(F,Arg,N) ->
    %Do a FULL preheat
    _ = bench_nano(F,Arg, N, N, 0.0),
    bench_nano(F, Arg, N, N, 0.0).
%Run the function F a number of times.
bench_nano(F, Arg)->
    bench_nano(F, Arg, 5).

it([], Acc)-> Acc;
it([H|T], Acc) -> it(T, [H|Acc]).
it(L) -> it(L, []).

%Used to measure the average run time required for a function to run.
%Measure in micro seconds.
bench(_,_,_,0,R)->
    R;

bench(F, A,N,I,R)->
    {Time, _} = timer:tc(F, A),
    bench(F, A, N,I-1, R+(Time/float(N))).

%Run the function N time to get its average performance.
bench(F ,Args ,N) ->
    Argv = Args(N),
    %Do a FULL preheat
    _ = bench(F, Argv, N, N, 0.0),
    bench(F, Argv, N, N, 0.0).

%Run the function F a number of times.
bench(F, Args)->
    bench(F, Args, 5).




%Creates a random matrix containing a single row.
rnd_row(N)->
    [[rand:uniform(100) || _ <- lists:seq(1,N)]].

%Creates a random matrix of size NxN
rnd_matrix(N)->
    [ [rand:uniform(100) || _ <- lists:seq(1, N)] || _ <- lists:seq(1,N)].

%Creates a random int
rnd() ->
    rand:uniform(100).


%Creates an inversible matrix: use DGESV to see if the matrix defines a solvable system.
inv_matrix(N) when N > 1->
    M = rnd_matrix(N),
    EM = numerl:matrix(M),
    R = numerl:dgesv(EM,EM),
    if is_atom(R) ->
        inv_matrix(N);
    true ->
        M
    end;
inv_matrix(1)->
    rnd_matrix(1).

%Prints the given results.
show_results(Name, T_e, T_n)->
    io:format("~nTesting ~w\nErlang native:  ~f\nNif: ~f\nFactor:~f~n", [Name,T_e, T_n, T_e/T_n]).

%Save a function
write_to_file(Name, Intervals, Values)->
    FName = string:concat(string:concat("../benchRes/", Name), ".txt"),
    {ok, File} = file:open(FName, [write]),
    io:fwrite(File, "~p~n~p", [Intervals, Values]).

bench_mat_creation(N)->
    io:format("Benching mat creation~n"),
    List = [ [ rand:uniform(100) || _ <-lists:seq(0,N)] ],
    Time = bench(fun numerl:matrix/1, fun(_) -> [List] end, 10000),
    io:format("Result:~f~n", [float(Time)]).

bench_plus(N)->
    io:format("Benching plus~n"),
    Time = bench(fun numerl:'+'/2, fun(_) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

bench_mult(N)->
    io:format("Benching multiplication of matrices~n"),
    Time = bench(fun numerl:'*'/2, fun(_) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

bench_mult_tr(N)->
    io:format("Benching multiplication of matrices tr~n"),
    Time = bench(fun numerl:'*tr'/2, fun(_) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

bench_mult_erl(N)->
    io:format("Benching multiplication of matrices tr~n"),
    Time = bench(fun mat:'*'/2, fun(_) -> [rnd_matrix(N), rnd_matrix(N)] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

bench_tr(N)->
    io:format("Benching tr of square matrix~n"),
    Time = bench(fun numerl:'tr'/1, fun(_) -> [numerl:matrix(rnd_matrix(N))] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

bench_dot(N)->
    io:format("Benching dot time execution~n"),
    Steps = lists:seq(0, N),
    A = [1 || _ <- Steps],
    B = [2 || _ <- Steps],
    Fct = fun(X,Y) -> lists:sum(lists:zipwith(fun erlang:'*'/2 ,X,Y)) end,
    Time = bench(Fct, fun(_) -> [A,B] end, 1000),
    io:format("Result:~f~n", [float(Time)]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compare performances
%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%Used to measure the average run time required for a function to run.
%Measure in milli seconds.
b(_,_,_,0,R)->
    R;

b(F, A,N,I,R)->
    {Time, _} = timer:tc(F, A),
    b(F, A, N,I-1, R+(Time/float(N))).

%Run the function N time to get its average performance.
b(F ,Args ,N) ->
    %Do a preheat
    _ = b(F, Args, 500, 500, 0.0),
    b(F, Args, N, N, 0.0).

bench_fcts(_,_,[],[],[])->
    io:format("Finished.");

bench_fcts(NRuns, Steps, [F|Fcts], [Arg|Args], [File|Files])->
    io:format("Running benchmark  ~s", [File]),
    Result = [b(F, Arg(N), NRuns) || N<-Steps],
    write_to_file(File, Steps, Result),
    io:format ("; finished in ~f s~n", [lists:sum(Result)*(NRuns+500)/1000000]),
    bench_fcts(NRuns, Steps, Fcts, Args, Files).


bench_zeros(NRuns, Steps)->
    Fcts = [fun numerl:zeros/2, fun mat:zeros/2],
    Args = [fun (N)->[N,N] end, fun (N)->[N,N] end],
    Files = ["zero_c", "zero_e"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_zeros()->
    bench_zeros(500, lists:seq(20, 200, 20)).


bench_mult_num(NRuns, Steps)->
    io:format("Benching mult num operator.~n"),
    Fcts = [fun mat:'*'/2, fun numerl:'*'/2],
    Args = [fun (N) -> [rnd(), rnd_matrix(N)] end,
            fun (N) -> [rnd(), numerl:matrix(rnd_matrix(N))] end],
    Files = ["mult_num_e", "mult_num_c"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_mult_num()->
    bench_mult_num(1500, lists:seq(20,100,10)).


bench_mult(NRuns, Steps)->
    io:format("Benching mult operator.~n"),
    Fcts = [fun mat:'*'/2, fun numerl:'*'/2],
    Args = [fun (N) -> [rnd_matrix(N), rnd_matrix(N)] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end],
    Files = ["mult_e", "mult_c"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_mult()->
    bench_mult(500, lists:seq(20,100,10)).


bench_inv(NRuns, Steps)->
    io:format("Benching inv operator.~n"),
    Fcts = [fun mat:inv/1, fun numerl:inv/1],
    Args = [fun (N) -> [inv_matrix(N)] end,
            fun (N) -> [numerl:matrix(inv_matrix(N))] end],
    Files = ["inv_e", "inv_c"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_inv()->
    bench_inv(500, lists:seq(20,100,10)).


bench_multb(NRuns, Steps)->
    io:format("Benching BLAS agains naïve multiplication.~n"),
    Fcts = [ fun numerl:dgemm/5,  fun numerl:'*'/2],
    Args = [
            fun (N) -> [1,numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N)), 0, numerl:matrix(rnd_matrix(N))] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end],
    Files = [ "mult_blas", "mult_nc"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_multb()->
    bench_multb(500, lists:seq(20,100,10)).

bench_solve(NRuns, Steps)->
    io:format("Benching inverse solver.~n"),
    Fcts = [ fun(A,B)-> I = numerl:inv(A), numerl:'*'(I, B) end, fun numerl:dgesv/2],
    Args = [
            fun (N) -> [numerl:matrix(inv_matrix(N)), numerl:matrix(rnd_matrix(N))] end,
            fun (N) -> [numerl:matrix(inv_matrix(N)), numerl:matrix(rnd_matrix(N))] end],
    Files = [ "solve_c", "solve_blas"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_solve()->
    bench_solve(500, lists:seq(20,100,10)).

bench_tr(NRuns, Steps)->
    io:format("Benching tr operator.~n"),
    Fcts = [fun mat:tr/1, fun numerl:tr/1],
    Args = [fun (N) -> [rnd_matrix(N)] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N))] end],
    Files = ["tr_e", "tr_c"],
    bench_fcts(NRuns, Steps, Fcts, Args, Files).
bench_tr()->
    bench_tr(2000, lists:seq(20,200,20)).
    

bench()->
    bench_zeros(),
    bench_mult_num(),
    bench_mult(),
    bench_inv(),
    bench_multb(),
    bench_solve(),
    bench_tr().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Benchmark rapid functions: call them Factor times instead of 1 time
%%% to get more accurate measures

bench_small_fcts(_,_,_, [],[],[])->
    io:format("Finished.");

bench_small_fcts(NRuns, Steps, Factor, [F|Fcts], [Arg|Args], [File|Files])->
    io:format("Running benchmark  ~s", [File]),
    Result = [b(F, Arg(N), NRuns) / Factor|| N<-Steps],
    write_to_file(File, Steps, Result),
    io:format ("; finished in ~f ms~n", [lists:sum(Result)*NRuns*Factor/1000]),
    bench_small_fcts(NRuns, Steps, Factor, Fcts, Args, Files).



bench_plus(NRuns, Steps)->
    io:format("Benching plus operator.~n"),
    Fcts = [fun benchk:matplus/2, fun benchk:numerlplus/2],
    Args = [fun (N) -> [rnd_matrix(N), rnd_matrix(N)] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N)), numerl:matrix(rnd_matrix(N))] end],
    Files = ["plus_e", "plus_c"],
    bench_small_fcts(NRuns, Steps, 10000, Fcts, Args, Files).
bench_plus()->
    bench_plus(100, lists:seq(1,100,10)).

rnd_vec_max(N)->
    [ float(rnd()) || _ <- lists:seq(1,N)].

bench_emax(NRuns, Steps)->
    Fcts = [fun benchk:listMax/2],
    Args = [fun (I) -> [rnd_vec_max(I), 0] end],
    File = ["max_e"],
    bench_small_fcts(NRuns, Steps, 10000, Fcts, Args, File).

bench_max(NRuns, Steps)->
    Fcts = [fun benchk:listMax/2, fun benchk:nif_max/2, fun benchk:nif_matrix_max/2],
    Args = [fun (I) -> [rnd_vec_max(I)] end,
            fun (I) -> [rnd_vec_max(I)] end,
            fun (I) -> [numerl:matrix([rnd_vec_max(I)])] end],
    
    Files = ["max_list_e", "max_list_c", "max_mat_c"],
    bench_small_fcts(NRuns, Steps, 1000, Fcts, Args, Files).
bench_max()->
    bench_max(20000, lists:seq(1,10)).

bench_small_zero(NRuns, Steps)->
    io:format("Benching small zero.~n"),
    Fcts = [fun benchk:mat_zeros/2, fun benchk:numerl_zeros/2],
    Args = [fun (N) -> [N,N] end,
            fun (N) -> [N,N] end],
    Files = ["small_zero_e", "small_zero_c"],
    bench_small_fcts(NRuns, Steps, 1000, Fcts, Args, Files).
bench_small_zero()->
    bench_small_zero(1000, lists:seq(1,50,5)).

bench_small_mult(NRuns, Steps)->
    io:format("Benching small mult.~n"),
    Fcts = [fun benchk:mat_mult/2, fun benchk:numerl_mult/2],
    Args = [fun (N) -> [rnd_matrix(N),rnd_matrix(N)] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N)),numerl:matrix(rnd_matrix(N))] end],
    Files = ["small_mult_e", "small_mult_c"],
    bench_small_fcts(NRuns, Steps, 500, Fcts, Args, Files).
bench_small_mult()->
    bench_small_mult(500, lists:seq(1,10,1)).

bench_small_inv(NRuns, Steps)->
    io:format("Benching small mult.~n"),
    Fcts = [fun benchk:mat_inv/1, fun benchk:numerl_inv/1],
    Args = [fun (N) -> [rnd_matrix(N)] end,
            fun (N) -> [numerl:matrix(rnd_matrix(N))] end],
    Files = ["small_inv_e", "small_inv_c"],
    bench_small_fcts(NRuns, Steps, 1000, Fcts, Args, Files).


run_all_fcts(M,N)->
    _ = numerl:eye(N),
    _ = numerl:zeros(N, N),
    _ = numerl:'+'(M,M),
    _ = numerl:'-'(M,N),
    _ = numerl:'*'(N,M),
    _ = numerl:'*'(M,M),
    _ = numerl:tr(M),
    _ = numerl:inv(M).


loop_fct_until(Fct, Time)->
    CurTime = erlang:system_time(second),
    if CurTime > Time -> ok;
    true -> 
        Fct(),
        loop_fct_until(Fct, Time)
    end.

loop_fct_for_s(Fct, Seconds)->
    CurTime = erlang:system_time(second),
    loop_fct_until(Fct, CurTime + Seconds).


reduce_col([], C, Rm)->
    {lists:reverse(C), lists:reverse(Rm)};
reduce_col([[Hr|Tr]|Rows], C, Rm)->
    reduce_col(Rows, [Hr|C], [Tr|Rm]).

btr([[]|_], Tr)->
    lists:reverse(Tr);
btr(M, Tr)->
    {Col, Rst} = reduce_col(M, [], []),
    btr(Rst, [Col|Tr]).
btr(M)->
    btr(M,[]).


%btr(Matrix, AccCols, AccCol, NewRows).

%Job finished!
btrf([[]|_], [], [], NewRows)->
    lists:reverse(NewRows);
%Finished extracting a column
btrf([], AccCols, AccCol, NewRows)->
    btrf(lists:reverse(AccCols), [], [], [lists:reverse(AccCol)|NewRows]);
%Currently extracting a column
btrf([[Rh|Rt]|Rows], AccCols, AccCol, NewRows)->
    btrf(Rows, [Rt|AccCols], [Rh|AccCol], NewRows).
%Simpler function.
btrf(M)->
    btrf(M, [], [], []).



%btrf(M)->
%    btrf().    



split(0,_)->
    [];
split(N,[H|T])->
    [H|split(N-1,T)].

split_tr(0, _,R)->
    lists:reverse(R,[]);
split_tr(N,[H|T], R)->
    split_tr(N-1, T, [H|R]).

m_tr([[]|_]) -> [];
m_tr(L)->
    [[ C || [C|_] <- L] |  m_tr([T || [_|T] <- L])].


empty_fun()-> true.