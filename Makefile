generateTemp: analyzer.l parser.y
	lex analyzer.l
	yacc -d parser.y 
	yacc parser.y -o gm.cc
	cc -c lex.yy.c -o lex.yy.o
	g++ lex.yy.o gm.cc symbolTable.cpp -o genTemp
	rm gm.cc lex.yy.c y.tab.h lex.yy.o y.tab.c

generateAssembly: tempToAssembly.cpp
	g++ tempToAssembly.cpp -o genMips

clean:
	rm genTemp genMips

clear:
	rm file.temp machine.asm

