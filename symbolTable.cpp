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

string TemporaryCode = ""; 
string functionFrame = "";
vector<string> declevels;
string dtype;
int dlevels;
stack<string> ifgoto;
string forExprVal;
int tempint = 1;
int strConstInt = 1;
stack<string> forIncrement;
stack<string> forNext;
int labelint = 1;
string currentStruct;
string currentFunction;
int currentScope = 0;
int starsCount = 0;
bool newOrNot = false;
stack<int> scopeStack;
stack<SymbolTableEntry> callStack;


//returns the name of a new temp variable, and also declares it as a variable in the temp code.
char* getTemp( string type )
{
	string temp = "_t" + to_string(tempint);
	vector<string> levels;
	insertVariable(temp, type, levels);
	temp += "_" + to_string(scopeStack.top());
	char* t = (char*) malloc((temp.length()-1)*sizeof(char));
	strcpy(t, temp.c_str());
	tempint++;		//increment tempint so that next time new temp variable is created.
	//appendCode(type + " " + temp);		//add the declaration
	return t;
}

//this one does the same thing except that it does not declare the variable.
char* getTemp()
{
	string temp = "_t" + to_string(tempint);
	vector<string> levels;
	insertVariable(temp, "int", levels);
	temp += "_" + to_string(scopeStack.top());
	char* t = (char*) malloc((temp.length()-1)*sizeof(char));
	strcpy(t, temp.c_str());
	tempint++;
	return t;
}

string getStringConst()
{
	string temp = "_s" + to_string(strConstInt);
	strConstInt++;
	return temp;
}

//returns a new label address, similar to the generating temp variables.
char* getLabel()
{
	string temp = "label" + to_string(labelint);
	char* t = (char*) malloc((temp.length()-1)*sizeof(char));
	strcpy(t, temp.c_str());
	labelint++;
	return t;
}


vector<StructTable> globalTable;


int getSize( string dataType )
{
	int size = 0;
	if( dataType == "char" )
	{
		size = 4;
	}
	else if( dataType == "int" )
	{
		size = 4;
	}
	else if( dataType == "string" )
	{
		size = 4;
	}
	else if( dataType == "bool" )
	{
		size = 4;
	}
	else if( dataType == "float" )
	{
		size = 4;
	}
	else if( dataType == "void" )
	{
		size = 4;
	}
	else if( dataType[0] == '*' )
	{
		size = 4;
	}
	else
	{
		for( int i = 0 ; i < globalTable.size() ; i++ )
		{
			if( globalTable[i].structName == dataType )
			{
				vector<SymbolTableEntry> table = globalTable[i].attributes;
				for( int j = 0 ; j < table.size() ; j++ )
				{
					size += getSize(table[j].dataType);
				}
			}
		}
	}
	return size;
}

int getActualSize( string dataType )
{
	int size = 0;
	if( dataType == "char" )
	{
		size = 1;
	}
	else if( dataType == "int" )
	{
		size = 4;
	}
	else if( dataType == "string" )
	{
		size = 4;
	}
	else if( dataType == "bool" )
	{
		size = 1;
	}
	else if( dataType == "float" )
	{
		size = 4;
	}
	else if( dataType[0] == '*' )
	{
		size = 4;
	}
	else
	{
		for( int i = 0 ; i < globalTable.size() ; i++ )
		{
			if( globalTable[i].structName == dataType )
			{
				vector<SymbolTableEntry> table = globalTable[i].attributes;
				for( int j = 0 ; j < table.size() ; j++ )
				{
					size += getActualSize(table[j].dataType);
				}
			}
		}
	}
	return size;
}
void printSymbolTable()
{
	cout << "Printing Symbol Table:" << endl;
	cout << endl;
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		cout << "StructName = " << globalTable[i].structName << endl;
		cout << "Attributes = " << endl;
		cout << "name\tdatatype\tscope\tsize\tlevels" << endl;

		vector<SymbolTableEntry> table = globalTable[i].attributes;
		for( int j = 0 ; j < table.size() ; j++ )
		{
			cout << table[j].name << "\t" << table[j].dataType << "\t\t" << table[j].scope << "\t" << table[j].size << "\t";
			for( int k = 0 ; k < table[j].levels.size() ; k++ )
			{
				cout << table[j].levels[k] << " ";
			}
			cout << endl;
		}
		cout << endl;
		cout << "Functions" << endl;

		vector<FunctionTable> functionTable = globalTable[i].functions;
		for( int f = 0 ; f < functionTable.size() ; f++ )
		{
			cout << "Function = " << functionTable[f].functionName << endl;
			cout << "Parameters = " << endl;

			table = functionTable[f].parameters;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				cout << table[j].name << "\t" << table[j].dataType << "\t\t" << table[j].scope << "\t" << table[j].size << "\t";
				for( int k = 0 ; k < table[j].levels.size() ; k++ )
				{
					cout << table[j].levels[k] << " ";
				}
				cout << endl;
			}
			cout << endl;

			cout << "Variables = " << endl;
			table = functionTable[f].table;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				cout << table[j].name << "\t" << table[j].dataType << "\t\t" << table[j].scope << "\t" << table[j].size << "\t";
				for( int k = 0 ; k < table[j].levels.size() ; k++ )
				{
					cout << table[j].levels[k] << " ";
				}
				cout << endl;
			}
			cout << endl;
			cout << "return = " << endl;

			cout << functionTable[f].returnValue.name << "\t" << functionTable[f].returnValue.dataType << "\t\t" << functionTable[f].returnValue.scope << "\t" << functionTable[f].returnValue.size << "\t";

			for( int k = 0 ; k < functionTable[f].returnValue.levels.size() ; k++ )
			{
				cout << functionTable[f].returnValue.levels[k] << " ";
			}
			cout << endl;
			cout << "label = " << functionTable[f].label << endl;
			cout << endl;
		}
	}
}

StructTable::StructTable( string name )
{
	structName = name;
	vector<SymbolTableEntry>* attr = new vector<SymbolTableEntry>;
	attributes = *attr;
	vector<FunctionTable>* func = new vector<FunctionTable>;
	functions = *func;
}

StructTable::StructTable()
{
}

FunctionTable::FunctionTable( string name, string rType, int levelCount )
{
	functionName = name;

	SymbolTableEntry* ste = new SymbolTableEntry();

	(*ste).name = "_" + name;

	(*ste).dataType = rType;
	(*ste).size = getSize(rType);
	if( scopeStack.size() == 0 )
	{
		(*ste).scope = 0;
	}
	else
	{
		(*ste).scope = scopeStack.top();
	}

	vector<string> levels;

	for( int level = 0 ; level < levelCount ; level++ )
	{
		string temp = "_" + (*ste).name + "_" + to_string((*ste).scope) + "_" + to_string(level+1);
		levels.push_back(temp);
	}

	(*ste).levels = levels;

	returnValue = (*ste);

	vector<SymbolTableEntry>* param = new vector<SymbolTableEntry>;
	parameters = *param;

	vector<SymbolTableEntry>* t = new vector<SymbolTableEntry>;
	table = *t;
}

FunctionTable::FunctionTable()
{
}

int insertStruct( string structName )
{
	StructTable* table = new StructTable( structName );
	globalTable.push_back(*table);
	return 1;
}

int getAttributeOffset( string structName, string attributeName )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			int k = 0;
			vector<SymbolTableEntry> table = globalTable[i].attributes;

			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].name == attributeName )
				{
					return k;
				}
				else
				{
					k += table[j].size;
				}
			}
		}
	}
	return 0;
}

int insertAttribute( string structName, string variableName, string dataType, vector<string> levels)
{
	SymbolTableEntry* ste = new SymbolTableEntry();
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<SymbolTableEntry> table = globalTable[i].attributes;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].name == variableName and table[j].scope == currentScope )
				{
					return -2;
				}
			}
			(*ste).name = variableName;
			(*ste).dataType = dataType;
			(*ste).size = getSize(dataType);
			(*ste).levels = levels;
			if( scopeStack.size() == 0 )
			{
				(*ste).scope = 0;
			}
			else
			{
				(*ste).scope = scopeStack.top();
			}
			globalTable[i].attributes.push_back(*ste);
			return 1;
		}
	}
	return -1;
}

int insertFunction( string structName, string returnType, string functionName, int levelCount )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{
					return -2;
				}
			}
			FunctionTable* func = new FunctionTable(functionName, returnType, levelCount );
			globalTable[i].functions.push_back(*func);


			SymbolTableEntry returnSte = getFunctionReturnAddress( structName, functionName );
			vector<string> levels = returnSte.levels;

			for( int level = 0 ; level < levels.size() ; level++ )
			{
				cout << levels[level] << endl;
				vector<string> sizeLevels;
				int re = insertVariable(structName, functionName, levels[level], "int", sizeLevels);
				cout << "re = " << re << endl;
			}
			if( structName != "main" )
			{
				insertParam( structName, functionName, "this", "int", 0);
			}
			return 1;
		}
	}
	return -1;
}

int insertParam( string structName, string functionName, string variableName, string dataType, int levelCount )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{
					vector<SymbolTableEntry> param = table[j].parameters;
					for( int k = 0 ; k < param.size() ; k++ )
					{
						if( param[k].name == variableName and param[k].scope == currentScope )
						{
							return -3;
						} 
					}
					SymbolTableEntry* ste = new SymbolTableEntry();

					(*ste).name = variableName;
					(*ste).dataType = dataType;
					(*ste).size = getSize(dataType);

					if( scopeStack.size() == 0 )
					{
						(*ste).scope = 0;
					}
					else
					{
						(*ste).scope = scopeStack.top();
					}

					vector<string> levels;

					for( int level = 0 ; level < levelCount ; level++ )
					{
						string temp = "_" + variableName + "_" + to_string((*ste).scope) + "_" + to_string(level+1);
						levels.push_back(temp);
					}

					for( int level = 0 ; level < levels.size() ; level++ )
					{
						vector<string> sizeLevels;
						//insertVariable(structName, functionName, levels[level], "int", sizeLevels);
					}
					(*ste).levels = levels;
					globalTable[i].functions[j].parameters.push_back(*ste);

					for( int level = 0 ; level < levelCount ; level++ )
					{
						insertParam( structName, functionName, levels[level], "int", 0 );
					}
					//insertVariable( structName, functionName, variableName, dataType, levels);
					return 1;
				}
			}
			return -2;
		}
	}
	return - 1;
}

int insertVariable( string structName, string functionName, string variableName, string dataType, vector<string> levels, int b )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{
					vector<SymbolTableEntry> param = table[j].table;
					for( int k = 0 ; k < param.size() ; k++ )
					{
						if( param[k].name == variableName and param[k].scope == currentScope )
						{
							return -3;
						} }
					SymbolTableEntry* ste = new SymbolTableEntry();

					(*ste).name = variableName;
					(*ste).dataType = dataType;
					(*ste).size = getSize(dataType);
					(*ste).levels = levels;
					(*ste).scope = b;
					globalTable[i].functions[j].table.push_back(*ste);
					return 1;
				}
			}
			return -2;
		}
	}
	return - 1;
}

void resolveArrays( string structName, string functionName )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					for( int k = 0 ; k < table[j].parameters.size() ; k++ )
					{
						insertVariable( structName, functionName, table[j].parameters[k].name, table[j].parameters[k].dataType, table[j].parameters[k].levels, table[j].parameters[k].scope);
					}

					for( int k = 0 ; k < table[j].parameters.size() ; k++ )
					{
						for( int l = 0 ; l < table[j].parameters[k].levels.size() ; l++ )
						{
							vector<string> le;
							insertVariable( structName, functionName, table[j].parameters[k].levels[l], "int", le );
						}
					}
				}
			}
		}
	}
}

int insertVariable( string structName, string functionName, string variableName, string dataType, vector<string> levels )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{
					vector<SymbolTableEntry> param = table[j].table;
					for( int k = 0 ; k < param.size() ; k++ )
					{
						if( param[k].name == variableName and param[k].scope == currentScope )
						{
							return -3;
						} }
					SymbolTableEntry* ste = new SymbolTableEntry();

					(*ste).name = variableName;
					(*ste).dataType = dataType;
					(*ste).size = getSize(dataType);
					(*ste).levels = levels;
					for( int level = 0 ; level < levels.size() ; level++ )
					{
						vector<string> sizeLevels;
						insertVariable(structName, functionName, levels[level], "int", sizeLevels);
					}
					if( scopeStack.size() == 0 )
					{
						(*ste).scope = 0;
					}
					else
					{
						(*ste).scope = scopeStack.top();
					}
					globalTable[i].functions[j].table.push_back(*ste);
					return 1;
				}
			}
			return -2;
		}
	}
	return - 1;
}

int insertFunction( string returnType, string functionName, int levelCount )
{
	return insertFunction( currentStruct,  returnType, functionName, levelCount );
}

int insertParam( string variableName, string dataType, int levelCount )
{
	return insertParam( currentStruct, currentFunction, variableName, dataType, levelCount ); 
}

int insertVariable( string variableName, string dataType, vector<string> levels )
{
	return insertVariable( currentStruct, currentFunction, variableName, dataType, levels);
}

SymbolTableEntry getStructAttribute( string structName, string variableName ) 
{ 
	SymbolTableEntry ste;
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<SymbolTableEntry> table = globalTable[i].attributes;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].name == variableName )
				{ 
					ste = table[j];
				}
			}
		}
	}
	return ste;
}

FunctionTable getStructFunction( string structName, string functionName )
{
	FunctionTable funcTable;
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					funcTable = table[j];
				}
			}
		}
	}
	return funcTable;
}

SymbolTableEntry getFunctionReturnAddress( string structName, string functionName )
{
	FunctionTable tab = getStructFunction( structName , functionName );
	return tab.returnValue;
}

SymbolTableEntry  getVariable( string structName, string functionName, string variableName )
{
	if( variableName.substr(0, 5) == "this." )
	{
		variableName = variableName.substr(5, variableName.size());
	}
	SymbolTableEntry ste;
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					vector<SymbolTableEntry> tab = table[j].table;

					bool b = true;
					int scope = 0;

					for( int k = 0 ; k < tab.size() ; k++ )
					{
						if( tab[k].name == variableName )
						{
							if( b )
							{
								stack<int> sk;
								while( !scopeStack.empty() )
								{
									int n = scopeStack.top();
									if( tab[k].scope == n )
									{
										ste = tab[k];
										b = false;
									}
									scopeStack.pop();
									sk.push(n);
								}

								while( !sk.empty() )
								{
									int n = sk.top();
									sk.pop();
									scopeStack.push(n);
								}
							}
							else
							{
								if( tab[k].scope > ste.scope )
								{
									stack<int> sk;
									while( !scopeStack.empty() )
									{
										int n = scopeStack.top();
										if( tab[k].scope == n )
										{
											ste = tab[k];
										}
										scopeStack.pop();
										sk.push(n);
									}

									while( !sk.empty() )
									{
										int n = sk.top();
										sk.pop();
										scopeStack.push(n);
									}
								}
							}
						}
					}
				}
			}
			if( ste.name == "" )
			{
				vector<SymbolTableEntry> tab = globalTable[i].attributes;
				for( int k = 0 ; k < tab.size() ; k++ )
				{
					if( tab[k].name == variableName )
					{
						ste = tab[k];
						ste.name = "this." + ste.name;
					}
				}
			}
		}
	}
	return ste;
}

SymbolTableEntry  getVariable( string variableName )
{
	return getVariable( currentStruct, currentFunction, variableName );
}

void appendCode( string statement )
{
	TemporaryCode += statement + "\n";
}

string getFunctionFrame()
{
	string res = "";

	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		res += "struct start " + globalTable[i].structName + "\n\n";

		vector<SymbolTableEntry> table = globalTable[i].attributes;
		for( int j = 0 ; j < table.size() ; j++ )
		{
			res += table[j].dataType + " " + to_string(table[j].size) + " " + table[j].name + "_" + to_string(table[j].scope) + " ";
			for( int k = 0 ; k < table[j].levels.size() ; k++ )
			{
				res += table[j].levels[k] + " ";
			}
			res += "\n";
		}

		vector<FunctionTable> functionTable = globalTable[i].functions;
		for( int f = 0 ; f < functionTable.size() ; f++ )
		{
			res += "function start " + functionTable[f].functionName + "\n\n";

			res += functionTable[f].returnValue.dataType + " " + to_string(functionTable[f].returnValue.size) + " " + functionTable[f].returnValue.name + "_" + to_string(functionTable[f].returnValue.scope) + " ";

			for( int k = 0 ; k < functionTable[f].returnValue.levels.size() ; k++ )
			{
				res += functionTable[f].returnValue.levels[k] + " ";
			}
			res += "\n";

			table = functionTable[f].parameters;
			res += "param start\n";
			for( int j = 0 ; j < table.size() ; j++ )
			{
				res += table[j].dataType + " " + to_string(table[j].size) + " " + table[j].name + "_" + to_string(table[j].scope) + " ";
				for( int k = 0 ; k < table[j].levels.size() ; k++ )
				{
					res += table[j].levels[k] + " ";
				}
				res += "\n";
			}
			res += "param end\n";

			table = functionTable[f].table;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				res += table[j].dataType + " " + to_string(table[j].size) + " " + table[j].name + "_" + to_string(table[j].scope) + " ";
				for( int k = 0 ; k < table[j].levels.size() ; k++ )
				{
					res += table[j].levels[k] + " ";
				}
				res += "\n";
			}
			res += "\nfunction end\n";
		}
		res += "\nstruct end\n\n";
	}
	return res;
}

int setLabel( string functionName, string label )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == currentStruct )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					globalTable[i].functions[j].label = label;
					return 1;
				}
			}
		}
	}
	return -1;
}

string getFunctionLabel( string structName, string functionName )
{
	string label = "";
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					label = table[j].label;
				}
			}
		}
	}
	return label;
}

void setCallStack( string structName, string functionName )
{
	while( !callStack.empty() )
	{
		callStack.pop();
	}
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == functionName )
				{ 
					for( int k = table[j].parameters.size()-1 ; k >= 0  ; k-- )
					{
						callStack.push(table[j].parameters[k]);
					}
				}
			}
		}
	}
	return;
}

bool checkMain()
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == "main" )
		{
			vector<FunctionTable> table = globalTable[i].functions;
			for( int j = 0 ; j < table.size() ; j++ )
			{
				if( table[j].functionName == "main" )
				{ 
					return true;
				}
			}
		}
	}
	return false;
}

void printScopeStack()
{
	cout << "stack content starts" << endl;
	stack<int> sk;
	while( !scopeStack.empty() )
	{
		int n = scopeStack.top();
		scopeStack.pop();
		sk.push(n);
	}

	while( !sk.empty() )
	{
		int n = sk.top();
		cout << n << endl;
		sk.pop();
		scopeStack.push(n);
	}
	cout << "stack content ends" << endl;
}

bool checkStruct( string structName )
{
	for( int i = 0 ; i < globalTable.size() ; i++ )
	{
		if( globalTable[i].structName == structName )
		{
			return true;
		}
	}
	return false;
}

char* getCharArray( string str )
{
	char* t = (char*) calloc(str.length(), sizeof(char));

	strcpy(t, str.c_str());

	return t;
}
