-module(cbpanel_support_controller, [Req, SessionID]).
-compile([export_all]).

-include("user.hrl").

index('GET', []) ->
    {ok, []}.
