// ast.h
#ifndef AST_H
#define AST_H

#include <stdio.h>
#include "symbol_table.h"  // ✅ So VarType is shared

typedef struct ASTNode {
    char label[128];
    VarType type;               // ✅ Uses shared enum
    struct ASTNode* child;
    struct ASTNode* sibling;
} ASTNode;

ASTNode* create_node(const char* label);
void add_child(ASTNode* parent, ASTNode* child);
void print_ast(ASTNode* root, FILE* fp);
void generate_dot(ASTNode* root, const char* filename);
void free_ast(ASTNode* node);

#endif
