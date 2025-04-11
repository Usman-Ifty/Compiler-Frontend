#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Symbol* table = NULL;

int insert_symbol(const char* name, VarType type, int line) {
    if (lookup_symbol(name)) return 0;
    Symbol* sym = malloc(sizeof(Symbol));
    sym->name = strdup(name);
    sym->type = type;
    sym->line = line;
    sym->next = table;
    table = sym;
    return 1;
}

int lookup_symbol(const char* name) {
    for (Symbol* s = table; s; s = s->next)
        if (strcmp(s->name, name) == 0) return 1;
    return 0;
}

VarType get_type(const char* name) {
    for (Symbol* s = table; s; s = s->next)
        if (strcmp(s->name, name) == 0) return s->type;
    return TYPE_UNKNOWN;
}

void init_symbol_table() {
    table = NULL;
}

void free_symbol_table() {
    while (table) {
        Symbol* tmp = table;
        table = table->next;
        free(tmp->name);
        free(tmp);
    }
}

typedef struct Function {
    char* name;
    Param* params;
    int param_count;
    int line;
    struct Function* next;
} Function;

static Function* functions = NULL;

Param* create_param(const char* name, VarType type) {
    Param* p = malloc(sizeof(Param));
    p->name = strdup(name);
    p->type = type;
    p->next = NULL;
    return p;
}

Param* create_param_list(Param* p) {
    return p;
}

Param* append_param(Param* head, Param* new_param) {
    if (!head) return new_param;
    Param* temp = head;
    while (temp->next) temp = temp->next;
    temp->next = new_param;
    return head;
}

void insert_function(const char* name, Param* params, int line) {
    Function* fn = malloc(sizeof(Function));
    fn->name = strdup(name);
    fn->params = params;
    fn->line = line;
    fn->param_count = 0;
    for (Param* p = params; p; p = p->next) fn->param_count++;
    fn->next = functions;
    functions = fn;
}

int check_function_call(const char* name, Param* args, int line) {
    for (Function* f = functions; f; f = f->next) {
        if (strcmp(f->name, name) == 0) {
            Param* p = f->params;
            Param* a = args;
            while (p && a) {
                if (p->type != a->type) {
                    printf("SEMANTIC ERROR [Line %d]: Type mismatch in call to function '%s'\n", line, name);
                    return 0;
                }
                p = p->next;
                a = a->next;
            }
            if (p || a) {
                printf("SEMANTIC ERROR [Line %d]: Incorrect number of arguments to '%s'\n", line, name);
                return 0;
            }
            return 1;
        }
    }
    printf("SEMANTIC ERROR [Line %d]: Function '%s' not declared\n", line, name);
    return 0;
}
