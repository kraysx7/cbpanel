-module(tabs).
-author("Ilya Troshkov").

-export([get_tabs/0, get_tab_id/1]).

%%%===================================================================
%%% API
%%%===================================================================

get_tabs()->
    [
      [{tab_id, 0}, {tab_img_class, "i-data"},       {tab_href, "/panel/profile"},          {tab_title, get_bin_from_string("Сводная информация")}],
      [{tab_id, 1}, {tab_img_class, "i-webhosting"}, {tab_href, "/panel/webhosting"},       {tab_title, get_bin_from_string("Хостинг web-сайтов")}],
      [{tab_id, 2}, {tab_img_class, "i-virmach"},    {tab_href, "/panel/vps"},              {tab_title, get_bin_from_string("Виртуальные серверы")}],
      [{tab_id, 3}, {tab_img_class, "i-mon"},        {tab_href, "/panel/monitoring"},       {tab_title, get_bin_from_string("События и мониторинг")}],
      [{tab_id, 4}, {tab_img_class, "i-settings"},   {tab_href, "/panel/profile/edit"},     {tab_title, get_bin_from_string("Настройки аккаунта")}],
      [{tab_id, 5}, {tab_img_class, "i-finance"},    {tab_href, "/panel/profile/finances"}, {tab_title, get_bin_from_string("Финансы")}],
      [{tab_id, 6}, {tab_img_class, "i-support"},    {tab_href, "/panel/support"},          {tab_title, get_bin_from_string("Поддержка")}]
    ].


get_tab_id(Path) ->
    Tabs = get_tabs(),
    case get_tab(Path, Tabs) of
	not_found -> -1;
	Tab -> proplists:get_value(tab_id, Tab)
    end.


%%%===================================================================
%%% Internal functions
%%%===================================================================

get_tab(Path, []) -> not_found;
get_tab(Path, [Tab | Other]) ->
    TabPath = proplists:get_value(tab_href, Tab),
    case TabPath of
	Path -> Tab;
	_ -> get_tab(Path, Other)
    end.
 
get_bin_from_string(String) when is_list(String)->
    unicode:characters_to_binary(String, utf8).
