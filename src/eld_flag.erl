%%%-------------------------------------------------------------------
%%% @doc Flag data type
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(eld_flag).

%% API
-export([new/2]).
-export([get_variation/2]).

%% Types
-type flag() :: #{
    debug_events_until_date => pos_integer() | undefined,
    deleted                 => boolean(),
    fallthrough             => variation_or_rollout(),
    key                     => key(),
    off_variation           => variation(),
    on                      => boolean(),
    prerequisites           => [prerequisite()],
    rules                   => [eld_rule:rule()],
    salt                    => binary(),
    sel                     => binary(),
    targets                 => [target()],
    track_events            => boolean(),
    variations              => [variation_value()],
    version                 => pos_integer()
}.

-type key() :: binary().
%% Flag key

-type variation() :: non_neg_integer().
%% Variation index

-type variation_or_rollout() :: variation() | rollout().
%% Contains either the fixed variation or percent rollout to serve

-type rollout() :: #{
    variations => [weighted_variation()],
    bucket_by  => binary() | undefined
}.
%% Describes how users will be bucketed into variations during a percentage rollout

-type weighted_variation() :: #{
    variation => variation(),
    weight    => non_neg_integer() % 0 to 100000
}.
%% Describes a fraction of users who will receive a specific variation

-type prerequisite() :: #{
    key       => key(),
    variation => variation()
}.
%% Describes a requirement that another feature flag return a specific variation

-type target() :: #{
    values    => [eld_user:key()],
    variation => variation()
}.
%% Describes a set of users who will receive a specific variation

-type variation_value() ::
    boolean()
    | integer()
    | float()
    | binary()
    | list()
    | map().

-export_type([flag/0]).
-export_type([key/0]).
-export_type([prerequisite/0]).
-export_type([target/0]).
-export_type([variation/0]).
-export_type([variation_or_rollout/0]).
-export_type([variation_value/0]).

%%%===================================================================
%%% API
%%%===================================================================

-spec new(Key :: eld_flag:key(), Properties :: map()) -> flag().
new(Key, #{
    <<"debugEventsUntilDate">> := DebugEventsUntilDate,
    <<"deleted">>              := Deleted,
    <<"fallthrough">>          := Fallthrough,
    <<"key">>                  := Key,
    <<"offVariation">>         := OffVariation,
    <<"on">>                   := On,
    <<"prerequisites">>        := Prerequisites,
    <<"rules">>                := Rules,
    <<"salt">>                 := Salt,
    <<"sel">>                  := Sel,
    <<"targets">>              := Targets,
    <<"trackEvents">>          := TrackEvents,
    <<"variations">>           := Variations,
    <<"version">>              := Version
}) ->
    #{
        debug_events_until_date => DebugEventsUntilDate,
        deleted                 => Deleted,
        fallthrough             => Fallthrough,
        key                     => Key,
        off_variation           => OffVariation,
        on                      => On,
        prerequisites           => parse_prerequisites(Prerequisites),
        rules                   => Rules,
        salt                    => Salt,
        sel                     => Sel,
        targets                 => parse_targets(Targets),
        track_events            => TrackEvents,
        variations              => Variations,
        version                 => Version
    }.

-spec get_variation(Flag :: flag(), VariationIndex :: non_neg_integer()) -> term().
get_variation(#{variations := Variations}, VariationIndex) ->
    lists:nth(VariationIndex + 1, Variations).

%%%===================================================================
%%% Internal functions
%%%===================================================================

-spec parse_prerequisites([map()]) -> [prerequisite()].
parse_prerequisites(Prerequisites) ->
    F = fun(#{<<"key">> := Key, <<"variation">> := Variation}) ->
            #{key => Key, variation => Variation}
        end,
    lists:map(F, Prerequisites).

-spec parse_targets([binary()]) -> [target()].
parse_targets(Targets) ->
    F = fun(#{<<"values">> := Values, <<"variation">> := Variation}) ->
        #{values => Values, variation => Variation}
        end,
    lists:map(F, Targets).
