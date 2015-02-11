-module(cbserver).
-compile([export_all]).

%% В этом модуле содержатся обёртки для rpc-вызовов к cbserver

%%  MODULE: user

register(UserName, Password, Email) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'user', 'register', [UserName, Password, Email]).


login(UserName, Password) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'user', 'login', [UserName, Password]).


logout(UserId, SessionKey) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'user', 'logout', [UserId, SessionKey]).


%%  MODULE: db_api

get_user(UserName, Password) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'db_api', 'get_user', [UserName, Password]). 

get_services(Type) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'db_api', 'get_services', [Type]).


get_user_services({user_id, UserId}) ->
    Node = config:get(cbserver_node),
    rpc:call(Node, 'db_api', 'get_user_services', [{user_id, UserId}]).


add_new_order(UserId, ServiceId, Params, Period, ProcessingMode) ->
    Node = config:get(cbserver_node),
    Args = [UserId, ServiceId, Params, Period, ProcessingMode],
    rpc:cast(Node, 'order', 'create', Args).




