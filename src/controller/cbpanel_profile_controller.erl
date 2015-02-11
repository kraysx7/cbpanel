-module(cbpanel_profile_controller, [Req, SessionID]).
-compile([export_all]).

-include("user.hrl").
-include("service.hrl").
-include("user_service.hrl").

-define(VPS_SERVICES_TYPE, 2).

index('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
	    %% lists:foreach(fun(Tab) -> io:format("Tab: ~p~n",[Tab]) end, Tabs),
		    {ok, [
			  {active_tab, tabs:get_tab_id(Req:path())}, {tabs, tabs:get_tabs()},
			  {user_data, [{name, UserData#user.name}, {balance, UserData#user.balance}]}
			 ] 
		    };
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end.

edit('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
		    {ok, [
			  {active_tab, tabs:get_tab_id(Req:path())}, {tabs, tabs:get_tabs()},
			  {user_data, [{name, UserData#user.name}, {balance, UserData#user.balance}]}
			 ] 
		    };
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end.

finances('GET', []) ->
    %% проверка сессии
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
		    {ok, [
			  {active_tab, tabs:get_tab_id(Req:path())}, {tabs, tabs:get_tabs()},
			  {user_data, [{name, UserData#user.name}, {balance, UserData#user.balance}]}
			 ] 
		    };
	{error, not_logined} ->  {redirect, "/login"};
	{sys_error, Reason} -> {redirect, "/login"}
    end.
 

orders('GET', []) ->
    {ok, [{services, empty}]}.

%% оформление заказа ШАГ 1.
%% Получаем данные о сервисе и обновляем информацию в сеcсии
create_order('GET', [ServiceId]) ->
    %% получить данные о сервисе
    case db_api:get_service(ServiceId) of
	{ok, OrderedService} ->
	    io:format("OrderedService: ~p~n", [OrderedService]),
	    %% сохранить в данных сессии информацию о выбранном сервисе
	    boss_session:set_session_data(SessionID, "ordered_service", OrderedService),
	    %% указать в данных сессии следующий шаг оформления заказа
	    boss_session:set_session_data(SessionID, "order_next_step", 2),
	    %% перейти к слудующему шагу
	    {redirect, "/create_order"};
	_ -> {ok, []}
    end;

%% Хэндлеры для страниц оформления заказа

create_order('GET', []) ->
    %% Получить текущий шаг оформления заказа
    case get_order_step() of
	OrderStep ->
	    create_order_handler(OrderStep);
	{error, step_error} ->  {redirect, "/"};
	{sys_error, Reason} -> {redirect, "/login"}		   
    end.

%% оформление заказа ШАГ 2.
create_order_handler(_Step = 2) ->
    io:format("Create Order Step: 2~n"),
    %% проверка авторизации
    case commons:is_logined(SessionID) of
	{ok, UserData} ->
	    %% получить данные о заказе из данных сессии
	    %% если данных нет, или id сервиса не совпадает с id из запроса - то перейти к шагу 1
	    ServiceData = [],
	    {ok, [{service, ServiceData}]};
	{error, not_logined} -> 
	    %% добавить экземпляр заказа в данные сессии
	    %% перенаправить на страницу логина
	    {redirect, "/login?reason=1"};
	{sys_error, Reason} -> {redirect, "/login"}
    end;


create_order_handler(_Step = 3) ->
    io:format("Create Order step 3~n").    


%% ######## INTERNAL FUNCTIONS #######

get_order_step() ->
     case boss_session:get_session_data(SessionID, "order_step") of
	 Step when is_integer(Step) -> Step;
	 undefined -> {error, step_error};
	 {error, Reason} -> {sys_error, Reason};
	 _ -> {sys_error, session_data_corrupt}
     end.
