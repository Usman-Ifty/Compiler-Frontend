#include <stdio.h>
#include <string.h>
#include "symbol_table.h"
#include "ast.h"

int yyparse(void);
int yylex(void);
extern int yylineno;
extern char* yytext;

int enable_tokens = 0;
int enable_check = 0;
int enable_ast = 0;

ASTNode* ast_root = NULL;

int main(int argc, char** argv) {
    printf("Starting Compiler...\n");

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--tokens") == 0) enable_tokens = 1;
        if (strcmp(argv[i], "--check") == 0) enable_check = 1;
        if (strcmp(argv[i], "--ast") == 0) enable_ast = 1;
    }

    if (enable_tokens) {
        int token;
        while ((token = yylex()) != 0) {
            printf("[Line %d] Token: %s\n", yylineno, yytext);
        }
    } else {
        if (enable_check) init_symbol_table();
        yyparse();

        if (enable_ast && ast_root) {
            generate_dot(ast_root, "ast.dot");
            printf("AST written to ast.dot\n");
        }

        if (enable_check) free_symbol_table();
        if (ast_root) free_ast(ast_root);
    }

    printf("Compilation Finished.\n");
    return 0;
}
