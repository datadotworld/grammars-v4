parser grammar PowerQueryParser;
options {
	tokenVocab = PowerQueryLexer;
}
document: section_document | expression_document;
section_document: section;

required_field_with_space_selector: IDENTIFIER_WITH_SPACE;
section:
	literal_attribs? SECTION section_name SEMICOLON section_members?;
section_name: IDENTIFIER;
section_members: section_member section_members?;
section_member:
	literal_attribs? SHARED? section_member_name EQUALS expression SEMICOLON;
section_member_name: IDENTIFIER;

// Note for the left recursion in this file: antlr is ok with direct left recursion and apparently converts it to non-recursive,
// but not ok with indirect left recursion, and right recursion may be a performance issue sometimes
expression_document: expression;
expression:
	arithmetic_expression
	| each_expression
	| function_expression
	| let_expression
	| if_expression
	| error_raising_expression
	| error_handling_expression;

nullable_primitive_type: NULLABLE? primitive_type;

// combining these because we don't care about evaluating the individual expressions for our purposes
arithmetic_expression:
	base_expression
	| arithmetic_expression (IS | AS) nullable_primitive_type
	| arithmetic_expression (OR | AND | EQUALS | NEQ | LE | GE | LEQ | GEQ | PLUS | MINUS | SLASH | STAR | AMP | META) base_expression
	;

base_expression:
    primary_expression
	| type_expression
	| (PLUS | MINUS | NOT) base_expression
	;

primary_expression:
	literal_expression
	| list_expression
	| record_expression
	| identifier_expression
	| section_access_expression
	| parenthesized_expression
	| implicit_target_field_selection
	| projection //field_access_expression
	| primary_expression (field_selector | projection | (OPEN_BRACE expression CLOSE_BRACE OPTIONAL?) | (OPEN_PAREN argument_list? CLOSE_PAREN) ) // projection, item_access_expression, invoke_expression
	| inner_function
	| not_implemented_expression;

literal_expression: LITERAL;
identifier_expression: identifier_reference;
identifier_reference: AT? IDENTIFIER;

section_access_expression: IDENTIFIER BANG IDENTIFIER;

parenthesized_expression: OPEN_PAREN expression CLOSE_PAREN;
not_implemented_expression: ELLIPSES;
argument_list: expression (COMMA expression)*?;
list_expression: OPEN_BRACE item_list? CLOSE_BRACE;
item_list: item (COMMA item)*?;
item: expression ( DOTDOT expression)*?;

record_expression: OPEN_BRACKET field_list? CLOSE_BRACKET;
field_list: field (COMMA field)*?;
field: field_name EQUALS expression;
field_name: IDENTIFIER;
item_selector: expression;

field_selector:
	required_field_selector OPTIONAL?
	| required_field_with_space_selector;
required_field_selector: OPEN_BRACKET field_name CLOSE_BRACKET;
implicit_target_field_selection: field_selector;
projection:
	OPEN_BRACKET required_selector_list CLOSE_BRACKET OPTIONAL?;

required_selector_list:
	required_field_selector (COMMA required_field_selector)*?;

function_expression:
	OPEN_PAREN parameter_list? CLOSE_PAREN return_type? '=>' function_body;
function_body: expression;
// initial grammar doesn't handle examples like #duration here: "if [#"days difference "] >= #duration(0, 0, 0, 0) then ..."
inner_function:
    ESCAPE_ESCAPE primitive_type OPEN_PAREN literal_item_list CLOSE_PAREN ;

parameter_list:
	fixed_parameter_list (COMMA optional_parameter_list)*?;
fixed_parameter_list:
	parameter (COMMA parameter)*?;
parameter: parameter_name parameter_type?;
parameter_name: IDENTIFIER;
parameter_type: assertion;
return_type: assertion;
assertion: AS nullable_primitive_type;
optional_parameter_list:
	optional_parameter (COMMA optional_parameter)*?;
optional_parameter: OPTIONAL_TEXT parameter;

each_expression: EACH each_expression_body;
each_expression_body: function_body;

let_expression: LET field_list IN expression;

if_expression:
	IF expression THEN expression ELSE expression;

type_expression: TYPE primary_type;
type_expr: parenthesized_expression | primary_type;
primary_type:
	primitive_type
	| record_type
	| list_type
	| function_type
	| table_type
	| nullable_type;
primitive_type:
	ANY
	| ANYNONNULL
	| BINARY
	| DATE
	| DATETIME
	| DATETIMEZONE
	| DURATION
	| FUNCTION
	| LIST
	| LOGICAL
	| NONE
	| NUMBER
	| RECORD
	| TABLE
	| TEXT
	| TYPE
	| LITERAL;
record_type:
	OPEN_BRACKET open_record_marker CLOSE_BRACKET
	| OPEN_BRACKET field_specification_list? CLOSE_BRACKET
	| OPEN_BRACKET field_specification_list COMMA open_record_marker CLOSE_BRACKET;
field_specification_list:
	field_specification (COMMA field_specification)*?;
field_specification:
	OPTIONAL_TEXT? field_name field_type_specification?;
field_type_specification: EQUALS field_type;
field_type: type_expr;
open_record_marker: ELLIPSES;
list_type: OPEN_BRACE item_type CLOSE_BRACE;
item_type: type_expr;
function_type:
	FUNCTION_START parameter_specification_list? CLOSE_PAREN return_type;
parameter_specification_list:
	required_parameter_specification_list
	| required_parameter_specification_list COMMA optional_parameter_specification_list
	| optional_parameter_specification_list;
required_parameter_specification_list:
	required_parameter_specification
	| required_parameter_specification COMMA required_parameter_specification_list;
required_parameter_specification: parameter_specification;
optional_parameter_specification_list:
	optional_parameter_specification
	| optional_parameter_specification COMMA optional_parameter_specification_list;
optional_parameter_specification:
	OPTIONAL_TEXT parameter_specification;
parameter_specification: parameter_name parameter_type;
table_type: TABLE row_type;
row_type: OPEN_BRACKET field_specification_list CLOSE_BRACKET;
nullable_type: NULLABLE type_expr;

error_raising_expression: ERROR expression;
error_handling_expression:
	TRY protected_expression otherwise_clause?;
protected_expression: expression;
otherwise_clause: OTHERWISE default_expression;
default_expression: expression;

literal_attribs: record_literal;
record_literal: OPEN_BRACKET literal_field_list? CLOSE_BRACKET;
literal_field_list:
	literal_field (COMMA literal_field)*?;
literal_field: field_name EQUALS any_literal;
list_literal: OPEN_BRACE literal_item_list? CLOSE_BRACE;
literal_item_list:
	any_literal (COMMA any_literal)*?;
any_literal: record_literal | list_literal | LITERAL;
