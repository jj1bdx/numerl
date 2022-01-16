-module(mat).
-compile(export_all).
-export_type([matrix/0]).
-type matrix() :: [[number(), ...], ...].



%Used to measure the average run time required for a function to run.
%Measure in micro seconds.
bench(_,_,_,0,R)->
    R;
bench(F, A,N,I,R)->
    {Time, _} = timer:tc(F, A),
    bench(F, A, N,I-1, R+(Time/float(N))).
%Run the function N time to get its average performance.
bench(F ,Args ,N) ->
    %Do a FULL preheat
    _ = bench(F, Args, N, N, 0.0),
    bench(F, Args, N, N, 0.0).
%Run the function F a number of times.
bench(F, Args)->
    bench(F, Args, 5).

%Used to measure the average run time required for a function to run.
%Measure in micro seconds.
bench_nano(_,_,_,0,R)->
    R;
bench_nano(F,Arg,N,I,R)->
    T = erlang:system_time(nanosecond),
    F(Arg),
    bench_nano(F,Arg, N,I-1, R+((erlang:system_time(nanosecond))-T/float(N))).
%Run the function N time to get its average performance.
bench_nano(F,Arg,N) ->
    %Do a FULL preheat
    _ = bench_nano(F,Arg, N, N, 0.0),
    bench_nano(F, Arg, N, N, 0.0).
%Run the function F a number of times.
bench_nano(F, Arg)->
    bench_nano(F, Arg, 5).



%Save a function
write_to_file(Name, Intervals, Values)->
    FName = string:concat(string:concat("../benchRes/", Name), ".txt"),
    {ok, File} = file:open(FName, [write]),
    io:fwrite(File, "~p~n~p", [Intervals, Values]).

%

%% convert a list into a NxM matrix with N = length(List)/M
-spec list_to_matrix(List, M) -> Matrix when
    List :: list(),
    M :: pos_integer(),
    Matrix :: matrix().

list_to_matrix(List, M) ->
    list_to_matrix(List, M, []).


%% transpose matrix
-spec tr(M) -> Transposed when
    M :: matrix(),
    Transposed :: matrix().

tr(M) ->
    tr(M, []).


%% matrix addition (M3 = M1 + M2)
-spec '+'(M1, M2) -> M3 when
    M1 :: matrix(),
    M2 :: matrix(),
    M3:: matrix().

'+'(M1, M2) ->
    element_wise_op(fun erlang:'+'/2, M1, M2).


%% matrix subtraction (M3 = M1 - M2)
-spec '-'(M1, M2) -> M3 when
    M1 :: matrix(),
    M2 :: matrix(),
    M3 :: matrix().

'-'(M1, M2) ->
    element_wise_op(fun erlang:'-'/2, M1, M2).


%% matrix multiplication (M3 = Op1 * M2)
-spec '*'(Op1, M2) -> M3 when
    Op1 :: number() | matrix(),
    M2 :: matrix(),
    M3 :: matrix().

'*'(N, M) when is_number(N) ->
    [[N*X|| X <- Row] || Row <- M];
'*'(M1, M2) ->
    '*´'(M1, tr(M2)).


%% transposed matrix multiplication (M3 = M1 * tr(M2))
-spec '*´'(M1, M2) -> M3 when
    M1 :: matrix(),
    M2 :: matrix(),
    M3 :: matrix().

'*´'(M1, M2) ->
    [[lists:sum(lists:zipwith(fun erlang:'*'/2, Li, Cj))
        || Cj <- M2]
        || Li <- M1].

%% return true if M1 equals M2 using 1e-6 precision
-spec '=='(M1, M2) -> boolean() when
    M1 :: matrix(),
    M2 :: matrix().

'=='(M1, M2) ->
    case length(M1) == length(M2) of
        true when length(hd(M1)) == length(hd(M2)) ->
            RoundFloat = fun(F) -> round(F*1000000)/1000000 end,
            CmpFloat = fun(F1, F2) -> RoundFloat(F1) == RoundFloat(F2) end, 
            Eq = element_wise_op(CmpFloat, M1, M2),
            lists:all(fun(Row) -> lists:all(fun(B) -> B end, Row) end, Eq);
        false -> false
    end.


%% get the row I of M
-spec row(I, M) -> Row when
    I :: pos_integer(),
    M :: matrix(),
    Row :: matrix().

row(I, M) ->
    [lists:nth(I, M)].


%% get the column J of M
-spec col(J, M) -> Col when
    J :: pos_integer(),
    M :: matrix(),
    Col :: matrix().

col(J, M) ->
    [[lists:nth(J, Row)] || Row <- M].


%% get the element a index (I,J) in M
-spec get(I, J, M) -> Elem when
    I :: pos_integer(),
    J :: pos_integer(),
    M :: matrix(),
    Elem :: number().

get(I, J, M) ->
    lists:nth(J, lists:nth(I, M)).


%% build a null matrix of size NxM
-spec zeros(N, M) -> Zeros when
    N :: pos_integer(),
    M :: pos_integer(),
    Zeros :: matrix().

zeros(N, M) ->
    [[0 || _ <- lists:seq(1, M)] || _ <- lists:seq(1, N)].


%% build an identity matrix of size NxN
-spec eye(N) -> Identity when
    N :: pos_integer(),
    Identity :: matrix().

eye(N) ->
    [[ if I =:= J -> 1; true -> 0 end
        || J <- lists:seq(1, N)]
        || I <- lists:seq(1, N)].


%% compute the inverse of a square matrix
-spec inv(M) -> Invert when
    M :: matrix(),
    Invert :: matrix().

inv(M) ->
    N = length(M),
    A = lists:zipwith(fun lists:append/2, M, eye(N)),
    Gj = gauss_jordan(A, N, 0, 1),
    [lists:nthtail(N, Row) || Row <- Gj].


%% evaluate a list of matrix operations
-spec eval(Expr) -> Result when
    Expr :: [T],
    T :: matrix() | '+' | '-' | '*' | '*´',
    Result :: matrix().

eval([L|[O|[R|T]]]) ->
    F = fun mat:O/2,
    eval([F(L, R)|T]);
eval([Res]) ->
    Res.




%% transpose matrix with accumulator
tr([[]|_], Rows) ->
    lists:reverse(Rows);
tr(M, Rows) ->
    {Row, Cols} = tr(M, [], []),
    tr(Cols, [Row|Rows]).

%% transpose the first row of a matrix with accumulators
tr([], Col, Cols) ->
    {lists:reverse(Col), lists:reverse(Cols)};
tr([[H|T]|Rows], Col, Cols) ->
    tr(Rows, [H|Col], [T|Cols]).

%% apply Op element wise on matrices M1 and M2
element_wise_op(Op, M1, M2) ->
    lists:zipwith(fun(L1, L2) -> lists:zipwith(Op, L1, L2) end, M1, M2).

%% Gauss-Jordan method from
%% https://fr.wikipedia.org/wiki/%C3%89limination_de_Gauss-Jordan#Pseudocode
gauss_jordan(A, N, _, J) when J > N ->
    A;
gauss_jordan(A, N, R, J) ->
    case pivot(col(J, lists:nthtail(R, A)), R+1, {0, 0}) of
        {_, 0} ->
            gauss_jordan(A, N, R, J+1);
        {K, Pivot} ->
            A2 = swap(K, R+1, A),
            [Row] = row(R+1, A2),
            Norm = lists:map(fun(E) -> E/Pivot end, Row),
            A3 = gauss_jordan_aux(A2, {R+1, J}, Norm, 1, []),
            gauss_jordan(A3, N, R+1, J+1)
    end.

%% Matrix(i, :) -= Matrix(i, j)/Pivot * Matrix(R, :) forall i\{R}
%% Matrix(R, :) *= 1/Pivot
%% with Pivot = Matrix(R, j)
gauss_jordan_aux([], _, _, _, Acc) ->
    lists:reverse(Acc);
gauss_jordan_aux([_|Rows], {I, J}, L, I, Acc)->
    gauss_jordan_aux(Rows, {I, J}, L, I+1, [L|Acc]);
gauss_jordan_aux([Row|Rows], {R, J}, L, I, Acc) ->
    F = lists:nth(J, Row),
    NewRow = lists:zipwith(fun(A, B) -> A-F*B end, Row, L),
    gauss_jordan_aux(Rows, {R, J}, L, I+1, [NewRow|Acc]).

%% find the gauss jordan pivot of a column
pivot([], _, Pivot) ->
    Pivot;
pivot([[H]|T], I, {_, V}) when abs(H) >= abs(V) ->
    pivot(T, I+1, {I, H});
pivot([_|T], I, Pivot) ->
    pivot(T, I+1, Pivot).

%% swap two indexes of a list
%% taken from https://stackoverflow.com/a/64024907
swap(A, A, List) ->
    List;
swap(A, B, List) ->
    {P1, P2} = {min(A,B), max(A,B)},
    {L1, [Elem1 | T1]} = lists:split(P1-1, List),
    {L2, [Elem2 | L3]} = lists:split(P2-P1-1, T1), 
    lists:append([L1, [Elem2], L2, [Elem1], L3]).

list_to_matrix([], _, Acc) ->
    lists:reverse(Acc);
list_to_matrix(List, M, Acc) ->
    {Row, Rest} = lists:split(M, List),
    list_to_matrix(Rest, M, [Row|Acc]).
