#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

static int node_counter = 0;

// Create a new AST node with a label
ASTNode* create_node(const char* label) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    if (!node) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    snprintf(node->label, sizeof(node->label), "%s", label);
    node->type = TYPE_UNKNOWN;
    node->child = NULL;
    node->sibling = NULL;
    return node;
}

// Add a child node to the parent (linked-list style)
void add_child(ASTNode* parent, ASTNode* child) {
    if (!parent || !child) return;

    if (!parent->child) {
        parent->child = child;
    } else {
        ASTNode* curr = parent->child;
        while (curr->sibling) {
            curr = curr->sibling;
        }
        curr->sibling = child;
    }
}

// Print AST with indentation
void print_ast(ASTNode* root, FILE* fp) {
    static int indent = 0;
    if (!root) return;

    for (int i = 0; i < indent; i++) fprintf(fp, "  ");
    fprintf(fp, "%s\n", root->label);

    indent++;
    for (ASTNode* child = root->child; child; child = child->sibling) {
        print_ast(child, fp);
    }
    indent--;
}

// Recursively generate DOT for Graphviz
void generate_dot_node(FILE* fp, ASTNode* node, int* id) {
    if (!node) return;

    int this_id = (*id)++;
    fprintf(fp, "  node%d [label=\"%s\"];\n", this_id, node->label);

    for (ASTNode* child = node->child; child; child = child->sibling) {
        int child_id = *id;
        generate_dot_node(fp, child, id);
        fprintf(fp, "  node%d -> node%d;\n", this_id, child_id);
    }
}

// Generate DOT file for entire AST
void generate_dot(ASTNode* root, const char* filename) {
    FILE* fp = fopen(filename, "w");
    if (!fp) {
        perror("fopen");
        return;
    }

    fprintf(fp, "digraph AST {\n");
    int id = 0;
    generate_dot_node(fp, root, &id);
    fprintf(fp, "}\n");
    fclose(fp);
}

// Free AST recursively
void free_ast(ASTNode* node) {
    if (!node) return;

    free_ast(node->child);
    free_ast(node->sibling);
    free(node);
}
