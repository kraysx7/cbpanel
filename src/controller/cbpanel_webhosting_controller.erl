-module(cbpanel_webhosting_controller, [Req, SessionID]).
-compile([export_all]).

-include("user.hrl").
-include("service.hrl").
-include("user_service.hrl").

-define(HOSTING_SERVICES_TYPE, 1).

index('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
	    case cbserver:get_user_services({user_id, UserData#user.user_id}) of
		{ok, UserServices} ->
		    UserServicesData = commons:records_to_tuplelist(UserServices, user_service),
		    io:format("UserServicesData: ~p~n", [UserServicesData]),
		    
		    {ok, [
			  {active_tab, tabs:get_tab_id(Req:path())}, {tabs, tabs:get_tabs()},
			  {user_data, [{name, UserData#user.name}, {balance, UserData#user.balance}]},
			  {user_services, UserServicesData}
			 ] 
		    };
		_ -> {ok, []}
	    end;
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end.

%% страница оформления заказа веб-хостинга
create_order('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
	    %% получить таблицу тарифов Web-Хостинга
	    case cbserver:get_services(?HOSTING_SERVICES_TYPE) of
		{ok, Services} ->
		    ServicesData = commons:records_to_tuplelist(Services, service),
		    io:format("ServicesData: ~p~n", [ServicesData]),
		    
		    {ok, [
			  {active_tab, tabs:get_tab_id("/panel/webhosting")}, {tabs, tabs:get_tabs()},
			  {user_data, [{name, UserData#user.name}, {balance, UserData#user.balance}]},
			  {service_id, 1}, {services, ServicesData}
			 ]
		    };
		_ -> {ok, []}
	    end;	
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end;

%% POST already is ajax 
create_order('POST', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
	    FormData = [ {domain_name, Req:post_param("domainname")}, 
			 {service_id,  Req:post_param("serviceid")},
			 {password, Req:post_param("password")}, 
			 {send_password, Req:post_param("sendpassword")} ],

	    case check_form(create_order, FormData) of
		{error, CheckRes} ->
		    {ok, Services} = cbserver:get_services(?HOSTING_SERVICES_TYPE),
		    ServicesData = commons:records_to_tuplelist(Services, service),
		    Vars = lists:append([ [{services, ServicesData}], [{check_res, CheckRes}], FormData ]),
		    io:format("Vars: ~p~n",[Vars]),
		    {render_other, [{action, "create_order_form"}], Vars};
		ok ->
		    %% RPC запрос к биллинг серверу для добавления нового заказа
		    ServiceId = commons:list_to_integer(proplists:get_value(service_id, FormData)),
		    Params = [
			      {domain_name, proplists:get_value(domain_name, FormData)},
			      {password, proplists:get_value(password, FormData)}
			     ],
		    
		    io:format("Panel PID: ~p~n", [self()]),

		    R = cbserver:add_new_order(UserData#user.user_id, ServiceId, Params, 1440, 0),

		    io:format("------ ~p -------~n",[R]),
		    {render_other, [{action, "create_order_result"}], []}
	    end;
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end.




%% Check form functions

check_form(create_order, FormData) ->
    io:format("DEBUG>>> check form: create_order~n", []),
    DomainName = proplists:get_value(domain_name, FormData),
    ServiceId = proplists:get_value(service_id, FormData),
    Password = proplists:get_value(password, FormData),
    SendPassword = proplists:get_value(send_password, FormData),
    io:format("DomainName : ~p~n", [DomainName]),
    io:format("Password : ~p~n", [Password]),
    io:format("SendPassword: ~p~n", [SendPassword]),
    io:format("ServiceId: ~p~n", [ServiceId]),
    CheckResult = [
		{domain_name, check_domain_name(DomainName)},
		{service_id,  check_service_id(ServiceId)},
		{password,  check_password(Password)},
		{send_password,  ok}
	       ],
    case CheckResult of
	[{_,ok}, {_,ok}, {_, ok}, {_, ok}] -> ok;
	_-> {error, CheckResult}
    end.


check_input(Value, MinLength) when is_list(Value) ->
    case length(Value) - MinLength of
	DL when DL < 0 -> value_is_short;
	_ -> ok
    end;
check_input(_Value, _Length) -> badarg.



-define(DOMAIN_REGEXP, "^([a-z0-9]([-a-z0-9]*[a-z0-9])?\\.)+((a[cdefgilmnoqrstuwxz]|aero|arpa)|(b[abdefghijmnorstvwyz]|biz)|(c[acdfghiklmnorsuvxyz]|cat|com|coop)|d[ejkmoz]|(e[ceghrstu]|edu)|f[ijkmor]|(g[abdefghilmnpqrstuwy]|gov)|h[kmnrtu]|(i[delmnoqrst]|info|int)|(j[emop]|jobs)|k[eghimnprwyz]|l[abcikrstuvy]|(m[acdghklmnopqrstuvwxyz]|mil|mobi|museum)|(n[acefgilopruz]|name|net)|(om|org)|(p[aefghklmnrstwy]|pro)|qa|r[eouw]|s[abcdeghijklmnortvyz]|(t[cdfghjklmnoprtvwz]|travel)|u[agkmsyz]|v[aceginu]|w[fs]|y[etu]|z[amw])$").
check_domain_name([]) -> domain_name_uncorrect;
check_domain_name(DomainName) when is_list(DomainName) ->
    case re:run(DomainName, ?DOMAIN_REGEXP) of
	{match, _} -> ok;
	nomatch -> domain_name_uncorrect
    end;
    
check_domain_name(_DomainName) -> badarg.



check_service_id([]) -> badarg;
check_service_id(ServiceId) when is_list(ServiceId) ->
    case commons:list_to_integer(ServiceId) of
	badarg -> badarg;
	_R -> ok
    end;

check_service_id(_ServiceId) -> badarg.


-define(PASSWORD_REGEXP, "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$").
check_password([]) -> password_empty;
check_password(Password) when is_list(Password) ->
    case re:run(Password, ?PASSWORD_REGEXP) of
	{match, _} -> ok;
	nomatch -> password_uncorrect
    end;

check_password(_Password) -> badarg.
