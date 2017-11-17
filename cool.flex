/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

unsigned int comment_level = 0;
unsigned int string_buf_left;
bool string_error;
 
/*
 *  Add Your own definitions here
 */

%}

CLASS           ?i:class
ELSE            ?i:else
IF              ?i:if
FI              ?i:fi
IN              ?i:in
INHERITS        ?i:inherits
LET             ?i:let
LOOP            ?i:loop
POOL            ?i:poot
THEN            ?i:then
WHILE           ?i:while
CASE            ?i:case
ESAC            ?i:esac
OF              ?i:of
NEW             ?i:new
ISVOID          ?i:isvoid
NOT		?i:not
TRUE		t[Rr][Uu][Ee]
FALSE		f[Aa][Ll][Ss][Ee]
OBJECTID	[a-z][a-zA-Z0-9_]*
TYPEID		[A-Z][a-zA-Z0-9_]*
DIGIT		[0-9]
CHAR		[a-zA-Z]
WHITESPACE	[ \f\t\r\v]
DARROW          =>

STRING_COMMENT	"--"
START_COMMENT	"(*"
END_COMMENT	"*)"
QUOTES		\"
WHITESPACE	[ \t\r\f\v]+
NOTSTRING	[^\n\0\\\"]+

%xINITIAL COMMENT STRING STRING_COMMENT ERROR_STRING

%%

<INITIAL>-- {
	BEGIN(STRING_COMMENT);
}

<STRING_COMMENT><<<EOF>> {
	yyterminate();
}

<STRING_COMMENT>[\n] {
	curr_lineno++;
	BEGIN(INITIAL);
} 
	

<INITIAL>{START_COMMENT} {
	comment_level++;
	BEGIN(COMMENT);
}

<COMMENT>{START_COMMENT} {
	comment_level++;
}

<COMMENT>[\n] {
	curr_luneno++;
	BEGIN<COMMENT>;
}

<COMMENT><<EOF>> {
	yylval.error_msg = "EOF in comment";
	BEGIN(INITIAL);
	return ERROR;
}

<COMMENT>{END_COMMENT} {
	comment_level--;
	if ( comment_level == 0)
		BEGIN(INITIAL);
}

<INITIAL>{END_COMMENT} {
	yylval.error_msg = "Unmatched *)";
	return ERROR;
}

<INITIAL>{QUOTES} {
	BEGIN(STRING);
	string_buf_ptr = string_buf;
	string_buf_left = MAX_STR_CONST;
}

<STRING><<EOF>> {
	yylval.error_msg = "EOF in string constant";
	BEGIN(INITIAL);
	return ERROR;
}

<STRING>{
\\?\0		{
	*string_buf_ptr = '\0';
	BEGIN(INITIAL);
	cool_yylval.symbol = stringtable.add_string(string_buf);
	return STR_CONST;
}
\n		{
	curr_lineno++;
	BEGIN(INITIAL);
	yylval.error_msg = "Unterminated string constant";
	return ERROR;
}
<<EOF>>		{
	BEGIN(INITIAL);
	yylval.error_msg = "EOF in string constant";
	return ERROR;
}
\\b
\\f
\\t
\\n
\\\n
\\?\0		{
	BEGIN(ERROR_STRING);
	yylval.error_msg = "String contains null character";
	return ERROR;
}
NOTSTRING	{
	if ( string_buf_ptr + yyleng > &string_buf[MAX_STR_CONST - 1]) {
		BEGIN(ERROR_STRING);
		yylval.error_msg = "String constant is too long";
		return ERROR;
	}
	strcpy(string_buf_ptr, yy_text);
	string_buf_ptr += yyleng;
}
}


<ERROR_STRING>{
\"		BEGIN(INITIAL);
\n		{
			curr_lineno++;
			BEGIN(INITIAL);
		}
\\\n		{ curr_lineno++;}
}



 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
