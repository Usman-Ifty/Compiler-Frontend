CC=gcc
LEX=flex
YACC=bison -d

all: compiler

compiler: parser.o lexer.o main.o ast.o symbol_table.o
	$(CC) -o compiler parser.o lexer.o main.o ast.o symbol_table.o

parser.o: parser.c parser.h
	$(CC) -c parser.c

parser.c parser.h: parser.y
	$(YACC) -o parser.c parser.y

lexer.o: lexer.c
	$(CC) -c lexer.c

lexer.c: lexer.l
	$(LEX) -o lexer.c lexer.l

main.o: main.c
	$(CC) -c main.c

ast.o: ast.c
	$(CC) -c ast.c

symbol_table.o: symbol_table.c
	$(CC) -c symbol_table.c

clean:
	rm -f *.o compiler parser parser.tab.* lexer.c ast.dot
