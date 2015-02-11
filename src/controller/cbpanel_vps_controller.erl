-module(cbpanel_vps_controller, [Req, SessionID]).
-compile([export_all]).

-include("user.hrl").

index('GET', []) ->
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
