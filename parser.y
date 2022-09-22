%{
#include<fstream>
#include<stdio.h>
#include<string.h>
#include<iostream>
#include<unordered_map>
#include<vector>
#include<stack>
#include<unistd.h>
#include"symbolTable.h"

using namespace std; 
extern FILE* yyin;

extern int DEBUG;		//to print information about tokeninzing
int parseDebug = 0;		//to print information about parsing
int symbolDebug = 0;	//print the symbol table.

extern int yylineno;

extern "C"
{
	int yyparse(void);
	int yylex(void);
	void yyerror(const char* s)
	{
		printf("%s at line: %d\n", s, yylineno);
		return;
	}
	int yywrap()
	{
		return 1; 
	} 
}
%}
%union
{
	char* str;		//used for returning the identifiers from the lexer.
	int intval;

	struct			//used by grammar symbols that evaluate to expressions.
	{
		char* type;
		char* addr;
	} var;

	struct			//used by grammar symbols that deal with array references.
	{
		char* type;
		char* addr;
		int arr;
		int level;
		char* index;
		int completed;
	} array;
};

%token BREAK CHAR CONST CONTINUE ELSE ELIF FLOAT FOR IN IF INT RETURN SIZEOF VOID BOOL STRING ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN POW_ASSIGN INC_OP DEC_OP OR_OP AND_OP LE_OP GE_OP EQ_OP NE_OP C_CONST S_CONST B_CONST I_CONST F_CONST IDENTIFIER LET PRINT PRINTS SCAN MAIN LEN VAR NULL_ MALLOC

%start begin

%%
	primary_expression								
		:	IDENTIFIER						
				{	
					SymbolTableEntry ste = getVariable(string($<str>1) );
					
					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: " << string($<str>1) << " not declared" << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("UNKNOWN TYPE");
						$<var.addr>$ = getCharArray("UNKNOWN VARIABLE");
					}
					else if( ste.name.substr(0, 4) == "this" )
					{
						string thisName = "this_" + to_string(ste.scope);
						string varName = ste.name.substr(5, ste.name.length());
						int attrOffset = getAttributeOffset(currentStruct, varName);

						string temp2(getTemp("int"));

						appendCode(temp2 + " =i #" + to_string(attrOffset));

						string temp3(getTemp("int"));
						appendCode(temp3 + " =i " + thisName + " +i " + temp2);

						$<var.type>$ = getCharArray(ste.dataType);
						$<var.addr>$ = getCharArray("*" + temp3);
					}
					else
					{
						$<var.type>$ = getCharArray(ste.dataType);
						$<var.addr>$ = getCharArray(ste.name + "_" + to_string(ste.scope));
					}

					if( parseDebug == 1 )
					{
						cout << "primary_expression -> IDENTIFIER" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}	

			| constant						
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;

					if( parseDebug == 1 )
					{
						cout << "primary_expression -> constant" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| '(' expression ')'			
				{
					$<var.addr>$ = $<var.addr>2;
					$<var.type>$ = $<var.type>2;

					if( parseDebug == 1 )
					{
						cout << "primary_expression -> ( expression )" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| NULL_							
				{
					$<var.type>$ = getCharArray("int");
					$<var.addr>$ = getTemp("int");
					
					appendCode(string($<var.addr>$) + " =i #0");

					if( parseDebug == 1 )
					{
						cout << "primary_expression -> NULL_" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			; 
	constant
		:	I_CONST							
				{
					$<var.type>$ = getCharArray("int");
					$<var.addr>$ = getTemp("int");

					appendCode(string($<var.addr>$) + " =i #" + string($<str>1));

					if( parseDebug == 1 )
					{
						cout << "constant -> I_const" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| F_CONST						
				{
					$<var.type>$ = getCharArray("float");
					$<var.addr>$ = getTemp("float");

					appendCode(string($<var.addr>$) + " =f #" + string($<str>1));

					if( parseDebug == 1 )
					{
						cout << "constant -> F_const" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| C_CONST						
				{
					$<var.type>$ = getCharArray("char");
					$<var.addr>$ = getTemp("char");

					appendCode(string($<var.addr>$) + " =c #" + string($<str>1));

					if( parseDebug == 1 )
					{
						cout << "constant -> C_const" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| S_CONST						
				{
					$<var.type>$ = getCharArray("string");
					$<var.addr>$ = getTemp("int");

					string strConst = getStringConst();

					appendCode( "strconst " + strConst +  " " + string($<var.addr>$) + " #" + string($<str>1));
					if( parseDebug == 1 )
					{
						cout << "constant -> S_const" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| B_CONST						
				{
					$<var.type>$ = getCharArray("bool");
					$<var.addr>$ = getTemp("bool");

					appendCode(string($<var.addr>$) + " =b #" + string($<str>1));
					
					if( parseDebug == 1 )
					{
						cout << "constant -> B_const" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			;

	postfix_expression
		:	primary_expression				
				{
					string addr($<var.addr>1);
					$<array.addr>$ = $<var.addr>1;
					$<array.type>$ = $<var.type>1;
					$<array.level>$ = 0;
					
					if( addr[0] == '_' )
					{
						$<array.completed>$ = 1;
						$<array.index>$ = NULL;
					}
					else
					{
						string origname = "";
						for( int i = 0 ; i < addr.size() ; i++ )
						{
							if( addr[i] != '_' )
							{
								origname += addr[i];
							}
							else
							{
								break;
							}
						}
						SymbolTableEntry ste = getVariable(origname);
						
						if( ste.levels.size() != 0 )
						{
							$<array.completed>$ = 0;
							$<array.index>$ = $<array.addr>$;
						}
						else if( ste.dataType == "string" )
						{
							$<array.completed>$ = 2;
							$<array.index>$ = $<array.addr>$;
						}
						else
						{
							$<array.completed>$ = 1;
							$<array.index>$ = NULL;
						}
					}

					if( parseDebug == 1 )
					{
						cout << "postfix_expression -> primary_expression" << endl;
					}
				}

			| postfix_expression '[' expression ']'
				{
					if( $<array.completed>1 == 1 )
					{
						cout << "COMPILETIME ERROR: Cannot index a non-array type" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else if( string($<var.type>3) != "int" )
					{
						cout << "COMPILETIME ERROR: Cannot use a non integer as index" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						string addr($<array.addr>1);
						string origname = "";
						for( int i = 0 ; i < addr.size() ; i++ )
						{
							if( addr[i] != '_' )
							{
								origname += addr[i];
							}
							else if( addr[i] == '.' )
							{
								origname = "";
							}
							else
							{
								break;
							}
						}
						SymbolTableEntry ste = getVariable(origname);

						if( $<array.completed>1 == 2 )
						{
							string temp(getTemp("int"));
							appendCode(temp + " =i len " + string($<array.addr>$));

							string label1 = getLabel();
							string label2 = getLabel();

							appendCode("if ( " + string($<var.addr>3) + " <i " + temp + " ) goto " +  label1);
							string strconst = getStringConst();
							string var(getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index out of Bounds\\n\"");
							appendCode("print string " + var);
							appendCode("exit");
							appendCode(label1 + ":");
							appendCode("if ( " + string($<var.addr>3) + " >=i #0 ) goto " + label2);

							strconst = getStringConst();
							var = (getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index is negative\\n\"");
							appendCode("print string " + var);

							appendCode("exit");
							appendCode(label2 + ":");

							temp = string(getTemp("int"));

							appendCode(temp + " =i " + string($<array.addr>1) + " +i " + string($<var.addr>3));

							$<array.addr>$ = getCharArray("*" + temp);
							$<array.type>$ = getCharArray("char");
							$<array.completed>$ = 1;
						}
						else if( $<array.level>1 ==  ste.levels.size()-1 )
						{
							string label1 = getLabel();
							string label2 = getLabel();

							appendCode("if ( " + string($<var.addr>3) + " <i " + ste.levels[$<array.level>1] + "_" + to_string(ste.scope) + " ) goto " +  label1);
							string strconst = getStringConst();
							string var(getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index out of Bounds\\n\"");
							appendCode("print string " + var);
							appendCode("exit");
							appendCode(label1 + ":");
							appendCode("if ( " + string($<var.addr>3) + " >=i #0 ) goto " + label2);

							strconst = getStringConst();
							var = (getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index is negative\\n\"");
							appendCode("print string " + var);

							appendCode("exit");
							appendCode(label2 + ":");

							string temp(getTemp("int"));

							appendCode(temp + " =i " + string($<var.addr>3) + " *i #" + to_string(getActualSize(ste.dataType)));

							appendCode(temp + " =i " + string($<array.index>1) + " +i " + temp);

							$<array.addr>$ = getCharArray("*" + temp);
							$<array.type>$ = $<array.type>1;
							$<array.completed>$ = 1;

							if( string($<array.type>$) == "string" )
							{
								$<array.completed>$ = 2;
							}
						}
						else
						{
							string label1 = getLabel();
							string label2 = getLabel();
							appendCode("if ( " + string($<var.addr>3) + " <i " + ste.levels[$<array.level>1] + "_" + to_string(ste.scope) + " ) goto " +  label1);
							string strconst = getStringConst();
							string var(getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index out of Bounds\\n\"");
							appendCode("print string " + var);
							appendCode("exit");
							appendCode(label1 + ":");
							appendCode("if ( " + string($<var.addr>3) + " >=i #0 ) goto " + label2);

							strconst = getStringConst();
							var = (getTemp("int"));
							appendCode("strconst " + strconst + " " + var + " #" + "\"RUNTIME ERROR: Index is negative\\n\"");
							appendCode("print string " + var);

							appendCode("exit");
							appendCode(label2 + ":");

							$<array.index>$ = getTemp("int");
							string temp($<array.index>$);

							appendCode(temp + " =i #1");

							for( int i = $<array.level>1 + 1; i < ste.levels.size() ; i++ )
							{
								appendCode(temp + " =i " + temp + " *i " + ste.levels[i] + "_" + to_string(ste.scope));
							}

							appendCode(temp + " =i " + temp + " *i #" + to_string(getActualSize(ste.dataType)));

							appendCode(temp + " =i " + string($<var.addr>3) + " *i " + temp );
							appendCode(temp + " =i " + temp + " +i " + string($<array.index>1));

							$<array.addr>$ = $<array.addr>1;
							$<array.completed>$ = 0;
							$<array.level>$ = $<array.level>1 + 1;
							$<array.type>$ = $<array.type>1;
						}
						if( parseDebug == 1 )
						{
							cout << "postfix_expression -> postfix_expression [ expression ]" << endl;
						}
					}
				}

			| postfix_expression INC_OP		
				{
					if( $<array.completed>$ >= 1 )
					{
						if( strcmp($<array.type>1,"int") != 0 )
						{
							cout << "COMPILETIME ERROR: cannot apply increment operator to non int types" << endl;
							cout << "At line : " << yylineno << endl;
						}
						else if( string($<array.addr>$)[0] == '_' )
						{
							cout << "COMPILETIME ERROR: lvalue is required as increment operand" << endl;
							cout << "At line: " << yylineno << endl;
						}
						else
						{
							$<array.addr>$ = getTemp("int");
							appendCode(string($<array.addr>$) + " =i " + string($<array.addr>1));
							appendCode(string($<array.addr>1) + " =i " + string($<array.addr>1) + " +i " + "#1");
							$<array.type>$ = $<var.type>1;
							$<array.completed>$ = $<array.completed>1;
						}
					}
					else
					{
						cout << "COMPILETIME ERROR: cannot apply increment operator to non int types" << endl;
						cout << "At line : " << yylineno << endl;
					}

					if( parseDebug == 1 )
					{
						cout << "postfix -> INC_OP" << endl;
					}
				}	

			| postfix_expression DEC_OP		
				{
					if( $<array.completed>$ >= 1 )
					{
						if( strcmp($<array.type>1,"int") != 0 )
						{
							cout << "COMPILETIME ERROR: cannot apply decrement operator to non int types" << endl;
							cout << "At line : " << yylineno << endl;
						}
						else if( string($<array.addr>$)[0] == '_' )
						{
							cout << "COMPILETIME ERROR: lvalue is required as decrement operand" << endl;
							cout << "At line: " << yylineno << endl;
						}
						else
						{
							$<array.addr>$ = getTemp("int");
							appendCode(string($<array.addr>$) + " =i " + string($<array.addr>1));
							appendCode(string($<array.addr>1) + " =i " + string($<array.addr>1) + " -i " + "#1");
							$<array.type>$ = $<var.type>1;
							$<array.completed>$ = $<array.completed>1;
						}
					}
					else
					{
						cout << "COMPILETIME ERROR: cannot apply decrement operator to non int types" << endl;
						cout << "At line : " << yylineno << endl;
					}
					if( parseDebug == 1 )
					{
						cout << "postfix -> DEC_OP" << endl;
					}
				}
				
			| postfix_expression '.' IDENTIFIER
				{
					SymbolTableEntry ste = getStructAttribute( string($<array.type>1), string($<str>3));
					
					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: type " << string($<array.type>1) << " doesn't have an attribute " << string($<str>3) << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						string temp1(getTemp("int"));
						appendCode("la " + temp1 + " " + string($<array.addr>1));

						string temp2(getTemp("int"));
						appendCode(temp2 + " =i #" + to_string(getAttributeOffset(string($<array.type>1), string($<str>3))));

						appendCode(temp2 + " =i " + temp2 + " +i " + temp1);

						$<array.type>$ = getCharArray(ste.dataType);
						$<array.addr>$ = getCharArray("*" + temp2);
						$<array.completed>$ = 1;
					}
				}

			| postfix_expression '.' IDENTIFIER '('
				{
					SymbolTableEntry ste = getFunctionReturnAddress(string($<array.type>1), string($<str>3));

					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: Type " << string($<array.type>1) << " doesn't have a method " << string($<str>3) << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("funCall " + string($<array.type>1) + "." + string($<str>3));

						setCallStack(string($<array.type>1), string($<str>3));

						string temp(getTemp("int"));
						appendCode("la " + temp + " " + string($<array.addr>1));
						appendCode("param " + temp + " 4");

						callStack.pop();
					}
				}

			functionCall		
				{
					SymbolTableEntry ste = getFunctionReturnAddress(string($<array.type>1), string($<str>3));

					if( !callStack.empty() )
					{
						cout << "COMPILETIME ERROR: Too few arguments for the function " << string($<array.type>1) << "." << string($<str>3) << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("call " + getFunctionLabel(string($<array.type>1), string($<str>3)));

						$<array.completed>$ = 1;
						$<array.type>$ = getCharArray(ste.dataType);
						$<array.addr>$ = getTemp(ste.dataType);

						appendCode(string($<array.addr>$) + " = returnVal");
					}

					if( parseDebug == 1 )
					{
						cout << "postfix expr -> postfix . identifier '(' functionCall " << endl;
					}
				}

			| IDENTIFIER '(' 
				{
					SymbolTableEntry ste = getFunctionReturnAddress(currentStruct, string($<str>1));

					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: " << string($<str>1) << " not declared" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("funCall " + currentStruct + "." + string($<str>1));
						setCallStack(currentStruct, string($<str>1));

						if( currentStruct != "main" )
						{
							string temp(getTemp("int"));
							appendCode("la " + temp + " this_" + to_string(callStack.top().scope));
							appendCode("param " + temp + " 4");
							callStack.pop();
						}
					}
				}

			functionCall
				{
					SymbolTableEntry ste = getFunctionReturnAddress(currentStruct, string($<str>1));

					if( !callStack.empty() )
					{
						cout << "COMPILETIME ERROR: Too few arguments for the function " << string($<str>1) << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("call " + getFunctionLabel(currentStruct, string($<str>1)));

						$<array.completed>$ = 1;
						$<array.type>$ = getCharArray(ste.dataType);
						$<array.addr>$ =  getTemp(ste.dataType);

						appendCode(string($<array.addr>$) + " = returnVal");
					}

					if( parseDebug == 1 )
					{
						cout << "postfix expr -> identifier '(' functionCall " << endl;
					}
				}	
			;
	
	functionCall
		:	')'						
				{
					if( parseDebug == 1 )
					{
						cout << "functionCall ->  ')'" << endl;
					}
				}

			| argument_list ')'
				{
					if( parseDebug == 1 )
					{
						cout << "functionCall -> argument_list ')'" << endl;
					}
				}

			;

	argument_list
		:	expression
				{
					if( callStack.empty() )
					{
						cout << "COMPILETIME ERROR: Too many arguments" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else if( string($<var.type>1).substr(0, 5) == "array" )
					{
						string addr($<var.addr>1);
						string origname = "";
						for( int i = 0 ; i < addr.size() ; i++ )
						{
							if( addr[i] != '_' )
							{
								origname += addr[i];
							}
							else
							{
								break;
							}
						}
						SymbolTableEntry ste = getVariable(origname);

						if( callStack.top().dataType != ste.dataType )
						{
							cout << "COMPILETIME ERROR: Incorrect function parameters type" << endl;
							cout << "Given parameter is of type '" << ste.dataType << "', required parameter is of type '" << callStack.top().dataType << "'" << endl;
						}
						else if( callStack.top().levels.size() != ste.levels.size() )
						{
							cout << "COMPILETIME ERROR: Incorrect dimensions for the array" << endl;
							cout << "Required array has dimensions " << callStack.top().levels.size() << ", given array has dimensions " << ste.levels.size() << endl;
						}
						else
						{
							appendCode("param " + string($<var.addr>1) + " " + to_string(callStack.top().size));
							for( int i = 0 ; i < callStack.top().levels.size() ; i++ )
							{
								string c = ste.levels[i] + "_" + to_string(ste.scope);
								appendCode("param " + c + " " + to_string(callStack.top().size));
								callStack.pop();
							}
							callStack.pop();
						}
					}
					else if( ((string($<var.type>1) != callStack.top().dataType) and ((string($<var.type>1)[0] == '*' and callStack.top().dataType != "int") or (string($<var.type>1) == "int" and callStack.top().dataType[0] != '*') )))
					{
						cout << "COMPILETIME ERROR: Incorrect fffffffunction parameters type" << endl;
						cout << "Given parameter is of type '" << string($<var.type>1) << "', required parameter is of type '" << callStack.top().dataType << "'" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{

						appendCode("param " + string($<var.addr>1) + " " + to_string(callStack.top().size));

						callStack.pop();
					}

					if( parseDebug == 1 )
					{
						cout << "argumentlist -> expression" << endl;
					}
				}
			| argument_list ',' expression
				{
					if( callStack.empty() )
					{
						cout << "COMPILETIME ERROR: Too many arguments" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else if( string($<var.type>3).substr(0, 5) == "array" )
					{
						string addr($<var.addr>3);
						string origname = "";
						for( int i = 0 ; i < addr.size() ; i++ )
						{
							if( addr[i] != '_' )
							{
								origname += addr[i];
							}
							else
							{
								break;
							}
						}
						SymbolTableEntry ste = getVariable(origname);

						if( callStack.top().dataType != ste.dataType )
						{
							cout << "COMPILETIME ERROR: Incorrect function parameters type" << endl;
							cout << "Given parameter is of type '" << ste.dataType << "', required parameter is of type '" << callStack.top().dataType << "'" << endl;
						}
						else if( callStack.top().levels.size() != ste.levels.size() )
						{
							cout << "COMPILETIME ERROR: Incorrect dimensions for the array" << endl;
							cout << "Required array has dimensions " << callStack.top().levels.size() << ", given array has dimensions " << ste.levels.size() << endl;
						}
						else
						{
							appendCode("param " + string($<var.addr>3) + " " + to_string(callStack.top().size));
							callStack.pop();
						}
					}

					else if( ((string($<var.type>3) != callStack.top().dataType) and ((string($<var.type>3)[0] == '*' and callStack.top().dataType != "int") or (string($<var.type>1) == "int" and callStack.top().dataType[0] != '*') )))
					{
						cout << "COMPILETIME ERROR: Incorrect function parameters type" << endl;
						cout << "Given parameter is of type " << string($<var.type>3) << ", required parameter is of type " << callStack.top().dataType << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("param " + string($<var.addr>3) + " " + to_string(callStack.top().size));

						callStack.pop();
					}

					if( parseDebug == 1 )
					{
						cout << "argumentlist -> argumentlist ',' expression" << endl;
					}
				}
			;
	
	unary_expression
		:	postfix_expression			
				{	
					if( $<array.completed>$ >= 1 )
					{
						$<var.addr>$ = $<array.addr>1;
						$<var.type>$ = $<array.type>1;
					}
					else
					{
						$<var.addr>$ = $<array.addr>1;
						$<var.type>$ = getCharArray("array " + string($<array.type>1));
					}

					if( parseDebug == 1 )
					{
						cout << "unary_expr	-> postfix" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| INC_OP unary_expression		
				{
					if( strcmp($<var.type>2,"int") != 0 )
					{
						cout << "COMPILETIME ERROR: cannot apply decrement operator to non int types" << endl;
						cout << "At line : " << yylineno << endl;
						
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;
					}
					else if( string($<var.addr>2)[0] == '_' )
					{
						cout << "COMPILETIME ERROR: lvalue is required as increment operand" << endl;
						cout << "At line: " << yylineno << endl;

						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;
					}
					else
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;

						appendCode(string($<var.addr>2) + " =i " + string($<var.addr>2) + " +i " + "#1");
						appendCode(string($<var.addr>$) + " =i " + string($<var.addr>2));
					}

					if( parseDebug == 1 )
					{
						cout << "unary_expr	-> INC_OP unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| DEC_OP unary_expression		
				{
					if( strcmp($<var.type>2,"int") != 0 )
					{
						cout << "COMPILETIME ERROR: cannot apply decrement operator to non int types" << endl;
						cout << "At line : " << yylineno << endl;

						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;
					}
					else if( string($<var.addr>$)[0] == '_' )
					{
						cout << "COMPILETIME ERROR: lvalue is required as decrement operand" << endl;
						cout << "At line: " << yylineno << endl;
						
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;
					}
					else
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>2;

						appendCode(string($<var.addr>2) + " =i " + string($<var.addr>2) + " -i " + "#1");
						appendCode(string($<var.addr>$) + " =i " + string($<var.addr>2));
					}
					
					if( parseDebug == 1 )
					{
						cout << "unary_expr	-> DEC_OP unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| unary_operator unary_expression
				{
					string op($<str>1);
					string type($<var.type>2); 
					$<var.type>$ = $<var.type>2;

					if( op == "+" or op == "-" )
					{
						if( type != "int" and type != "float" )
						{
							cout << "COMPILETIME ERROR: cannot apply + to non number types" << endl;
							cout << "At line : " << yylineno << endl;
							$<var.addr>$ = $<var.addr>2;
						}
						else
						{
							if( op == "-" )
							{
								if( type == "int" )
								{
									$<var.addr>$ = getTemp("int");
									appendCode(string($<var.addr>$) + " =i " + "minus " + string($<var.addr>2));
								}
								else if( type == "float" )
								{
									$<var.addr>$ = getTemp("float");
									appendCode(string($<var.addr>$) + " =f " + "minus " + string($<var.addr>2));
								}
							}
						}
					}
					if( op == "!" )
					{
						if( type != "bool" )
						{
							cout << "COMPILETIME ERROR: cannot apply '!' to non bool types" << endl;
							cout << "At line : " << yylineno << endl;
							$<var.type>$ = $<var.type>2;
						}
						else
						{
							$<var.addr>$ = getTemp("bool");
							appendCode(string($<var.addr>$) + " = " + "not " + string($<var.addr>2));
						}
					}	
					if( op == "*" )
					{
						if( type[0] != '*' )
						{
							cout << "COMPILETIME ERROR: cannot apply * to non-pointer type" << endl;
							cout << "At line : " << yylineno << endl;
							$<var.type>$ = getCharArray("int");
							$<var.addr>$ = $<var.addr>2;
						}
						else
						{
							string temp = type.substr(1, type.size());
							$<var.type>$ = getCharArray(temp);

							string addr(getTemp(temp));
							appendCode( addr + " =i " + string($<var.addr>2) );

							$<var.addr>$ = getCharArray("*" + addr);
						}
					}
					if( op == "&" ) 
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = getCharArray("int");

						appendCode("la " + string($<var.addr>$) + " " + string($<var.addr>2));
					}
					if( parseDebug == 1 )
					{
						cout << "unary_expr	-> unary_op unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| LEN '(' IDENTIFIER ')'		
				{
					SymbolTableEntry ste = getVariable(string($<str>3) );
					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: " << string($<str>3) << " not declared" << endl;
						cout << "At line : " << yylineno << endl;
						
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");
					}
					else
					{
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");

						appendCode(string($<var.addr>$) + " =i len " + ste.name + "_" + to_string(ste.scope));
					}
					
					if( parseDebug == 1 )
					{	
						cout << "unary_expr -> len '(' identifier ')'" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| SIZEOF '(' IDENTIFIER ')'
				{
					SymbolTableEntry ste = getVariable(string($<str>3) );
					
					if( ste.name == "" )
					{
						cout << "COMPILETIME ERROR: " << string($<str>1) << " not declared" << endl;
						cout << "At line : " << yylineno << endl;

						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");
					}
					else
					{
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");

						appendCode(string($<var.addr>$) + " =i #" + to_string(getActualSize(ste.dataType)));
					}
					
					if( parseDebug == 1 )
					{	
						cout << "unary_expr -> size '(' identifier ')'" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| SIZEOF '(' type_name ')'
				{
					if( !checkStruct(dtype) )
					{
						cout << "COMPILETIME ERROR: Type " << dtype << " is not defined" << endl;
						cout << "At line : " << yylineno << endl;
						
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");
					}
					else
					{
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");

						appendCode(string($<var.addr>$) + " =i #" + to_string(getActualSize(dtype)));
					}
					
					if( parseDebug == 1 )
					{	
						cout << "unary_expr -> size '(' identifier ')'" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| MALLOC '(' expression ')'
				{
					if( string($<var.type>3) != "int" )
					{
						cout << "COMPILETIME ERROR: Argument to malloc must be an integer" << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");
					}
					else
					{
						$<var.type>$ = getCharArray("int");
						$<var.addr>$ = getTemp("int");

						appendCode(string($<var.addr>$) + " =i malloc " + string($<var.addr>3));
					}
					
					if( parseDebug == 1 )
					{	
						cout << "unary_expr -> malloc '(' expression ')'" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;
	
	type_name		
		:	INT							
				{	
					dtype = "int"; 	
					starsCount = 0; 
				}	

			| FLOAT						
				{	
					dtype = "float";
					starsCount = 0; 
				}
			
			| CHAR						
				{	
					dtype = "char";
					starsCount = 0; 
				}
			
			| STRING					
				{	
					dtype = "string";
					starsCount = 0; 
				}
				
			| BOOL						
				{	
					dtype = "bool";
					starsCount = 0; 
				}

			| VAR IDENTIFIER					
				{	
					dtype = string($<str>2); 
					starsCount = 0;
					if( !checkStruct(dtype) )
					{
						cout << "COMPILETIME ERROR: Type " << dtype << " is not defined" << endl;
						cout << "At line : " << yylineno << endl;
					}
				}
			;

	unary_operator
		:	'+'				
				{	
					$<str>$ = $<str>1;
					
					if( parseDebug == 1 )
					{
						cout << "unary_op -> +" << endl;
					}
				}

			| '-'			
				{	
					$<str>$ = $<str>1;
					
					if( parseDebug == 1 )
					{
						cout << "unary_op -> -" << endl;
					}
				}

			| '!'			
				{
					$<str>$ = $<str>1;
					
					if( parseDebug == 1 )
					{
						cout << "unary_op -> !" << endl;
					}
				}

			| '*'			
				{
					$<str>$ = $<str>1;
					
					if( parseDebug == 1 )
					{
						cout << "unary_op -> *" << endl;
					}
				}

			| '&'			
				{
					$<str>$ = $<str>1;
					
					if( parseDebug == 1 )
					{
						cout << "unary_op -> &" << endl;
					}
				}
			;
	
	multiplicative_expression
		:	unary_expression				
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;

					if( parseDebug == 1 )
					{
						cout << "multi	-> unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| multiplicative_expression '*' unary_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( (type1 != "int" and type1 != "float") or (type2 != "int" and type2 != "float") )
					{
						cout << "COMPILETIME ERROR: cannot apply '*' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = $<var.type>1;
						$<var.type>$ = $<var.type>1;
					}
					else
					{
						if( type1 == "int" and type2 == "int" )
						{
							$<var.addr>$ = getTemp("int");
							$<var.type>$ = $<var.type>1;
							appendCode(string($<var.addr>$) + " =i " + string($<var.addr>1) + " *i " +  string($<var.addr>3));
						}
						else if( type1 == "float" and type2 == "float" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>1;
							appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " *f " +  string($<var.addr>3));
						}
						else if( type1 == "int" and type2 == "float" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>3;
							char* temp = getTemp("float");
							appendCode(string(temp) + " =f elevateToFloat ( " + string($<var.addr>1) + " )");
							appendCode(string($<var.addr>$) + " =f " + string(temp) + " *f " +  string($<var.addr>3));
						}
						else if( type1 == "float" and type2 == "int" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>1;
							char* temp = getTemp("float");
							appendCode(string(temp) + " =f elevateToFloat ( " + string($<var.addr>3) + " )");
							appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " *f " +  string(temp));
						}
					}
					if( parseDebug == 1 )
					{
						cout << "multi -> multi * unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| multiplicative_expression '/' unary_expression
				{	
					string type1($<var.type>1);
					string type2($<var.type>3);
					
					if( (type1 != "int" and type1 != "float") or (type2 != "int" and type2 != "float") )
					{
						cout << "COMPILETIME ERROR: cannot apply '/' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = $<var.type>1;
						$<var.type>$ = $<var.type>1;
					}
					else
					{
						if( type1 == "int" and type2 == "int" )
						{
							$<var.addr>$ = getTemp("int");
							$<var.type>$ = $<var.type>1;
							appendCode(string($<var.addr>$) + " =i " + string($<var.addr>1) + " /i " +  string($<var.addr>3));
						}
						else if( type1 == "float" and type2 == "float" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>1;
							appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " /f " +  string($<var.addr>3));
						}
						else if( type1 == "int" and type2 == "float" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>3;
							char* temp = getTemp("float");
							appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>1) + " )");
							appendCode(string($<var.addr>$) + " =f " + string(temp) + " /f " +  string($<var.addr>3));
						}
						else if( type1 == "float" and type2 == "int" )
						{
							$<var.addr>$ = getTemp("float");
							$<var.type>$ = $<var.type>1;
							char* temp = getTemp("float");
							appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>3) + " )");
							appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " /f " +  string(temp));
						}
					}

					if( parseDebug == 1 )
					{
						cout << "multi -> multi / unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| multiplicative_expression '%' unary_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 != "int" or type2 != "int" )
					{
						cout << "COMPILETIME ERROR: cannot apply '\%' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = $<var.type>1;
						$<var.type>$ = $<var.type>1;
					}
					else
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =i " + string($<var.addr>1) + " %i " +  string($<var.addr>3));
					}
					if( parseDebug == 1 )
					{
						cout << "multi	-> multi %% unary_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;

	additive_expression
		:	multiplicative_expression		
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;
					if( parseDebug == 1 )
					{
						cout << "additive -> multi" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| additive_expression '+' multiplicative_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 == "int" and type2 == "int" )
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =i " + string($<var.addr>1) + " +i " +  string($<var.addr>3));
					}
					else if( type1 == "float" and type2 == "float" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " +f " +  string($<var.addr>3));
					}
					else if( type1 == "int" and type2 == "float" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>3;
						char* temp = getTemp("float");
						appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>1) + " )");
						appendCode(string($<var.addr>$) + " =f " + string(temp) + " +f " +  string($<var.addr>3));
					}
					else if( type1 == "float" and type2 == "int" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>1;
						char* temp = getTemp("float");
						appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>3) + " )");
						appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " +f " +  string(temp));
					}
					else if( type1 == "string" and type2 == "string" )
					{
						$<var.type>$ = $<var.type>1;
						$<var.addr>$ = getTemp("string");
						appendCode(string($<var.addr>$) + " =s strcat " + string($<var.addr>1) + " " +  string($<var.addr>3));
					}
					else if( type1 == "string" and type2 == "char" )
					{
						$<var.type>$ = $<var.type>1;
						$<var.addr>$ = getTemp("string");
						appendCode(string($<var.addr>$) + " =s strcatc " + string($<var.addr>1) + " " +  string($<var.addr>3));
					}
					else if( type1 == "char" and type2 == "string" )
					{
						$<var.type>$ = $<var.type>3;
						$<var.addr>$ = getTemp("string");
						appendCode(string($<var.addr>$) + " =s ccatstr " + string($<var.addr>3) + " " +  string($<var.addr>1));
					}
					else if( type1 == "char" and type2 == "int" )
					{
						$<var.addr>$ = getTemp("char");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =c " + string($<var.addr>1) + " +c " +  string($<var.addr>3));
					}
					else
					{
						cout << "COMPILETIME ERROR: cannot apply '+' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = $<var.type>1;
						$<var.type>$ = $<var.type>1;
					}

					if( parseDebug == 1 )
					{
						cout << "additive -> additive + multi" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| additive_expression '-' multiplicative_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 == "int" and type2 == "int" )
					{
						$<var.addr>$ = getTemp("int");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =i " + string($<var.addr>1) + " -i " +  string($<var.addr>3));
					}
					else if( type1 == "float" and type2 == "float" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>1;
						appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " -f " +  string($<var.addr>3));
					}
					else if( type1 == "int" and type2 == "float" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>3;
						char* temp = getTemp("float");
						appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>1) + " )");
						appendCode(string($<var.addr>$) + " =f " + string(temp) + " -f " +  string($<var.addr>3));
					}
					else if( type1 == "float" and type2 == "int" )
					{
						$<var.addr>$ = getTemp("float");
						$<var.type>$ = $<var.type>1;
						char* temp = getTemp("float");
						appendCode(string(temp) + " = elevateToFloat ( " + string($<var.addr>3) + " )");
						appendCode(string($<var.addr>$) + " =f " + string($<var.addr>1) + " -f " +  string(temp));
					}
					else
					{
						cout << "COMPILETIME ERROR: cannot apply '-' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = $<var.type>1;
						$<var.type>$ = $<var.type>1;
					}

					if( parseDebug == 1 )
					{
						cout << "additive -> additive - multi" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;
	
	relational_expression
		:	additive_expression				
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;
					
					if( parseDebug == 1 )
					{
						cout << "rel_expr	-> additive" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| relational_expression '<' additive_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);
					
					if( type1 == "bool" or type1 == "string" or type2 == "bool" or type2 == "string" )
					{
						cout << "COMPILETIME ERROR: cannot apply '<' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
					}
					else
					{
						$<var.type>$ = getCharArray("bool");

						$<var.addr>$ = getTemp("bool");
						string label1 = getLabel();
						string label2 = getLabel();

						if( type1 == "int" and type2 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " <i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else
						{
							appendCode("if ( " + string($<var.addr>1) + " <f " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}

					if( parseDebug == 1 )
					{
						cout << "rel_expr -> rel_expr < additive" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| relational_expression '>' additive_expression
				{
					//same as for >
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 == "bool" or type1 == "string" or type2 == "bool" or type2 == "string" )
					{
						cout << "COMPILETIME ERROR: cannot apply '>' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
					}
					else
					{
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");

						string label1 = getLabel();
						string label2 = getLabel();
						if( type1 == "int" and type2 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " >i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else
						{
							appendCode("if ( " + string($<var.addr>1) + " >f " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}

					if( parseDebug == 1 )
					{
						cout << "rel_expr -> rel_expr > additive" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| relational_expression LE_OP additive_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 == "bool" or type1 == "string" or type2 == "bool" or type2 == "string" )
					{
						cout << "COMPILETIME ERROR: cannot apply '<=' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
					}
					else
					{
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");

						string label1 = getLabel();
						string label2 = getLabel();
						if( type1 == "int" and type2 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " <=i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else
						{
							appendCode("if ( " + string($<var.addr>1) + " <=f " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}

					if( parseDebug == 1 )
					{
						cout << "rel_expr -> rel_expr <= additive" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| relational_expression GE_OP additive_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 == "bool" or type1 == "string" or type2 == "bool" or type2 == "string" )
					{
						cout << "COMPILETIME ERROR: cannot apply '>=' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
					}
					else
					{
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");

						string label1 = getLabel();
						string label2 = getLabel();
						if( type1 == "int" and type2 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " >=i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else
						{
							appendCode("if ( " + string($<var.addr>1) + " >=f " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}
					if( parseDebug == 1 )
					{
						cout << "rel_expr -> rel_expr >= additive" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;
	
	equality_expression
		:	relational_expression			
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;

					if( parseDebug == 1 )
					{
						cout << "eq_expr -> rel_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| equality_expression EQ_OP relational_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 != type2 and !(type1[0] == '*' and type2 == "int") )
					{
						cout << "COMPILETIME ERROR: cannot apply '==' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
					}
					else
					{
						$<var.type>$ = getCharArray("bool");

						$<var.addr>$ = getTemp("bool");
						string label1 = getLabel();
						string label2 = getLabel();
						if( type1 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "float" )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==f " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "char" )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==c " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "bool" )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==b " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "string" )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==s " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1[0] == '*' )
						{
							appendCode("if ( " + string($<var.addr>1) + " ==i " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}
					if( parseDebug == 1 )
					{
						cout << "eq_expr -> eq_expr == rel_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| equality_expression NE_OP relational_expression
				{
					string type1($<var.type>1);
					string type2($<var.type>3);

					if( type1 != type2 and !(type1[0] == '*' and type2 == "int") )
					{
						cout << "COMPILETIME ERROR: cannot apply '!=' to arguements of types: " << type1 << ", " << type2 << endl;
						cout << "At line : " << yylineno << endl;
						
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");
						
						return -1;
					}
					else
					{
						$<var.type>$ = getCharArray("bool");
						$<var.addr>$ = getTemp("bool");

						string label1 = getLabel();
						string label2 = getLabel();
						if( type1 == "int" )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=i " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "float" )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=f " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "char" )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=c " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "bool" )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=b " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1 == "string" )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=s " + string($<var.addr>3) + " ) goto " + string(label1));
						}
						else if( type1[0] == '*' )
						{
							appendCode("if ( " + string($<var.addr>1) + " !=i " + string($<var.addr>3) + " ) goto " + string(label1));
						}

						appendCode(string($<var.addr>$) + " =b #false");
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");	
					}

					if( parseDebug == 1 )
					{
						cout << "eq_expr -> eq_expr != rel_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}	
			;

	logical_and_expression
		:	equality_expression				
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;
					
					if( parseDebug == 1 )
					{
						cout << "logicaland_expr -> eq_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| logical_and_expression AND_OP equality_expression
				{
					if( strcmp($<var.type>1, "bool") != 0 or strcmp($<var.type>3, "bool") != 0 )
					{
						cout << "COMPILETIME ERROR: cannot apply '&&' to non-boolean operands" << endl;
						cout << "At line : " << yylineno << endl;
						
						$<var.addr>$ = getTemp("bool");
						$<var.type>$ = $<var.type>1;
					}
					else
					{
						$<var.addr>$ = getTemp("bool");
						$<var.type>$ = $<var.type>1;

						char* label1 = getLabel();
						appendCode("if ( " + string($<var.addr>1) + " ==b #false ) goto " + string(label1));
						appendCode("if ( " + string($<var.addr>3) + " ==b #false ) goto " + string(label1));
						appendCode(string($<var.addr>$) + " =b #true");
						char* label2 = getLabel();
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #false");
						appendCode(string(label2) + ":");
					}

					if( parseDebug == 1 )
					{
						cout << "logicaland -> logicaland && eq_expr" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;
	
	logical_or_expression
		:	logical_and_expression			
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;
					
					if( parseDebug == 1 )
					{
						cout << "logicalor -> logicaland" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}

			| logical_or_expression OR_OP	logical_and_expression
				{
					if( strcmp($<var.type>1, "bool") != 0 or strcmp($<var.type>3, "bool") != 0 )
					{
						cout << "COMPILETIME ERROR: cannot apply '||' to non-boolean operands" << endl;
						cout << "At line : " << yylineno << endl;
						$<var.addr>$ = getTemp("bool");
						$<var.type>$ = $<var.type>1;
					}
					else
					{
						$<var.addr>$ = getTemp("bool");
						$<var.type>$ = $<var.type>1;

						char* label1 = getLabel();
						appendCode("if ( " + string($<var.addr>1) + " ==b #true ) goto " + string(label1));
						appendCode("if ( " + string($<var.addr>3) + " ==b #true ) goto " + string(label1));
						appendCode(string($<var.addr>$) + " =b #false");
						char* label2 = getLabel();
						appendCode("goto " + string(label2));
						appendCode(string(label1) + ":");
						appendCode(string($<var.addr>$) + " =b #true");
						appendCode(string(label2) + ":");
					}
					if( parseDebug == 1 )
					{
						cout << "logical_or -> logicalor || logicaland" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;;
					}
				}
			;

	expression
		: 	logical_or_expression			
				{
					$<var.addr>$ = $<var.addr>1;
					$<var.type>$ = $<var.type>1;
					
					if( parseDebug == 1 )
					{
						cout << "expresson -> logicalor" << endl;
						cout << "$<var.addr>$ = " << string($<var.addr>$) << endl;
						cout << "$<var.type>$ = " << string($<var.type>$) << endl;
					}
				}
			;

	assignment_operator
		:	'='						{	$<str>$ = $<str>1;	}
			| MUL_ASSIGN			{	$<str>$ = $<str>1;	}
			| DIV_ASSIGN			{	$<str>$ = $<str>1;	}
			| MOD_ASSIGN			{	$<str>$ = $<str>1;	}
			| ADD_ASSIGN			{	$<str>$ = $<str>1;	}
			| SUB_ASSIGN			{	$<str>$ = $<str>1;	}
			| POW_ASSIGN			{	$<str>$ = $<str>1;	}
			;

	assignment_expression
		: 	unary_expression assignment_operator expression
				{
					string op($<str>2);
					string ltype($<var.type>1);
					string rtype($<var.type>3);
					string type1 = ltype;
					string type2 = rtype;
					string var($<var.addr>1);
					string val($<var.addr>3);

					//usual assignment rules.
					if( op == "=" )
					{
						if( ltype == "int" and rtype == "int" )
						{
							appendCode(var + " =i " + val);
						}
						else if( ltype == "float" and rtype == "float" )
						{
							appendCode(var + " =f " + val);
						}
						else if( ltype == "string"  and rtype == "string" )
						{
							appendCode(var + " =s " + val);
						}
						else if( ltype == "char" and rtype == "char" )
						{
							appendCode(var + " =c " + val);
						}
						else if( ltype == "bool" and rtype == "bool" )
						{
							appendCode(var + " =b " + val);
						}
						else if( ltype == "float" and rtype == "int" )
						{
							char* t = getTemp("float");
							appendCode(string(t) + " =f " + "elevateToFloat ( " + val + " )");
							appendCode(var + " =f " + string(t));
						}
						else if( ltype[0] == '*' and rtype == "int" )
						{
							appendCode(var + " =i " + val);
						}
						else if( ltype == rtype and ltype[0] == '*' )
						{
							appendCode(var + " =i" + " " + val);
						}
						else if( ltype == rtype )
						{
							appendCode(var + " =v " + val);
						}
						else
						{
							cout << "COMPILETIME ERROR: different operands type to '='" << endl;
							cout << "ltype = " << ltype << " rtype = " << rtype << endl;
							cout << "At line : " << yylineno << endl;
						}
					}
					else if( op[0] == '%' )
					{
						if( ltype != "int" or rtype != "int" )
						{
							cout << "COMPILETIME ERROR: non-int operands to %" << endl;
							cout << "At line : " << yylineno << endl;
						}
						else
						{
							appendCode(var + " =i " + var + " % " + val);
						}
					}
					else if( op[0] == '^' or op[0] == '-' or op[0] == '/' or op[0] == '*')
					{
						if( ltype != "int" and ltype != "float" or rtype != "int" and rtype != "float" )
						{
							cout << "COMPILETIME ERROR: invalid operands for "  << op << endl;
							cout << "At line : " << yylineno << endl;
						}
						else
						{
							if( type1 == "int" and type2 == "int" )
							{
								appendCode(var + " =i " + var + " " + op[0] + "i " +  val);
							}
							else if( type1 == "float" and type2 == "float" )
							{
								appendCode(var + " =f " + var + " " + op[0] + "f " +  val);
							}
							else if( type1 == "int" and type2 == "float" )
							{
								cout << "COMPILETIME ERROR: cannot convert int to float" << endl;
								cout << "At line : " << yylineno << endl;
							}
							else if( type1 == "float" and type2 == "int" )
							{
								char* temp = getTemp("float");
								appendCode(string(temp) + " = elevateToFloat ( " + val + " )");
								appendCode(var + " =f " + var + " " + op[0] + "f " +  string(temp));
							}
						}
					}
					else if( op[0] == '+' )
					{
						if( type1 == "int" and type2 == "int" )
						{
							appendCode(var + " =i " + var + " +i " +  val);
						}
						else if( type1 == "float" and type2 == "float" )
						{
							appendCode(var + " =f " + var + " +f " +  val);
						}
						else if( type1 == "int" and type2 == "float" )
						{
							cout << "COMPILETIME ERROR: cannot convert int to float" << endl;
							cout << "At line : " << yylineno << endl;
						}
						else if( type1 == "float" and type2 == "int" )
						{
							char* temp = getTemp("float");
							appendCode(string(temp) + " = elevateToFloat ( " + val + " )");
							appendCode(var + " =f " + var + " +f " +  string(temp));
						}
						else if( type1 == "string" and type2 == "string" )
						{
							string str(getTemp("string"));
							appendCode(str + " =s strcat " + var + " " +  val);
							appendCode(var + " =s " + str);
						}
						else if( type1 == "string" and type2 == "char" )
						{
							string str(getTemp("string"));
							appendCode(str + " =s strcatc " + var + " " +  val);
							appendCode(var + " =s " + str);
						}
						else if( type1 == "char" and type2 == "int" )
						{
							appendCode(var + " =c " + var + " +c " +  val);
						}
						else
						{
							cout << "COMPILETIME ERROR: Invalid operands for +" << endl;
							cout << "At line : " << yylineno << endl;
						}
					}
					if( parseDebug == 1 )
					{
						cout << "assignment epxression -> unaryExpression assign_op expression" << endl;
					}
				}
			;


	declaration_expression
			:type_name declarationlist
				{
					if( parseDebug == 1 )
					{
						cout << "declaration expr -> typename declarationlist" << endl;
					}
				}
			;
	
	declarationlist
			:	declaration ',' declarationlist		
			|	declaration
			;
	
	declaration
		:	stars IDENTIFIER						
				{
					string dd = dtype;
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dd = "*" + dd;
					}
					starsCount = 0;

					vector<string> levels;
					string var($<str>2);

					if( insertVariable(var, dd, levels ) == -1 )
					{
						cout << "COMPILETIME ERROR: Redeclaration of an already existing variable " << var << endl;
						cout << "At line : " << yylineno << endl;
					}

					if( parseDebug == 1 )
					{
						cout << "declaration -> identifier" << endl;
					}
				}

			| stars IDENTIFIER '=' expression		
				{
					string dd = dtype;
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dd = "*" + dd;
					}
					starsCount = 0;

					if( dd != string($<var.type>4) and dd[0] != '*' )
					{
						cout << "COMPILETIME ERROR: cannot assign different variable types: " << dtype << " and " << string($<var.type>4) << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						vector<string> levels;

						string var($<str>2);
						string val($<var.addr>4);
						if( insertVariable(var, dd, levels) == -1 )
						{
							cout << "COMPILETIME ERROR: Redeclaration of an already existing variable " << var << endl;
							cout << "At line : " << yylineno << endl;
						}
						else
						{
							SymbolTableEntry ste = getVariable( var);
							if( dd == "int" )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =i " + val);
							}
							else if( dd == "float" )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =f " + val);
							}
							else if( dd == "bool" )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =b " + val);
							}
							else if( dd == "char" )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =c " + val);
							}
							else if( dd == "string" )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =s " + val);
							}
							else if( dd[0] != '*' )
							{
								appendCode(ste.name + "_" + to_string(ste.scope) + " =v " + val);
							}

							if( dd[0] == '*' )
							{
								appendCode(ste.name+ "_" + to_string(ste.scope) + " =i " + val);
							}
						}
					}

					if( parseDebug == 1 )
					{
						cout << "declaration -> identifier = expression" << endl;
					}
				}

			| stars IDENTIFIER 
				{
					declevels.clear();
				}

			brackets			
				{							
					string var($<str>2);
					string arrayInit = "array " + var + "_" + to_string(scopeStack.top()) + " " + to_string(getActualSize(dtype)) + " ";
					
					for( int i = 0 ; i < declevels.size() ; i++ )
					{
						string temp = "_" + var + "_" + to_string(scopeStack.top()) + "_" + to_string(i+1); 
						appendCode(temp + "_" + to_string(scopeStack.top()) + " =i " + declevels[i]);
						arrayInit += temp + "_" + to_string(scopeStack.top()) + " ";
						declevels[i] = temp;
					
					}
					appendCode(arrayInit);
					
					if( insertVariable(var, dtype, declevels ) == -1 )
					{
						cout << "COMPILETIME ERROR: Redeclaration of an already existing variable " << var << endl;
						cout << "At line : " << yylineno << endl;
					}

					if( parseDebug == 1 )
					{
						cout << "declaration -> identifier" << endl;
					}
				}
			;

	stars
		:	'*' stars
				{
					if( parseDebug == 1 )
					{
						cout << "stars -> '*' stars" << endl;
					}
					starsCount++;
				}
		|

		;

	brackets
		:	'[' expression ']'
				{
					string type($<var.type>2);
					declevels.push_back($<var.addr>2);
					
					if( type != "int" )
					{
						cout << "COMPILETIME ERROR: cannot use non-int values as sizes for arrays" << endl;
						cout << "At line : " << yylineno << endl;
					}
					
				}

			brackets

			| '[' expression ']'
				{
					string type($<var.type>2);
					declevels.push_back($<var.addr>2);
					
					if( type != "int" )
					{
						cout << "COMPILETIME ERROR: cannot use non-int values as sizes for arrays" << endl;
						cout << "At line : " << yylineno << endl;
					}
				}
			;
	

	conditional_expression
		:	IF '(' expression ')'
				{
					string expr($<var.addr>3);

					string label1 = getLabel();
					$<str>1 = getCharArray(label1);

					string label2 = getLabel();
					ifgoto.push(label2);

					appendCode("if ( " + expr + " !=b #true ) goto " + label1);
				}

			'{' 
				{
					currentScope++;
					scopeStack.push(currentScope);
					$<intval>5 = scopeStack.top();
				}

			statement_list 
				{
					appendCode("goto " + ifgoto.top());
					appendCode(string($<str>1) + ":");
				}

			'}'								
				{
					scopeStack.pop();
					
					if( symbolDebug == 1 )
					{
						printSymbolTable();
					}
				}

			else_statement
				{
					if( parseDebug == 1 )
					{
						cout << "conditional expression -> if(expression) statement_block else_statement" << endl;
					}
				}
			;
	
	else_statement
		:	ELIF '(' expression ')' 
				{
					string expr($<var.addr>3);
					string label1 = getLabel();
					$<str>1 = getCharArray(label1);

					appendCode("if ( " + expr + " !=b #true ) goto " + label1);
				}
			'{' 
				{
					currentScope++;
					scopeStack.push(currentScope);
					$<intval>5 = scopeStack.top();
				}
								
			statement_list					
				{
					appendCode("goto " + ifgoto.top());
					appendCode(string($<str>1) + ":");
				}

			'}'
				{
					scopeStack.pop();
					if( symbolDebug == 1 )
					{
						printSymbolTable();
					}
				}

			else_statement					
				{
					if( parseDebug == 1 )
					{
						cout << "else_statement -> elif(expression) statment_block else_statement" << endl;
					}
				}
				
			| ELSE '{' 
											
				{
					currentScope++;
					scopeStack.push(currentScope);
					$<intval>2 = scopeStack.top();
				}

			statement_list					
				{
					appendCode(ifgoto.top() + ":");
					ifgoto.pop();
					if( parseDebug == 1 )
					{
						cout << "else_statement -> else statem_block" << endl;
					}
				}

			'}'
				{
					scopeStack.pop();
					if( symbolDebug == 1 )
					{
						printSymbolTable();
					}
				}

			|			
				{
					appendCode(ifgoto.top() + ":");
					ifgoto.pop();
					if( parseDebug == 1 )
					{
						cout << "else_statement -> null" << endl;
					}
				}
	
	statement
		: 	assignment_expression ';'
			| declaration_expression ';'
			| conditional_expression
			| for_expression
			| expression ';'
			| IO_statement ';'
			| flow_control_statements ';'
			| RETURN expression ';'
				{
					string returnVal($<var.addr>2);
					appendCode("return " + returnVal);
					
					if( parseDebug == 1 )
					{
						cout << "statement -> return expression" << endl;
					}
				}

			| RETURN ';'
				{
					appendCode("return");
					
					if( parseDebug == 1 )
					{
						cout << "statement -> return" << endl;
					}
				}
			| error ';'
			;
	
	flow_control_statements
		:	BREAK				
				{
					if( forNext.empty() == true )
					{
						cout << "COMPILETIME ERROR: cannot use break outside for loop" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("goto " + forNext.top());
					}
				}

			| CONTINUE
				{
					if( forIncrement.empty() == true )
					{
						cout << "COMPILETIME ERROR: cannot use continue outside for loop" << endl;
						cout << "At line : " << yylineno << endl;
					}
					else
					{
						appendCode("goto " + forIncrement.top());
					}
				}
			;

	IO_statement
		:	print_statement
			| scan_statement
			;

	scan_statement
		:	unary_expression '=' SCAN '('')'
				{
					string name = string($<var.addr>1);
					if( string($<var.type>1) == "int" )
					{
						appendCode("scan int " + name);
					}
					else if( string($<var.type>1) == "char" )
					{
						appendCode("scan char " + name);
					}
					else if( string($<var.type>1) == "float" )
					{
						appendCode("scan float " + name);
					}
					else if( string($<var.type>1) == "string" )
					{
						appendCode("scan string " + name);
					}
					else
					{
						cout << "COMPILETIME ERROR: Cannot scan datatype " << string($<var.type>1) << endl;
						cout << "At Line " << yylineno << endl;
					}
				}	
			;

	print_statement
		:	PRINT '(' print_args ')'	
				{
					appendCode("print newline");
				}

			| PRINT '(' ')'
				{
					appendCode("print newline");
				}

			| PRINTS '(' print_args ')'
			;
	
	print_args
		:	expression ','		
				{
					if( string($<var.type>1) == "int" )
					{
						appendCode("print int " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "char" )
					{
						appendCode("print char " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "float" )
					{
						appendCode("print float " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "string" )
					{
						appendCode("print string " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "bool" )
					{
						appendCode("print bool " + string($<var.addr>1));
					}
					else if( string($<var.type>1)[0] == '*' )
					{
						appendCode("print int " + string($<var.addr>1));
					}
					else
					{
						cout << "COMPILETIME ERROR: Cannot print Expression of type " << string($<var.type>1) << endl;
						cout << "At Line " << yylineno << endl;
					}
				}

			print_args

			| expression
				{
					if( string($<var.type>1) == "int" )
					{
						appendCode("print int " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "char" )
					{
						appendCode("print char " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "float" )
					{
						appendCode("print float " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "string" )
					{
						appendCode("print string " + string($<var.addr>1));
					}
					else if( string($<var.type>1) == "bool" )
					{
						appendCode("print bool " + string($<var.addr>1));
					}
					else if( string($<var.type>1)[0] == '*' )
					{
						appendCode("print int " + string($<var.addr>1));
					}
					else
					{
						cout << "COMPILETIME ERROR: Cannot print Expression of type " << string($<var.type>1) << endl;
						cout << "At Line " << yylineno << endl;
					}
				}
			;

	for_expression
		:	FOR '(' 
				{
					currentScope++;
					scopeStack.push(currentScope);
					$<intval>2 = scopeStack.top();
				}

			loop_initialization_list  ';' 
				{
					string start = getLabel();
					$<str>1 = getCharArray(start);
					appendCode(start + ":");
				}

			loop_condition ';'				
				{
					string expr = forExprVal;

					string statementstart = getLabel();

					string incrementstart = getLabel();
					forIncrement.push(incrementstart);

					string endfor = getLabel();
					forNext.push(endfor);

					$<str>4 = getCharArray(statementstart);
					$<var.addr>6 = getCharArray(incrementstart);
					$<var.type>6 = getCharArray(endfor);

					appendCode("if ( " + expr + " !=b #true ) goto " + endfor);
					appendCode("goto " + statementstart);
					appendCode(incrementstart + ":");
				}

			loop_increment_list 			
				{
					appendCode("goto " + string($<str>1));
					appendCode(string($<str>4) + ":");
				}

			')' '{' statement_list 			
				{
					appendCode("goto " + string($<var.addr>6));
					appendCode(string($<var.type>6) + ":");
					
					if( parseDebug == 1 )
					{
						cout << "forstatemet -> completed" << endl;
					}
				}

			'}'								
				{
					scopeStack.pop();
					forIncrement.pop();
					forNext.pop();
				}
			;

	loop_initialization_list										
		:	assignment_expression ',' loop_initialization_list			
				{
					if( parseDebug == 1 )
					{
						cout << "loop_init -> assignmentexpression , loop_init" << endl;
					}
				}

			| assignment_expression
				{
					if( parseDebug == 1 )
					{
						cout << "loop_init -> assignmentexpression" << endl;
					}
				}

			| declaration_expression		
				{
					if( parseDebug == 1 )
					{
						cout << "loop_init -> declaration" << endl;
					}
				}

			|
				{
					if( parseDebug == 1 )
					{
						cout << "loop_init -> NULL" << endl;
					}
				}
			;
	
	loop_condition
		: 	expression						
				{
					if( strcmp($<var.type>1, "bool") != 0 )
					{
						cout << "COMPILETIME ERROR: non-boolean expression is being used as loop condition" << endl;
					}

					forExprVal = string($<var.addr>1);

					if( parseDebug == 1 )
					{
						cout << "loop_condition -> expression" << endl;
					}
				}

			|
				{
					forExprVal = string(getTemp("bool"));
					appendCode(forExprVal + " = #true");

					if( parseDebug == 1 )
					{
						cout << "loop_condition -> NULL" << endl;
					}
				}
			;
	
	loop_increment_list
		:	expression ',' loop_increment_list	
				{
					if( parseDebug == 1 )
					{
						cout << "loop_incr -> expression , loop_incr" << endl;
					}
				}

			| expression					
				{
					if( parseDebug == 1 )
					{
						cout << "loop_incr -> expression" << endl;
					}
				}

			| 
				{
					if( parseDebug == 1 )
					{
						cout << "loop_incr -> expression" << endl;
					}
				}
			;

	statement_list
		: 	statement statement_list
			| statement
			;

	begin:
		{
			currentStruct = "main";
			insertStruct(currentStruct);
		}
		blocks
		;

	blocks:
		block blocks
		| 
		;
	
	block:
		functionPrefix
		| struct_declaration
		;

	struct_declaration
		:	VAR IDENTIFIER '{' 
				{
					string structName = string($<str>2);
					insertStruct( structName );
					currentStruct = structName;
					currentScope++;
					scopeStack.push(currentScope); 
				}

			attributes '}'
				{
					scopeStack.pop();
					currentStruct = "main";
					
					if( parseDebug == 1 )
					{
						cout << "struct _declaration -> var identifier '{' attributes '}'" << endl;
					}
				}
		;

	attributes
		:	functionPrefix attributes
				{
					if( parseDebug == 1 )
					{
						cout << "attributes -> functionPrefix attributes" << endl;
					}
				}

			| attribute attributes
				{
					if( parseDebug == 1 )
					{
						cout << "attributes -> attribute attributes" << endl;
					}
				}
			|
		;
	
	attribute
		:	type_name stars IDENTIFIER ';'
				{
					string dd = dtype;
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dd = "*" + dd;
					}
					starsCount = 0;
					dlevels = 0;
					vector<string> levels;
					
					for( int i = 1 ; i <= dlevels; i++ )
					{
						levels.push_back(string($<str>3) + "_" + to_string(scopeStack.top()) + "_" + to_string(i));
					}
					int res = insertAttribute( currentStruct, string($<str>3), dd, levels);
					if( res == -2 )
					{	
						cout << "COMPILETIME ERROR: Attribute with the given name already exists" << endl;
					}
					else if( res == -1 )
					{
						cout << "COMPILETIME ERROR: Attribute declaration prohibited" << endl;
					}
					
					if( parseDebug == 1 )
					{
						cout << "attribute -> typename stars identifier dimensions" << endl;
					}
				}
		;
	
	dimensions:
		'['']' dimensions	
				{
					dlevels++;
				}
		|
		;

	functionPrefix:
		VOID MAIN '(' ')'
				{
					int res = insertFunction(currentStruct, "void", "main", 0);
					if( res == -2 )
					{
						cout << "COMPILETIME ERROR: " << "Redefinition of the function main" << endl;
					}
					else if( res == -1 )
					{
						cout << "COMPILETIME ERROR: " << "Function Declaration prohibited" << endl;
					}
					else
					{
						currentFunction = "main";

						string label = getLabel();
						appendCode(label + ":");
						setLabel(currentFunction, label);
						appendCode("function start " + currentStruct + "." + currentFunction);
						appendCode("setReturn");
					}
					if( parseDebug == 1 )
					{
						cout << "function -> void main" << endl;
					}
				}

		statement_block							
				{
					appendCode("return");
				}

		| VOID stars IDENTIFIER '('
				{
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dtype = "*" + dtype;
					}
					starsCount = 0;

					string fname = string($<str>3);
					int res = insertFunction(currentStruct, "void", fname, 0);
					if( res == -2 )
					{
						cout << "COMPILETIME ERROR: " << "Redefinition of the function " << fname << endl;
					}
					else if( res == -1 )
					{
						cout << "COMPILETIME ERROR: " << "Function Declaration prohibited" << endl;
					}
					else
					{
						currentFunction = fname;
						currentScope++;
						scopeStack.push(currentScope);
					}
				}
		functionSuffix

		| type_name stars IDENTIFIER '('
				{
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dtype = "*" + dtype;
					}
					starsCount = 0;
					
					string fname = string($<str>3);
					int res = insertFunction(currentStruct, dtype, fname, 0);
					if( res == -2 )
					{
						cout << "COMPILETIME ERROR: " << "Redefinition of the function " << fname << endl;
					}
					else if( res == -1 )
					{
						cout << "COMPILETIME ERROR: " << "Function Declaration prohibited" << endl;
					}
					else
					{
						currentFunction = fname;
						currentScope++;
						scopeStack.push(currentScope);
					}
				}

		functionSuffix
		;
	
	functionSuffix:
		functionArguements ')'
				{
					resolveArrays(currentStruct, currentFunction);
					currentScope--;
					scopeStack.pop();
					string label = getLabel();
					appendCode(label + ":");
					setLabel(currentFunction, label);
					appendCode("function start " + currentStruct + "." + currentFunction);
					appendCode("setReturn");
				}

		statement_block							
				{
					appendCode("return");
				}

		| ')'									
				{
					resolveArrays(currentStruct, currentFunction);
					currentScope--;
					scopeStack.pop();
					string label = getLabel();
					appendCode(label + ":");
					setLabel(currentFunction, label);
					appendCode("function start " + currentStruct + "." + currentFunction);
					appendCode("setReturn");
				}

		statement_block							
				{
					appendCode("return");
				}
		;

	functionArguements:
		type_name stars IDENTIFIER dimensions
				{
					string dd = dtype;
					string var($<str>3);
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dd = "*" + dd;
					}
					starsCount = 0;
					int r = insertParam( var, dd, dlevels );
					if( r == -1 )
					{
						cout << "COMPILETIME ERROR: Redeclaration of an already existing variable" << endl;
						cout << "At line : " << yylineno << endl;
					}
					dlevels = 0;
				}

		| functionArguements ',' type_name stars IDENTIFIER dimensions
				{
					string var($<str>5);
					string dd = dtype;
					for( int i = 0 ; i < starsCount ; i++ )
					{
						dd = "*" + dd;
					}
					starsCount = 0;
					if( insertParam(var, dd, dlevels) == -1 )
					{
						cout << "COMPILETIME ERROR: Redeclaration of an already existing variable" << endl;
						cout << "At line : " << yylineno << endl;
					}
					dlevels = 0;
				}
		;

	statement_block
		:	'{' 						
				{
					currentScope++;
					scopeStack.push(currentScope);
					$<intval>1 = scopeStack.top();
				}

			statement_list	'}'			
				{
					scopeStack.pop();
					
					if( parseDebug == 1 )
					{
						cout << "statement_block -> { statementlist }" << endl;
					}
				}
											
			| '{' '}'					{
												if( parseDebug == 1 )
												{
													cout << "statementblock -> {}" << endl;
												}
										}
			;
%%


int main( int argcount, char* arguements[] )
{
	yyin = fopen(arguements[1], "r");
	int i = yyparse();

	string filename(arguements[1]);

	if( i != 0 )
	{
		return 0;
	}
	
	string file = "file.temp";
	ofstream Myfile(file);

	string functionFrame = getFunctionFrame();
	bool b = checkMain();
	if( b == false )
	{
		cout << "Main function is not declared" << endl;
		return 1;
	}
	functionFrame += "code starts\nfunCall main.main\ncall " + getFunctionLabel("main", "main") + "\nexit\n";
	TemporaryCode = functionFrame + TemporaryCode;

	Myfile << TemporaryCode;
	Myfile.close();
	return 0;
}
