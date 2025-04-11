%option yylineno

%{
#include "symbol_table.h"  // ✅ MUST come first so VarType is known
#include "parser.h"
#include <stdio.h>
#include <string.h>
%}


%%
"int"       { return INT; }
"float"     { return FLOAT; }
"bool"      { return BOOL; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"switch"    { return SWITCH; }
"case"      { return CASE; }
"default"   { return DEFAULT; }
"break"     { return BREAK; }
"print"     { return PRINT; }
"read"      { return READ; }
"return"    { return RETURN; }
"func"     { return FUNC; }

"true"|"false"    { yylval.str = strdup(yytext); return BOOL_CONST; }

[0-9]+"."[0-9]+   { yylval.str = strdup(yytext); return FLOAT_CONST; }
[0-9]+            { yylval.str = strdup(yytext); return INT_CONST; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return ID;
}

"=="    { return EQ; }
"!="    { return NEQ; }
"<="    { return LEQ; }
">="    { return GEQ; }
"&&"    { return AND; }
"||"    { return OR; }
"!"     { return NOT; }
"+"     { return PLUS; }
"-"     { return MINUS; }
"*"     { return MUL; }
"/"     { return DIV; }
"%"     { return MOD; }
"<"     { return LT; }
">"     { return GT; }
"="     { return ASSIGN; }
";"     { return SEMICOLON; }
","     { return COMMA; }
":"     { return COLON; }          // ✅ Added this line
"{"     { return LBRACE; }
"}"     { return RBRACE; }
"("     { return LPAREN; }
")"     { return RPAREN; }

[ \t\r]+    ;       // Ignore spaces/tabs
\n          ;       // Newlines auto-increment yylineno
"//".*      ;       // Single-line comments
"/*"([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*"*"+"/" ;

.           { printf("Lexical Error at line %d: Unknown token '%s'\n", yylineno, yytext); }

%%
int yywrap() {
    return 1;
}
