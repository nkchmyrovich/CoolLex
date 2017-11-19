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
 
/*
 *  Add Your own definitions here
 */

#define ASSERT(error_message) \
        cool_yylval.error_msg = (error_message); \
        return ERROR; 

#define STRING_OK(c) \
        if (string_buf_ptr + 1 > &string_buf[MAX_STR_CONST - 1]) { \
            BEGIN(ERROR_STRING); \
            ASSERT("String constant too long"); \
        } \
        *string_buf_ptr++ = (c); 


%}

%x INITIAL COMMENT STRING STRING_COMMENT ERROR_STRING

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
DARROW          =>
NEWLINE		[\n]
LINE_COMMENT    "--"
START_COMMENT	"(*"
END_COMMENT	"*)"
QUOTES		\"
WHITESPACE	[ \t\r\f\v]
NOTSTRING	[^\n\0\\\"]

%%

<INITIAL>{LINE_COMMENT} {
	BEGIN(STRING_COMMENT);
}

<STRING_COMMENT><<EOF>>   {
        yyterminate();
}


<STRING_COMMENT>{NEWLINE} {
	curr_lineno++;
	BEGIN(INITIAL);
} 

<INITIAL>{START_COMMENT} {
	BEGIN(COMMENT);
	comment_level++;
}

<INITIAL>{END_COMMENT} {
	ASSERT("Unmatched *)");
}

<COMMENT>{START_COMMENT} {
	comment_level++;
}

<COMMENT>{END_COMMENT} {
        comment_level--;
        if ( comment_level == 0) {
                BEGIN(INITIAL);
        }
}

<COMMENT>{NEWLINE} {
	curr_lineno++;
}

<COMMENT>[\\\n] {
	curr_lineno++;
}

<COMMENT><<EOF>> {
	BEGIN(INITIAL);
	ASSERT("EOF in comment");
}

<INITIAL>{QUOTES} {
	string_buf_ptr = string_buf;
	BEGIN(STRING);
}

<STRING>{
{QUOTES}              {
                        *string_buf_ptr = '\0';
                        BEGIN(INITIAL);
                        cool_yylval.symbol = stringtable.add_string(string_buf);
                        return STR_CONST;
                    }
\0           {
                        BEGIN(ERROR_STRING);
                        ASSERT("String contains null character");
                    }
\n              {
                        ++curr_lineno;
                        BEGIN(INITIAL);
                        ASSERT("Unterminated string constant");
                    }
<<EOF>>		{
        BEGIN(INITIAL);
        ASSERT("EOF in string constant");
}

\\b             STRING_OK('\b');
\\f             STRING_OK('\f');
\\t             STRING_OK('\t');
\\n             STRING_OK('\n');
\\\n            {
        curr_lineno++;
        STRING_OK('\n');
}
\\.             STRING_OK(yytext[1]);
[^\\\n\0\"]+    {
	if (string_buf_ptr + yyleng >&string_buf[MAX_STR_CONST - 1]) {
        	BEGIN(ERROR_STRING);
        	ASSERT("String constant too long");
        }
        strcpy(string_buf_ptr, yytext);
        string_buf_ptr += yyleng;
}
}

<ERROR_STRING>{
    \"          BEGIN(INITIAL);
    \n          {
                    ++curr_lineno;
                    BEGIN(INITIAL);
                }
    \\\n        {++curr_lineno;}`
}

"("         {return '(';}
")"         {return ')';}
"."         {return '.';}
"@"         {return '@';}
"~"         {return '~';}
"*"         {return '*';}
"/"         {return '/';}
"+"         {return '+';}
"-"         {return '-';}
"<="        {return LE;}
"<"         {return '<';}
"="         {return '=';}
"<-"        {return ASSIGN;}
"{"         {return '{';}
"}"         {return '}';}
":"         {return ':';}
","         {return ',';}
";"         {return ';';}

{DARROW}		{ return (DARROW); }
{CLASS}                 { return CLASS; }
{ELSE}                  { return ELSE; }                        
{FI}                    { return FI; }
{IF}                    { return IF; }                          
{IN}                    { return IN; }
{INHERITS}              { return INHERITS; }
{LET}                   { return LET; }
{LOOP}                  { return LOOP; }
{POOL}                  { return POOL; }
{THEN}                  { return THEN; }                        
{WHILE}                 { return WHILE; }
{CASE}                  { return CASE; }
{ESAC}                  { return ESAC; }
{NEW}                   { return NEW; }
{ISVOID}                { return ISVOID; }                      
{OF}                    { return OF; }
{NOT}                   { return NOT; }
{TRUE}                  { yylval.boolean = true; return BOOL_CONST; }
{FALSE}                 { yylval.boolean = false; return BOOL_CONST; }

<INITIAL>{TYPEID}       {  
	cool_yylval.symbol = stringtable.add_string(yytext);
        return TYPEID;
}

<INITIAL>{OBJECTID}     {
	cool_yylval.symbol = stringtable.add_string(yytext);
        return OBJECTID;
}

{DIGIT}+		{
        cool_yylval.symbol = inttable.add_string(yytext);
        return INT_CONST;
}

<INITIAL>\n             {
	++curr_lineno;
}
                        
<INITIAL>{WHITESPACE}   {}

<INITIAL>.              {ASSERT(yytext);}

%%
