-module(cbpanel_main_controller, [Req, SessionID]).
-compile([export_all]).

-include("user.hrl").
-include("service.hrl").
-include("user_service.hrl").

-define(HOSTING_SERVICES_TYPE, 1).
-define(VPS_SERVICES_TYPE, 2).

index('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, _UserData} -> {redirect, "/services"};
	{error, not_logined} -> {redirect, "/login"};
	{sys_error, Reason} -> {ok, [{sys_error, Reason}]}
    end.

login('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, _SessionData} -> {redirect, "/services"};
	{error, not_logined} -> {ok, []};
	{sys_error, Reason} -> {ok, [{sys_error, Reason}]}
    end;


login('POST', []) ->
    UserName = Req:post_param("username"),
    Password = Req:post_param("password"),
    %%LoginTime = erlang:now(),
    %% валидация формы
    %% проверка пароля
    io:format("Name: ~p; Pass: ~p~n",[UserName, Password]),
    case cbserver:get_user(UserName, Password) of
	{ok, UserData} ->
	    case boss_session:set_session_data(SessionID, "user_data", UserData) of
		ok -> 
		    %% редирект на страницу с подключенными сервисами
		    {redirect, "/services"};
		{error, Reason} -> {ok, [{sys_error, Reason}]}
	    end;
	_ -> {ok, []}
    end.



logout('GET', []) ->
    boss_session:delete_session(SessionID),
    {redirect, "/"}.


register('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, _SessionData} -> {redirect, "/services"};
	{error, not_logined} -> {ok, []};
	{sys_error, Reason} -> {ok, [{sys_error, Reason}]}
    end.


vps_table('GET', []) ->
    %% получить таблицу тарифов VPS (Virtual Private Server)
    {ok, []}.


hosting_table('GET', []) ->
    %% получить таблицу тарифов Web-Хостинга
    case cbserver:get_services(?HOSTING_SERVICES_TYPE) of
	{ok, Services} ->
	    ServicesData = lists:foldl(
			     fun(Service, R) ->
				     TermParams = commons:decode_service_params(Service#service.params),
				     %% модифицируем сруктуру сервиса
				     UpdatedService = Service#service{params=TermParams},
				     %% формируем список значений сервиса для отображения
				     ServiceData = commons:record_to_tuplelist(UpdatedService, service),
				     lists:append(R, [ServiceData])
			     end, [], Services),
	    io:format("ServicesData: ~p~n", [ServicesData]),
	    
	    {ok, [{services, ServicesData}]};
	_ -> {ok, []}
    end.
  

%% ######## INTERNAL FUNCTIONS #######

