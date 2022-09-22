#include<string.h> 
#include<iostream>
#include<unordered_map>
#include<vector>
#include<stack>
#include<utility>
#include<unistd.h>
using namespace std;

extern string TemporaryCode;
extern vector<string> declevels;
extern string dtype;
extern stack<string> ifgoto;
extern string forExprVal;
extern int tempint;
extern int strConstInt;
extern stack<string> forIncrement;
extern stack<string> forNext;
extern int labelint;
extern string currentStruct;
extern string currentFunction;
extern int currentScope;
extern stack<int> scopeStack;
extern int dlevels;
extern int starsCount;
extern bool newOrNot;

char* getTemp( string type );
char* getTemp();
string getStringConst();
char* getLabel();

class SymbolTableEntry
{
	public:
		string name;		//name of the variable.
		string dataType;	//dataType of the variable.
		vector<string> levels;		//if it is an array, then this contains the array of variables
									//in which the sizes of those dimensions reside.
		int size;			//size of the variable in bytes	
		bool array;			//bool variable specifying if it is an array or not.
		int scope;			//scope in which it is defined and to which it belongs to.
};

class FunctionTable
{
	public:
		string functionName;
		string label;
		SymbolTableEntry returnValue;
		vector<SymbolTableEntry> parameters;
		vector<SymbolTableEntry> table;

		FunctionTable(string name, string rType, int levelCount );
		FunctionTable();
};

class StructTable
{
	public:
		string structName;
		vector<SymbolTableEntry> attributes;
		vector<FunctionTable> functions;

		StructTable( string name );
		StructTable();
};

extern vector<StructTable> globalTable;
extern stack<SymbolTableEntry> callStack;

int insertStruct( string structName );
int insertAttribute( string structName, string variableName, string dataType, vector<string> levels);
int insertFunction( string returnType, string functionName, int levelCount );
int insertParam( string variableName, string dataType, int levelCount );
int insertVariable( string variableName, string dataType, vector<string> levels);

int insertVariable( string structName, string functionName, string variableName, string dataType, vector<string> levels );
int insertParam( string structName, string functionName, string variableName, string dataType, int levelCount );
int insertFunction( string structName, string returnType, string functionName, int levelCount );

SymbolTableEntry getStructAttribute( string structName, string variableName );
FunctionTable getStructFunction( string structName, string functionName );
SymbolTableEntry getVariable( string variableName );

char* getCharArray( string str );
void appendCode( string statement );
void printSymbolTable();
SymbolTableEntry getFunctionReturnAddress(string structName, string functionName);
string getFunctionFrame();
int setLabel(string functionName, string label);
string getFunctionLabel(string structName, string functionName );
void setCallStack(string structName, string functionName);
bool checkMain();
void printScopeStack();
int getSize( string dataType );
int getActualSize( string dataType );
int getAttributeOffset( string structName, string attributeName );
bool checkStruct( string structName );
void resolveArrays( string structName, string functionName );



/*
int insertEntry( string variableName, string dataType , vector<string> levels, bool array);
int insertFunction( string returnType, string functionName );
void printSymbolTable();
symbolTableEntry getEntry(string name );
void appendCode( string statement );
void insertCurrentSymbolTable();
symbolTableEntry getFunctionReturnAddress(string functionName);
*/
