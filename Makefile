generateTemp: analyzer.l parser.y
	lex analyzer.l
	yacc -d parser.y 
	yacc parser.y -o gm.cc
	cc -c lex.yy.c -o lex.yy.o
	g++ lex.yy.o gm.cc symbolTable.cpp -o genTemp
	rm gm.cc lex.yy.c y.tab.h lex.yy.o y.tab.c
#after this a genTemp executable file will be generated type ./genTemp SamplePrograms/0hello.cnp (give file name to execute) in which output is stored in file.temp file.
generateAssembly: tempToAssembly.cpp
	g++ tempToAssembly.cpp -o genMips

clean:
	rm genTemp genMips

clear:
	rm file.temp machine.asm

