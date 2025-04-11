%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "symbol_table.h"
#include "ast.h"

extern int yylineno;
void yyerror(const char *s);
int yylex(void);

extern int enable_check;
extern ASTNode* ast_root;

ASTNode* root_node(const char* label, ASTNode* child);
ASTNode* root_seq(const char* label, ASTNode* c1, ASTNode* c2);
%}

%union {
    char* str;
    struct ASTNode* ast;
    struct Param* param;
    VarType type;
}

%token <str> ID
%token <str> INT_CONST FLOAT_CONST BOOL_CONST
%token INT FLOAT BOOL IF ELSE WHILE FOR SWITCH CASE DEFAULT BREAK PRINT READ RETURN
%token FUNC
%token EQ NEQ LEQ GEQ AND OR NOT PLUS MINUS MUL DIV MOD LT GT ASSIGN
%token SEMICOLON COMMA COLON LBRACE RBRACE LPAREN RPAREN

%type <ast> program func_decl statement statements
%type <ast> declaration assignment if_statement while_loop for_loop for_init for_update
%type <ast> switch_case case_blocks case_block print_stmt read_stmt expression
%type <param> param param_list
%type <type> type
%type <ast> return_stmt

%%

program:
    program func_decl { ast_root = create_node("Program"); add_child(ast_root, $1); add_child(ast_root, $2); }
    | func_decl       { ast_root = create_node("Program"); add_child(ast_root, $1); }
    ;

func_decl:
    type ID LPAREN param_list RPAREN LBRACE statements RBRACE
    {
        printf("Function declared: %s\n", $2);
        insert_function($2, $4, yylineno);
        $$ = root_seq("FuncDecl", create_node($2), $7);
    }
    ;

param_list:
    param_list COMMA param { $$ = append_param($1, $3); }
    | param                { $$ = create_param_list($1); }
    |                     { $$ = NULL; }
    ;

param:
    type ID {
        $$ = create_param($2, $1);
        insert_symbol($2, $1, yylineno);
    }
    ;

statements:
    statements statement { $$ = create_node("Statements"); add_child($$, $1); add_child($$, $2); }
    | statement           { $$ = create_node("Statements"); add_child($$, $1); }
    ;

statement:
      declaration
    | assignment
    | if_statement
    | while_loop
    | for_loop
    | switch_case
    | print_stmt
    | read_stmt
    | return_stmt
    ;
return_stmt:
    RETURN expression SEMICOLON
    {
        printf("Return statement\n");
        $$ = root_seq("Return", $2, NULL);
    }
    ;

declaration:
    type ID SEMICOLON
    {
        printf("Declared variable: %s\n", $2);
        if (enable_check && !insert_symbol($2, $1, yylineno))
            printf("SEMANTIC ERROR [Line %d]: Redeclaration of variable '%s'\n", yylineno, $2);
        $$ = create_node("Declaration");
        add_child($$, create_node($2));
    }
    | type ID ASSIGN expression SEMICOLON
    {
        printf("Declared + assigned variable: %s\n", $2);
        if (enable_check) {
            if (!insert_symbol($2, $1, yylineno))
                printf("SEMANTIC ERROR [Line %d]: Redeclaration of variable '%s'\n", yylineno, $2);
            else if ($1 != $4->type)
                printf("SEMANTIC ERROR [Line %d]: Type mismatch in initialization of '%s'\n", yylineno, $2);
        }
        $$ = root_seq("DeclAssign", create_node($2), $4);
    }
    ;

assignment:
    ID ASSIGN expression SEMICOLON
    {
        printf("Assignment to: %s\n", $1);
        VarType varType = get_type($1);
        if (enable_check) {
            if (!lookup_symbol($1))
                printf("SEMANTIC ERROR [Line %d]: Variable '%s' used before declaration\n", yylineno, $1);
            else if (varType != TYPE_UNKNOWN && varType != $3->type)
                printf("SEMANTIC ERROR [Line %d]: Type mismatch in assignment to '%s'\n", yylineno, $1);
        }
        $$ = root_seq("Assign", create_node($1), $3);
    }
    ;

if_statement:
    IF LPAREN expression RPAREN LBRACE statements RBRACE
        { printf("If block\n"); $$ = root_seq("If", $3, $6); }
    | IF LPAREN expression RPAREN LBRACE statements RBRACE ELSE LBRACE statements RBRACE
        { printf("If-Else block\n"); $$ = root_seq("IfElse", root_seq("If", $3, $6), $10); }
    ;

while_loop:
    WHILE LPAREN expression RPAREN LBRACE statements RBRACE
        { printf("While loop\n"); $$ = root_seq("While", $3, $6); }
    ;

for_loop:
    FOR LPAREN for_init SEMICOLON expression SEMICOLON for_update RPAREN LBRACE statements RBRACE
    {
        printf("For loop\n");
        ASTNode* header = create_node("ForHeader");
        add_child(header, $3); add_child(header, $5); add_child(header, $7);
        $$ = root_seq("For", header, $10);
    }
    ;

for_init:
    ID ASSIGN expression
    {
        printf("Assignment in for-loop: %s\n", $1);
        $$ = root_seq("ForInit", create_node($1), $3);
    }
    ;

for_update:
    ID ASSIGN expression
    {
        printf("Assignment in for-loop: %s\n", $1);
        $$ = root_seq("ForUpdate", create_node($1), $3);
    }
    ;

switch_case:
    SWITCH LPAREN ID RPAREN LBRACE case_blocks RBRACE
        { printf("Switch-case block\n"); $$ = root_seq("Switch", create_node($3), $6); }
    ;

case_blocks:
    case_blocks case_block { $$ = create_node("Cases"); add_child($$, $1); add_child($$, $2); }
    | case_block           { $$ = create_node("Cases"); add_child($$, $1); }
    ;

case_block:
    CASE INT_CONST COLON statements BREAK SEMICOLON
        { $$ = root_seq("Case", create_node($2), $4); }
    | DEFAULT COLON statements
        { $$ = root_seq("Default", create_node("default"), $3); }
    ;

print_stmt:
    PRINT LPAREN expression RPAREN SEMICOLON
        { printf("Print statement\n"); $$ = root_seq("Print", $3, NULL); }
    ;

read_stmt:
    READ LPAREN ID RPAREN SEMICOLON
    {
        printf("Read into variable: %s\n", $3);
        if (enable_check && !lookup_symbol($3))
            printf("SEMANTIC ERROR [Line %d]: Variable '%s' used before declaration\n", yylineno, $3);
        $$ = root_seq("Read", create_node($3), NULL);
    }
    ;

type:
    INT   { $$ = TYPE_INT; }
  | FLOAT { $$ = TYPE_FLOAT; }
  | BOOL  { $$ = TYPE_BOOL; }
    ;

expression:
    expression PLUS expression   { $$ = root_seq("Add", $1, $3); $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT; }
  | expression MINUS expression  { $$ = root_seq("Sub", $1, $3); $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT; }
  | expression MUL expression    { $$ = root_seq("Mul", $1, $3); $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT; }
  | expression DIV expression    { $$ = root_seq("Div", $1, $3); $$->type = TYPE_FLOAT; }
  | expression EQ expression     { $$ = root_seq("Eq", $1, $3); $$->type = TYPE_BOOL; }
  | expression NEQ expression    { $$ = root_seq("Neq", $1, $3); $$->type = TYPE_BOOL; }
  | expression LT expression     { $$ = root_seq("Lt", $1, $3); $$->type = TYPE_BOOL; }
  | expression GT expression     { $$ = root_seq("Gt", $1, $3); $$->type = TYPE_BOOL; }
  | expression AND expression    { $$ = root_seq("And", $1, $3); $$->type = TYPE_BOOL; }
  | expression OR expression     { $$ = root_seq("Or", $1, $3); $$->type = TYPE_BOOL; }
  | NOT expression               { $$ = root_node("Not", $2); $$->type = TYPE_BOOL; }
  | LPAREN expression RPAREN     { $$ = $2; }
  | ID {
        if (enable_check && !lookup_symbol($1))
            printf("SEMANTIC ERROR [Line %d]: Variable '%s' used before declaration\n", yylineno, $1);
        $$ = create_node($1);
        $$->type = get_type($1);
    }
  | INT_CONST {
        char label[128]; sprintf(label, "INT: %s", $1);
        $$ = create_node(label);
        $$->type = TYPE_INT;
    }
  | FLOAT_CONST {
        char label[128]; sprintf(label, "FLOAT: %s", $1);
        $$ = create_node(label);
        $$->type = TYPE_FLOAT;
    }
  | BOOL_CONST {
        char label[128]; sprintf(label, "BOOL: %s", $1);
        $$ = create_node(label);
        $$->type = TYPE_BOOL;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}

ASTNode* root_node(const char* label, ASTNode* child) {
    ASTNode* node = create_node(label);
    if (child) add_child(node, child);
    return node;
}

ASTNode* root_seq(const char* label, ASTNode* c1, ASTNode* c2) {
    ASTNode* node = create_node(label);
    if (c1) add_child(node, c1);
    if (c2) add_child(node, c2);
    return node;
}
