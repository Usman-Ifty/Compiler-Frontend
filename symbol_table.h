#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef enum { TYPE_UNKNOWN = -1, TYPE_INT, TYPE_FLOAT, TYPE_BOOL } VarType;

typedef struct Symbol {
    char* name;
    VarType type;
    int line;
    struct Symbol* next;
} Symbol;

typedef struct Param {
    char* name;
    VarType type;
    struct Param* next;
} Param;

void init_symbol_table();
int insert_symbol(const char* name, VarType type, int line);
int lookup_symbol(const char* name);
VarType get_type(const char* name);
void free_symbol_table();

Param* create_param(const char* name, VarType type);
Param* create_param_list(Param* p);
Param* append_param(Param* head, Param* new_param);

void insert_function(const char* name, Param* params, int line);
int check_function_call(const char* name, Param* args, int line);

#endif
