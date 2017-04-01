%%%---------------------------------------------------------------------------

Header
  "%%% @private"
.

Nonterminals
  toml
  root_section section_list
  section section_name section_body
  key value string datetime
  array value_list nls nls_comma
  inline_table inline_kv_list
.

Terminals
  '[[' ']]' '[' ']' '{' '}'
  '.' '=' ','
  nl
  datetime_tz local_datetime local_date local_time
  bool float plus_integer integer bare_key
  basic_string literal_string
  basic_string_ml literal_string_ml
.

Rootsymbol toml.

%%%---------------------------------------------------------------------------

% TODO: change semantic values
toml -> root_section              : {'$1', []}.
toml -> root_section section_list : {'$1', lists:reverse('$2')}.
toml ->              section_list : {[],   lists:reverse('$1')}.

root_section -> section_body : lists:reverse('$1').

section_list -> section : ['$1'].
section_list -> section_list section : ['$2' | '$1'].

%%----------------------------------------------------------
%% sections (a.k.a. tables)

section -> '['  section_name ']'  nl section_body :
  {table, lists:reverse('$2'), lists:reverse('$5')}.
section -> '[[' section_name ']]' nl section_body :
  {array_table, lists:reverse('$2'), lists:reverse('$5')}.

section_name -> key : ['$1'].
section_name -> section_name '.' key : ['$3' | '$1'].

section_body -> nl : [].
section_body -> key '=' value nl : [{'$1', '$3'}].
section_body -> section_body nl : '$1'.
section_body -> section_body key '=' value nl : [{'$2', '$4'} | '$1'].

%%----------------------------------------------------------

key -> basic_string : value('$1').
key -> bare_key     : value('$1').
key -> bool         : atom_to_list(value('$1')).
key -> integer      : value('$1', raw).
key -> local_date   : value('$1', raw).

%%----------------------------------------------------------

value -> string   : '$1'.
value -> plus_integer : value('$1').
value -> integer  : value('$1', parsed).
value -> float    : value('$1').
value -> bool     : value('$1').
value -> datetime : '$1'.
value -> array    : '$1'.
value -> inline_table : '$1'.

string -> basic_string      : value('$1').
string -> basic_string_ml   : value('$1').
string -> literal_string    : value('$1').
string -> literal_string_ml : value('$1').

datetime -> datetime_tz    : {datetime, element(1, value('$1')), element(2, value('$1'))}.
datetime -> local_datetime : {datetime, value('$1')}.
datetime -> local_date     : {date, value('$1', parsed)}.
datetime -> local_time     : {time, value('$1')}.

%%----------------------------------------------------------

array -> '['     ']' : {array, []}.
array -> '[' nls ']' : {array, []}.

array -> '['     value_list           ']' : {array, lists:reverse('$2')}.
array -> '['     value_list nls       ']' : {array, lists:reverse('$2')}.
array -> '['     value_list nls_comma ']' : {array, lists:reverse('$2')}.
array -> '[' nls value_list           ']' : {array, lists:reverse('$3')}.
array -> '[' nls value_list nls       ']' : {array, lists:reverse('$3')}.
array -> '[' nls value_list nls_comma ']' : {array, lists:reverse('$3')}.

value_list -> value : ['$1'].
value_list -> value_list nls_comma value : ['$3' | '$1'].

nls_comma -> ','.
nls_comma -> ',' nls.
nls_comma -> nls ','.
nls_comma -> nls ',' nls.

nls -> nl.
nls -> nls nl.

%%----------------------------------------------------------

inline_table -> '{' '}' : {table, []}.
inline_table -> '{' inline_kv_list '}' : {table, lists:reverse('$2')}.

% NOTE: as per spec and reference grammar, trailing comma is not allowed
inline_kv_list -> key '=' value : [{'$1', '$3'}].
inline_kv_list -> inline_kv_list ',' key '=' value : [{'$3', '$5'} | '$1'].

%%----------------------------------------------------------

%%%---------------------------------------------------------------------------

Erlang code.

value({_TermName, _Line, {RawValue, _ParsedValue}}, raw = _Element) ->
  RawValue;
value({_TermName, _Line, {_RawValue, ParsedValue}}, parsed = _Element) ->
  ParsedValue.

value({_TermName, _Line, Value}) ->
  Value.

%%%---------------------------------------------------------------------------
%%% vim:ft=erlang
