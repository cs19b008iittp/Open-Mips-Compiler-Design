#include<iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <cstring>
#include<string.h>
#include<stack>
using namespace std;

struct Var {
	string type;
	int size ;
	string name;
	int global =-1;
};
struct function {
	string name;
	vector<string> parameters;  
	vector<string> variables;
	map <string, struct Var> params;
	map <string, struct Var> vars;
	struct  Var returnValue;
};

struct DS{
	string name;
	map <string, struct Var> attributes;
	map <string, struct function> funcs;
};

map<string, struct DS > m;

void printMap(){
	cout << "Printing Map " << endl;
	for(auto M = m.begin(); M!= m.end(); ++M){
		cout << "Parent Fn : " << M->first << endl;
		struct DS ds = M->second;

		map <string, struct Var> attributes = ds.attributes;
		cout << "Atrributes : " << endl;
		for( auto attr = attributes.begin(); attr != attributes.end(); ++attr){
			cout << "Atribute Name : " << attr->first<< endl;
			struct Var var = attr->second;

			cout << "type : " << var.type << endl;
			cout << "size : " << var.size<< endl;
			cout << "name : " << var.name<< endl;

		}
		map <string, struct function> funcs = ds.funcs;
		cout << "Functions : " << endl;
		for(auto fun = funcs.begin(); fun != funcs.end(); ++fun){
			cout << "funtion name : " << fun->first << endl;

			struct function fn = fun->second;

			cout << "name : " << fn.name << endl;
			cout << "Return value : " << endl;
			struct Var var ;
			var = fn.returnValue;
			cout << "type : " << var.type << endl;
			cout << "size : " << var.size<< endl;
			cout << "name : " << var.name<< endl;

			map <string, struct Var> params = fn.params; 
			cout << "Parameters : " << endl;
			for(auto par = params.begin(); par != params.end(); ++par){
				cout << "parameter name : " << par->first  << endl;
				var = par->second;
				cout << "type : " << var.type << endl;
				cout << "size : " << var.size<< endl;
				cout << "name : " << var.name<< endl;
			}

			map <string, struct Var> vars = fn.vars; 
			cout << "Variables : " << endl;

			for( int i = 0 ; i < fn.variables.size() ; i++ )
			{
				cout << "var name = " << fn.variables[i] << endl;
				var = vars[fn.variables[i]];
				cout << "name\t\tsize\t\ttype\t\t" << endl;
				cout << var.name << "\t\t" << var.size << "\t\t" << var.type << endl;
			}
			cout << endl;
		}
		cout << endl;
	}
}

int getVarSize(string s)
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;
	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> vars = fn.vars;

			size += fn.returnValue.size;

			struct Var var ;
			for(auto v = vars.begin(); v != vars.end(); ++v)
			{
				var = v->second;
				size += var.size;
			}

		}
		else
		{
			cout << "Couldn't find the given fn : c" + child_fn + "c in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : s" + parent_fn + "s in map "<< endl;
		return -1;
	}

	return size;
}

int getVariableSize( string s, string var_name )
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;

	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> vars = fn.vars;
			vector <string> variables = fn.variables;

			int index= 0;
			for(index= 0 ; index < variables.size(); index++)
			{
				if(variables[index] == var_name)
					break;
			}

			if (index != variables.size())
			{
				size = vars[variables[index]].size;
			}
			else 
			{
				cout << "Could'nt find the Variable" << endl;
				return -1;
			}

		}
		else
		{
			cout << "Couldn't find the given fn : $" + child_fn + "$ in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : $" + parent_fn + "$ in map "<< endl;
		return -1;
	}
	return size;
}

int stackAddresses(string s, int pars)
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;


	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> params = fn.params;
			vector <string> parameters = fn.parameters;

			int no_params = parameters.size();
			struct Var var ;
			if(pars > 0 && pars <= no_params)
			{
				var = fn.returnValue;
				size += var.size;
				for(int i =0; pars>0 ; i++)
				{
					size += params.find(parameters[i])->second.size;
					pars--;
				}
			}
			else
			{
				cout << "There are less parameters than given " << endl;
				return -1;
			}
		}
		else
		{
			cout << "Couldn't find the given fn : cc" + child_fn + "cc in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : ss" + parent_fn + "ss in map "<< endl;
		return -1;
	}
	return size;
}

int stackAdressesName(string s, string par)
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;

	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end()){
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> params = fn.params;
			vector <string> parameters = fn.parameters;

			int index= 0;
			for(index= 0 ; index < parameters.size(); index++)
			{
				if(parameters[index] == par)
					break;
			}

			if (index != parameters.size())
			{
				size = stackAddresses(s,index+1);
			}
			else 
			{
				cout << "Could'nt find the parameter" << endl;
				return -1;
			}
		}
		else
		{
			cout << "Couldn't find the given fn : " + child_fn + " in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : " + parent_fn + " in map "<< endl;
		return -1;
	}
	return size;
}


int stackAddressesVars(string s, int var_index)
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;


	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> vars = fn.vars;
			vector <string> variables = fn.variables;

			int no_vars = variables.size();
			struct Var var ;
			if(var_index >= 0 && var_index < no_vars)
			{
				/*
				   var = fn.returnValue;
				   size += var.size;
				   var_index--;
				   for(int i =0; var_index>0 ; i++)
				   {
				   size += vars.find(variables[i])->second.size;
				   var_index--;
				   }
				 */
				size = 4;
				for( int i = variables.size()-1 ; i > var_index ; i-- )
				{
					size += vars.find(variables[i])->second.size;
				}
			}
			else
			{
				cout << "There are less Variables than given " << endl;
				return -1;
			}
		}
		else
		{
			cout << "Couldn't find the given fn : " + child_fn + " in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : " + parent_fn + " in map "<< endl;
		return -1;
	}
	return size;
}

int getArrayOffset( string s, int pars, int sizeno )
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;

	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> params = fn.params;
			vector <string> parameters = fn.parameters;

			int no_params = parameters.size();
			struct Var var ;
			if(pars > 0 && pars <= no_params)
			{
			}
			else
			{
				cout << "There are less parameters than given " << endl;
				return -1;
			}
		}
		else
		{
			cout << "Couldn't find the given fn : cc" + child_fn + "cc in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : ss" + parent_fn + "ss in map "<< endl;
		return -1;
	}
	return size;
}

int stackAdressesVarsName(string s, string var_name)
{
	string parent_fn = "";
	string child_fn = "";

	string word = "";
	for(auto x : s)
	{
		if(x == '.')
		{
			parent_fn = word;
			word = "";
		}
		else
		{
			word += x;
		}
	}
	child_fn = word;

	int size = 0;
	if(m.find(parent_fn)!= m.end())
	{
		struct DS ds = m.find(parent_fn)->second;
		map <string, struct function> funcs = ds.funcs;
		if(funcs.find(child_fn)!= funcs.end())
		{
			struct function fn = funcs.find(child_fn)->second;

			map <string, struct Var> vars = fn.vars;
			vector <string> variables = fn.variables;

			int index= 0;
			for(index= 0 ; index < variables.size(); index++)
			{
				if(variables[index] == var_name)
					break;
			}

			if (index != variables.size())
			{
				size = stackAddressesVars(s,index);
			}
			else 
			{
				cout << "Could'nt find the Variable" << endl;
				return -1;
			}

		}
		else
		{
			cout << "Couldn't find the given fn : $" + child_fn + "$ in funcs map "<< endl;
			return -1;
		}
	}
	else
	{
		cout << "Couldn't find the given struct : $" + parent_fn + "$ in map "<< endl;
		return -1;
	}
	return size;
}

string currentFunc;
string funCall;

string getStackAddr(string str)
{
	if(str.substr(0, 1) == "*")
	{
		int k = stackAdressesVarsName(currentFunc, str.substr(1, str.length()));
		if(k == -1)
		{
			cout<<str<<" K is -1"<<endl;
			exit(-1);
		}
		return to_string(k)+"($sp)";
	}
	int k = stackAdressesVarsName(currentFunc, str);
	if(k == -1)
	{
		cout<<str<<" K is -1"<<endl;
		exit(-1);
	}
	return to_string(k)+"($sp)";
	//return "Nitesh";
}

int getStackAddrNo( string str )
{
	if(str.substr(0, 1) == "*")
	{
		int k = stackAdressesVarsName(currentFunc, str.substr(1, str.length()));
		if(k == -1)
		{
			cout<<str<<" K is -1"<<endl;
			exit(-1);
		}
		return k;
	}
	int k = stackAdressesVarsName(currentFunc, str);
	if(k == -1)
	{
		cout<<str<<" K is -1"<<endl;
		exit(-1);
	}
	return k;
}

int main(int argcount, char* arguments[])
{
	fstream file; 
	vector <vector<string>> v;
	file.open(string(arguments[1]),ios::in); 
	if(file.is_open())
	{
		string s;
		while(getline(file, s))
		{
			if( s == "" )
			{
				continue;
			}
			char s1[s.size()+1];
			strcpy(s1, s.c_str());
			char* token = strtok(s1, " ");

			vector<string> tokens;
			while (token != NULL)
			{

				tokens.push_back(string(token));
				token = strtok(NULL, " ");
			}

			if(tokens[0] == "code" ){
				if(tokens[1] == "starts"){
					break;
				}
			}
			v.push_back(tokens);
		}



		file.close();


		int s_start = 0;
		int s_end = 1;
		int f_start = 0;
		int f_end = 1;

		int p_start = 0;
		int p_end = 1;
		int v_start = 0;
		int v_end = 1;


		string parent_fn = "";
		string child_fn = "";


		for(int i = 0 ; i < v.size(); i++){

			if(v[i][0] == "struct" ){

				if(v[i][1] == "start" ){
					if(s_start == 0 && s_end == 1){
						s_start = 1;
						s_end = 0;
						struct DS ds;
						ds.name = v[i][2];
						parent_fn = v[i][2];
						m.insert({parent_fn, ds});
					}
					else {
						cout << "invalid syntax \n";
						break;
					}
				}
				else if(v[i][1] == "end"){
					if(s_start == 1 && s_end == 0){
						s_start = 0;
						s_end = 1;
						parent_fn = "";
					}
					else{
						cout << "invalid syntax \n";
						break;
					}
				}
			}

			else if(v[i][0] == "function" ){

				if(v[i][1] == "start" ){
					if(s_start == 1 && s_end == 0 && f_start == 0 && f_end == 1){
						f_start = 1;
						f_end = 0;
						child_fn = v[i][2];

						struct DS ds = m.find(parent_fn)->second;

						struct function fn ;
						fn.name = child_fn;

						i++;

						struct Var v1 ;
						v1.type = v[i][0];
						v1.size = stoi(v[i][1]);
						v1.name = v[i][2];

						fn.returnValue = v1;

						ds.funcs.insert({child_fn,fn});
						m.find(parent_fn)->second= ds;

					}
					else {
						cout << "invalid syntax \n";
						break;
					}
				}
				else if(v[i][1] == "end"){
					if(s_start == 1 && s_end == 0 && f_start == 1 && f_end == 0){
						f_start = 0;
						f_end = 1;

						v_start = 0;
						v_end = 1;

						p_start = 0;
						p_end = 1;

						child_fn = "";
					}
					else{
						cout << "invalid syntax \n";
						break;
					}
				}
			}

			else if(v[i][0] == "param" ){
				if(v[i][1] == "start"){

					if(s_start == 1 && s_end == 0 && f_start == 1 && f_end == 0 && p_start == 0 && p_end == 1){
						p_start = 1;
						p_end = 0;
					}
					else {
						cout << "invalid syntax at linenoo : " << i << endl ;
					}
				}
				else  if(v[i][1] == "end"){

					if(s_start == 1 && s_end == 0 && f_start == 1 && f_end == 0 && p_start == 1 && p_end == 0){
						p_start = 0;
						p_end = 1;

						v_start = 1;
						v_end = 0;
					}
					else {
						cout << "invalid syntax at linenooo : " << i << endl ;
					}
				}

				else{
					cout << "booo\n";
				}
			}

			else{
				if(s_start == 1 && s_end == 0 && f_start == 0 && f_end == 1){
					struct DS ds =  m.find(parent_fn)->second;
					struct Var var ;
					var.type = v[i][0];
					var.size = stoi(v[i][1]);
					var.name = v[i][2];
					if(v.size() == 4){
						var.global = stoi(v[i][3]);
					}
					ds.attributes.insert({v[i][2], var});
					m.find(parent_fn)->second = ds;

				}
				else if( p_start == 1 && p_end == 0){

					struct DS ds = m.find(parent_fn)->second;

					struct Var var;
					var.type = v[i][0];
					var.size = stoi(v[i][1]);
					var.name = v[i][2];
					if(v.size() == 4){
						var.global = stoi(v[i][3]);
					}

					if(ds.funcs.find(child_fn) !=ds.funcs.end()){

						ds.funcs.find(child_fn)->second.parameters.push_back(var.name);
						ds.funcs.find(child_fn)->second.params.insert({var.name, var});
						m.find(parent_fn)->second = ds;

					}
					else{
						cout << "Invalid syntax ! at line : " << i << endl;
						break;
					}

				}
				else   if(p_start == 0 && p_end == 1 && v_start == 1 && v_end == 0){

					struct DS ds = m.find(parent_fn)->second;

					struct Var var;
					var.type = v[i][0];
					//cout << "At i = " << i << " v[i][1] : "<< v[i][1] << endl;

					var.size = stoi(v[i][1]);
					var.name = v[i][2];
					if(v.size() == 4){
						cout << "At i = " << i << " v[i][3] : "<< v[i][3] << endl;
						var.global = stoi(v[i][3]);
					}

					if(ds.funcs.find(child_fn) !=ds.funcs.end()){
						ds.funcs.find(child_fn)->second.variables.push_back(var.name);
						ds.funcs.find(child_fn)->second.vars.insert({var.name, var});
						m.find(parent_fn)->second = ds;

					}
					else{
						cout << "Invalid syntax ! at line : " << i << endl;
						break;
					}


				}
				else{
					cout << "invalid syntax at line_no : " << i << endl ;

				}
			}


		}

		//printMap();
		// cout << "Variables size : " << getVarSize("main","main" );
		// cout << stackAddresses("main.fibonacci", 4)<< endl;
		// cout << stackAdressesName("main.fibonacci", "n_5")<< endl << endl;

		// cout << stackAddresses("main.fibonacci", 1)<< endl;
		// cout << stackAdressesName("main.fibonacci", "n_7")<< endl<< endl;

		// cout << stackAddresses("main.fibonacci", 2)<< endl;
		// cout << stackAdressesName("main.fibonacci", "n_3")<< endl<< endl;

		// cout << stackAddresses("main.fibonacci", 3)<< endl;
		// cout << stackAdressesName("main.fibonacci", "n_1")<< endl << endl;



		// cout << stackAddressesVars("main.fibonacci", 7)<< endl;
		// cout << stackAdressesVarsName("main.fibonacci", "_t6_3")<< endl << endl;
	}
	else
	{
		cout << " Unable to open file" ;
	}

	string mc = ".text \n.globl main \nmain:\n";
	string def = ".data\n";

	int looplabel = 1;
	file.open(string(arguments[1]),ios::in); 
	if (file.is_open())
	{  
		int d1 = 0;
		string s;
		vector<string> var;
		int paramCount = 0;
		while(getline(file, s))
		{ 
			if( s == "" )
			{
				continue;
			}
			char s1[s.size()+1];
			strcpy(s1, s.c_str());
			char* token = strtok(s1, " ");
			vector<string> tokens;
			while (token != NULL)
			{

				tokens.push_back(token);
				token = strtok(NULL, " ");
			}
			if(tokens[0] == "code" && tokens[1] == "starts")
			{
				d1 = 1;
				continue;
			}
			if(d1 == 0) continue;

			//cout << s << endl;

			mc += "\n#" + s + "\n";
			if(tokens[0] == "funCall")
			{
				funCall = tokens[1];
				paramCount = 1;
			}
			else if( tokens[0] == "function" and tokens[1] == "start" )
			{
				currentFunc = tokens[2];
			}
			else if(tokens[0] == "call")
			{
				int size = getVarSize(funCall);
				size += 4;
				mc += "addiu $sp, $sp, -" + to_string(size) + "\n";
				mc += "jal " + tokens[1] + "\n";
			}
			else if( tokens[0] == "setReturn" )
			{
				mc += "sw $ra, 0($sp)\n";
			}
			else if( tokens[0] == "param" )
			{
				if( tokens[1][0] == '*' )
				{
					mc += "lw $8, " + getStackAddr(tokens[1]) + "\n";
					mc += "lw $8, ($8)\n";

					int a = stackAddresses( funCall, paramCount );
					mc += "sw $8, -" + to_string(a) + "($sp)\n";
				}
				else
				{
					int noOfLoads = stoi(tokens[2])/4;

					int a = stackAddresses( funCall, paramCount );
					mc += "li $9, 0\n";
					mc += "li $10, -" + to_string(a) + "\n";

					mc += "add $10, $10, $sp\n";

					int b = getStackAddrNo(tokens[1]);
					mc += "li $11, " + to_string(b) + "\n";
					mc += "add $11, $11, $sp\n";
					for( int i = 0 ; i < noOfLoads ; i++ )
					{
						mc += "add $10, $10, $9\n";
						mc += "add $11, $11, $9\n";

						mc += "lw $8, ($11)\n";
						mc += "sw $8, ($10)\n";

						mc += "addi $9, $9, 4\n";
					}
				}

				if( tokens.size() > 3 )
				{
					for( int i = 3 ; i < tokens.size() ; i++ )
					{
						getArrayOffset( funCall, paramCount , i-3 );
					}
				}
				paramCount++;
			}
			else if( tokens.size() == 3 and tokens[2] == "returnVal" )
			{
				int a = getStackAddrNo(tokens[0]);
				int noOfLoads = getVariableSize(currentFunc, tokens[0])/4;

				for( int i = 0 ; i < noOfLoads ; i++ )
				{
					mc += "lw $8 -" + to_string((noOfLoads-i)*4) + "($sp)\n";
					mc += "sw $8 " + to_string(a+i*4) + "($sp)\n";
				}
				/*
				mc += "lw $8, -4($sp)\n";
				string addr = getStackAddr(tokens[0]);
				mc += "sw $8, " + addr + "\n";
				*/
			}
			else if( tokens[0] == "return" )
			{
				mc += "lw $ra, 0($sp)\n";
				if( tokens.size() != 1 )
				{
					//string addr = getStackAddr(tokens[1]);
					int b = getStackAddrNo(tokens[1]);

					int size = getVarSize(currentFunc);
					size += 4;
					//mc += "addiu $sp, $sp, " + to_string(size) + "\n";
					int noOfLoads = getVariableSize(currentFunc, tokens[1])/4;
					for( int i = 0 ; i < noOfLoads ; i++ )
					{
						mc += "lw $" + to_string(8+i) + " " + to_string(b+i*4) + "($sp)\n";
					}

					mc += "addiu $sp, $sp, " + to_string(size) + "\n";

					for( int i = 0 ; i < noOfLoads ; i++ )
					{
						mc += "sw $" + to_string(8+i) + " -" + to_string((noOfLoads - i)*4) + "($sp)\n";
					}
					//mc += "lw $8, " + addr + "\n";
					//mc += "sw $8, -4($sp)\n";
				}
				else if( tokens.size() == 1 )
				{
					int size = getVarSize(currentFunc);
					size += 4;
					mc += "addiu $sp, $sp, " + to_string(size) + "\n";
				}
				mc += "jr $ra\n";
			}
			else if( tokens[0] == "strconst" )
			{
				string temp = tokens[3].substr(1, tokens[3].length());

				for( int i = 4 ; i < tokens.size() ; i++ )
				{
					temp +=  " " + tokens[i];
				}
				def += tokens[1] + ": .asciiz " + temp + "\n";

				string addr = getStackAddr(tokens[2]);

				mc += "la $8, " + tokens[1] + "\n";
				mc += "sw $8, " + addr + "\n";
			}
			else if(tokens[0].substr(tokens[0].size()-1, tokens[0].size()) == ":")
			{
				string lname = tokens[0]; 
				mc += lname+"\n";

			}
			else if(tokens[0] == "goto")
			{
				string gotolabel = tokens[1];
				mc += "j "+gotolabel+"\n";
			}
			else if(tokens[0] == "array")
			{
				mc += "li $8, 1\n";
				string arrayName = getStackAddr(tokens[1]);
				int size = stoi(tokens[2]);

				for( int i = 3 ; i < tokens.size() ; i++ )
				{
					mc += "lw $9, " + getStackAddr(tokens[i]) + "\n";
					mc += "mul $8, $8, $9\n";
				}

				mc += "li $10, " + to_string(size) + "\n";
				mc += "mul $8, $8, $10\n";
				mc += "li $2, 9\n";
				mc += "move $4, $8\n";
				mc += "syscall\n";
				mc += "sw $2, "+arrayName+"\n";
			}
			// else if(tokens[0] == "int")
			// {
			// 	if(tokens.size() > 2 )
			// 	{
			// 		mc += "li $8, 1\n";

			// 		for( int i = 2 ; i < tokens.size() ; i++ )
			// 		{
			// 			mc += "lw $9, " + tokens[i] + "\n";
			// 			mc += "mul $8, $8, $9\n";
			// 		}
			// 		mc += "li $10, 4\n";
			// 		mc += "mul $8, $8, $10\n";
			// 		mc += "li $2, 9\n";
			// 		mc += "move $4, $8\n";
			// 		mc += "syscall\n";
			// 		mc += "sw $2, "+tokens[1]+"\n";
			// 		def += tokens[1] + ": .word 0\n";
			// 	}
			// 	else
			// 	{
			// 		string v = tokens[1];
			// 		def += v + ": .word 0\n";
			// 	}
			// }
			// else if(tokens[0] == "char")
			// {
			// 	if(tokens.size() > 2 )
			// 	{
			// 		mc += "li $8, 1\n";

			// 		for( int i = 2 ; i < tokens.size() ; i++ )
			// 		{
			// 			mc += "lw $9, " + tokens[i] + "\n";
			// 			mc += "mul $8, $8, $9\n";
			// 		}
			// 		mc += "li $10, 1\n";
			// 		mc += "mul $8, $8, $10\n";
			// 		mc += "li $2, 9\n";
			// 		mc += "move $4, $8\n";
			// 		mc += "syscall\n";
			// 		mc += "sw $2, "+tokens[1]+"\n";
			// 		def += tokens[1] + ": .word 0\n";
			// 	}
			// 	else
			// 	{
			// 		string v = tokens[1];
			// 		def += v + ": .word 0\n";
			// 	}
			// }
			// else if(tokens[0] == "float")
			// {
			// 	string v = tokens[1];
			// 	def += v + ": .float 0.0 \n";
			// }
			// else if(tokens[0] == "bool")
			// {
			// 	string v = tokens[1];
			// 	def += v + ": .word 0 \n";
			// }
			// else if( tokens[0] == "string" )
			// {
			// 	if(tokens.size() > 2 )
			// 	{
			// 		mc += "li $8, 1\n";

			// 		for( int i = 2 ; i < tokens.size() ; i++ )
			// 		{
			// 			mc += "lw $9, " + tokens[i] + "\n";
			// 			mc += "mul $8, $8, $9\n";
			// 		}
			// 		mc += "li $10, 4\n";
			// 		mc += "mul $8, $8, $10\n";
			// 		mc += "li $2, 9\n";
			// 		mc += "move $4, $8\n";
			// 		mc += "syscall\n";
			// 		mc += "sw $2, "+tokens[1]+"\n";
			// 		def += tokens[1] + ": .word 0\n";
			// 	}
			// 	else
			// 	{
			// 		string v = tokens[1];
			// 		def += v + ": .word 0\n";
			// 	}
			// }
			else if(tokens[0] == "if")
			{   
				string var1 = tokens[2];
				string c_op = tokens[3];
				string var2 = tokens[4];
				string goto_label = tokens[7];  
				string reg1 = "$8";
				string reg2 = "$9";
				if(c_op.substr(c_op.size()-1, c_op.size()) == "b")
				{
					var1 = getStackAddr(tokens[2]);
					mc += "lw "+reg1+", "+var1+"\n";
					if( c_op == "==b" )
					{
						if(var2 == "#true")
						{
							mc += "bnez " +  reg1 + ", " + goto_label + "\n";
						}
						else if(var2 == "#false"){
							mc += "beqz " + reg1 + ", " + goto_label + "\n";
						}
					}
					else if( c_op == "!=b" )
					{
						if(var2 == "#false")
						{
							mc += "bnez " +  reg1 + ", " + goto_label + "\n";
						}
						else if(var2 == "#true"){
							mc += "beqz " + reg1 + ", " + goto_label + "\n";
						}
					}
				}
				if(c_op.substr(c_op.size()-1, c_op.size()) == "i")
				{
					if(var1[0] == '#')
					{
						mc += "li "+reg1+", "+var1.substr(1, var1.length())+"\n";
					}
					else if(var1[0] == '*' )
					{
						var1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+var1+"\n";
						mc += "lw "+reg1+", "+"("+reg1+")\n";
					}
					else
					{
						var1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+var1+"\n";
					}

					if(var2[0] == '#')
					{
						mc += "li "+reg2+", "+var2.substr(1, var2.length())+"\n";
					}
					else if(var2[0] == '*' )
					{
						var2 = getStackAddr(tokens[4]);
						mc += "lw "+reg2+", "+var2/*.substr(1, var2.length())*/+"\n";
						mc += "lw "+reg2+", "+"("+reg2+")\n";
					}
					else
					{
						var2 = getStackAddr(tokens[4]);
						mc += "lw "+reg2+", "+var2+"\n";
					}


					if(c_op == "==i")
					{
						mc += "beq "+reg1+", "+reg2+", "+goto_label+"\n";
					}
					else if(c_op == "<=i")
					{
						mc += "ble "+reg1+", "+reg2+", "+goto_label+"\n";
					}
					else if(c_op == ">=i")
					{
						mc += "bge "+reg1+", "+reg2+", "+goto_label+"\n";
					}
					else if(c_op == "<i")
					{
						mc += "blt "+reg1+", "+reg2+", "+goto_label+"\n";
					}
					else if(c_op == ">i")
					{
						mc += "bgt "+reg1+", "+reg2+", "+goto_label+"\n";
					}
					else if(c_op == "!=i")
					{
						mc += "bne "+reg1+", "+reg2+", "+goto_label+"\n";
					}
				}	
				/*
				   else if(c_op.substr(c_op.size()-1, c_op.size()) == "f")
				   {
				   string f1="$f0", f2="$f1", f3="$f2";

				   if(var1[0] == '#')
				   {
				   mc += "li.s "+f1+", "+var1.substr(1, var1.length())+"\n";
				   }
				   else if (var1[0] == '*') 
				   {
				   mc += "lwc1 "+f1+", "+var1.substr(1, var1.length())+"\n";
				   mc += "lwc1 "+f1+", "+"("+f1+")\n";
				   }
				   else
				   {
				   var1 = getStackAddr(tokens[0]);
				   mc += "lwc1 "+f1+", "+var1+"\n";
				   }

				   if(var2[0] == '#')
				   {
				   mc += "li.s "+f2+", "+var2.substr(1, var2.length())+"\n";
				   }
				   else if (var2[0] == '*') 
				   {
				   mc += "lwc1 "+f2+", "+var2.substr(1, var2.length())+"\n";
				   mc += "lwc1 "+f2+", "+"("+f2+")\n";
				   }
				   else
				   {
				   var2 = getStackAddr(tokens[4]);
				   mc += "lwc1 "+f2+", "+var2+"\n";
				   }


				   if(c_op == "==f")
				   {
				   mc += "c.eq.s "+f1+", "+f2+"\n";
				   }
				   else if(c_op == "<=f")
				   {
				   mc += "c.le.s "+f1+", "+f2+"\n";
				   }
				   else if(c_op == ">=f")
				   {
				   mc += "c.le.s "+f2+", "+f1+"\n";
				   }
				   else if(c_op == "<f")
				   {
				   mc += "c.lt.s "+f1+", "+f2+"\n";
				   }
				   else if(c_op == ">f")
				   {
				   mc += "c.lt.s "+f2+", "+f1+"\n";
				   }
				   else if(c_op == "!=f")
				   {
				   mc += "c.ne.s "+f1+", "+f2+"\n";
				   }
				   mc += "bc1t "+goto_label+"\n";
				   } 
				 */
			}
			else if(tokens[0] == "print")
			{
				string type = tokens[1];
				if( type == "newline" )
				{
					mc += "li $4, 10\n";
					mc += "li $2, 11\n";
					mc += "syscall\n";
					continue;
				}
				string var1 = getStackAddr(tokens[2]);

				if(type == "int")
				{
					if( tokens[2][0] == '*' )
					{
						//var1 = getStackAddr(tokens[2]);
						mc += "lw $8, " + var1/*.substr(1, var1.size())*/ + "\n";
						mc += "lw $8, 0($8)\n";
						mc += "li $2, 1\n"; 
						mc += "move $4, $8\n";
						mc += "syscall\n";
					}
					else
					{
						//var1 = getStackAddr(tokens[2]);
						mc += "li $2, 1\n"; 
						mc += "lw $4, " + var1 +"\n";
						mc += "syscall\n";
					}
				}
				else if(type == "char")
				{
					if( tokens[2][0] == '*' )
					{
						//var1 = getStackAddr(tokens[2]);
						mc += "lw $8, " + var1/*.substr(1, var1.size())*/ + "\n";
						mc += "lb $8, ($8)\n";
						mc += "li $2, 11\n"; 
						mc += "move $4, $8\n";
						mc += "syscall\n";
					}
					else
					{
						//var1 = getStackAddr(tokens[2]);
						mc += "li $2, 11\n"; 
						mc += "lb $4, " + var1 +"\n";
						mc += "syscall\n";
					}
				}
				else if(type == "string")
				{
					if( tokens[2][0] == '*' )
					{
						mc += "li $2, 4\n"; 
						mc += "lw $4, " + var1 +"\n";
						mc += "lw $4, ($4)\n";
						mc += "syscall\n";
					}
					else
					{
						mc += "li $2, 4\n"; 
						mc += "lw $4, " + var1 +"\n";
						mc += "syscall\n";
					}
				}
				else if(type == "float")
				{
					mc += "li $2, 2\n";
					mc += "lwc1 $f12, "+var1+"\n";
					mc += "syscall\n";
				}
				else if(type == "bool")
				{
					mc += "li $2, 1\n"; 
					mc += "lw $4, " + var1 +"\n";
					mc += "syscall\n";
				}                
			}
			else if(tokens[0] == "scan")
			{
				string type = tokens[1];
				string var1 = tokens[2];

				if(type == "int")
				{
					mc += "li $2, 5\n"; 
					mc += "syscall\n";

					if(var1[0] != '*')
					{
						var1 = getStackAddr(tokens[2]);
						mc += "sw $2, " + var1 + "\n";
					}
					else
					{
						var1 = getStackAddr(tokens[2]);
						mc += "lw $4, " + var1/*.substr(1, var1.length())*/ + "\n";
						mc += "sw $2, ($4)\n";
					}
				}
				else if(type == "char")
				{
					mc += "li $2, 12\n"; 
					mc += "syscall\n";

					if(var1[0] != '*')
					{
						var1 = getStackAddr(tokens[2]);
						mc += "sw $2, " + var1 + "\n";
					}
					else
					{
						var1 = getStackAddr(tokens[2]);
						mc += "sw $2, (" + var1/*.substr(1, var1.length())*/ + ")\n";
					}
				}
				else if(type == "string")
				{
					var1 = getStackAddr(tokens[2]);
					mc += "li $4, 200\n";
					mc += "li $2, 9\n";
					mc += "syscall\n";
					mc += "move $4, $2\n";
					mc += "li $2, 8\n";
					mc += "li $5, 200\n";
					mc += "syscall\n";
					mc += "sw $4, "+var1+"\n";

					mc += "lw $16, " + var1 + "\n"; 
					string loop1 = "looplabel" + to_string(looplabel);
					looplabel++;
					string exit1 = "looplabel" + to_string(looplabel);
					looplabel++;

					mc += "addi $t0, $zero, 0\n";
					mc += loop1  + ":\n";
					mc += "lb $t1, 0($16)\n";
					mc += "li $t4, 10\n";
					mc += "beq $t1, $t4, " + exit1 + "\n";

					mc += "addi $16, $16, 1\n";
					mc += "addi $t0, $t0, 1\n";
					mc +=  "j " + loop1 + "\n";
					mc += exit1 + ":\n";
					mc += "sb $zero, 0($16)\n";
				}
				else if(type == "float")
				{
					mc += "li $2, 6\n";
					mc += "syscall\n";
					mc += "swc1 $f0, "+var1+"\n";
				}  
			}
			else if( tokens[0] == "la" )
			{
				string reg = "$8";
				if( tokens[2][0] == '*' )
				{
					mc += "lw $8, " + getStackAddr(tokens[2]) + "\n";
				}
				else
				{
					mc += "la " + reg + ", " + getStackAddr(tokens[2]) + "\n";
				}
				mc += "sw " + reg + ", " + getStackAddr(tokens[1]) + "\n";
			}
			else if( tokens[0] == "exit" )
			{
				mc += "li $v0, 10\nsyscall\n";
			}
			else if( tokens.size() >= 3 )
			{
				string v1, v2, res, resreg, eq, op;

				string reg1 = "$8";
				string reg2 = "$9";
				string reg3 = "$10";
				string reg4 = "$11";

				string f1 = "$f0";
				string f2 = "$f1";
				string f3 = "$f2";
				string f4 = "$f3";

				res = tokens[0]; 
				eq = tokens[1];


				if(eq == "=i")
				{
					if( tokens[2] == "len" )
					{
						string str = getStackAddr(tokens[3]);
						string lenVar = getStackAddr(tokens[0]);
						mc += "lw $16, " + str + "\n";
						string loop1 = "looplabel" + to_string(looplabel);
						looplabel++;
						string exit1 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "addi $t0, $zero, 0\n";
						mc += loop1  + ":\n";
						mc += "lb $t1, 0($16)\n";
						mc += "beqz $t1, " + exit1 + "\n";

						mc += "addi $16, $16, 1\n";
						mc += "addi $t0, $t0, 1\n";
						mc +=  "j " + loop1 + "\n";
						mc += exit1 + ":\n";
						mc += "sw $t0, " + lenVar + "\n";
						continue;
					}
					else if( tokens[2] == "malloc" )
					{
						string addrSize = getStackAddr(tokens[3]);
						string addrVar = getStackAddr(tokens[0]);

						mc += "lw $8, " + addrSize + "\n";
						mc += "li $2, 9\n";
						mc += "move $4, $8\n";
						mc += "syscall\n";
						mc += "sw $2, " + addrVar + "\n";
						continue;
					}

					string t_e = tokens[2];
					if( tokens.size() == 4 )	//t1 = minus t2
					{
						v1 = getStackAddr(tokens[3]);

						if( tokens[3][0] == '*')
						{
							mc += "lw "+reg1+", "+v1 +"\n";
							mc += "lw "+reg1+", "+"("+reg1+")\n";
						}
						else
						{
							mc += "lw "+reg1+", "+v1+"\n";
						}

						mc += "sub "+reg1+ ", $zero, "+reg1+"\n";

						if( res[0] == '*')
						{
							res = getStackAddr(tokens[0]);
							mc += "lw "+reg4+", "+res +"\n";
							mc += "sw "+reg1+", "+"("+reg4+")\n";
						}
						else
						{
							res = getStackAddr(tokens[0]);
							mc += "sw " + reg1 + ", " + res + "\n";
						}
						continue;
					}

					if( t_e[0] == '#')
					{

						mc += "li " + reg1 + ", " + t_e.substr( 1, t_e.size() )+"\n";
					}
					else if(t_e[0] == '*')
					{
						v1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+v1/*.substr(1, v1.size())*/+"\n";
						mc += "lw "+reg1+", "+"("+reg1+")\n";
					}
					else
					{
						v1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+v1+"\n";
					}


					if( tokens.size() == 5 )
					{
						op = tokens[3];
						v2 = tokens[4];
						int t2 = 0;

						if( v2[0] == '#')
						{
							mc += "li " + reg2 + ", " + v2.substr( 1, v2.size() )+"\n";
							t2 = 1;
						}
						else if(v2[0] == '*')
						{
							v2 = getStackAddr(tokens[4]);
							mc += "lw "+reg2+", "+v2+"\n";
							mc += "lw "+reg2+", "+"("+reg2+")\n";
						}
						else
						{
							v2 = getStackAddr(tokens[4]);
							mc += "lw "+reg2+", "+v2+"\n";
						}


						if(op == "+i")
						{
							t2 == 0 ? mc += "add "+ reg3 + ", " + reg1 + ", " + reg2 + "\n" : mc += "addi "+ reg3 + ", " + reg1 + ", " + v2.substr(1, v2.length()) + "\n";
						}
						else if(op == "-i")
						{
							mc += "sub "+ reg3 + ", " + reg1 + ", " + reg2 + "\n";
						}
						else if(op == "*i")
						{
							mc += "mul "+ reg3 + ", " + reg1 + ", " + reg2 + "\n";
						}
						else if(op == "/i")
						{
							mc += "div "+ reg1 + ", " + reg2 + "\n";
							mc += "mflo "+ reg3 + "\n";
						}
						else if( op == "%i" )
						{
							mc += "div "+ reg1 + ", " + reg2 + "\n";
							mc += "mfhi "+ reg3 + "\n";
						}
						resreg = reg3;
					}

					if( tokens.size() == 3 or tokens.size() == 4 )
					{
						resreg = reg1;
					}

					if( res[0] == '*')
					{
						res = getStackAddr(tokens[0]);
						mc += "lw "+reg4+", "+res+"\n";
						mc += "sw "+resreg+", "+"("+reg4+")\n";
					}
					else
					{
						res = getStackAddr(tokens[0]);
						mc += "sw " + resreg + ", " + res + "\n";
					}
				}
				else if( eq == "=v" )
				{
					int a = getStackAddrNo(tokens[0]);
					int b = getStackAddrNo(tokens[2]);
					int noOfLoads = getVariableSize(currentFunc, tokens[0])/4;

					for( int i = 0 ; i < noOfLoads ; i++ )
					{
						mc += "lw $8 " + to_string(b+i*4) + "($sp)\n";
						mc += "sw $8 " + to_string(a+i*4) + "($sp)\n";
					}
				}
				else if( eq == "=f")
				{
					v1 = getStackAddr(tokens[2]);
					string t_r = tokens[2];
					if( tokens.size() == 4 )	//t1 = minus t2
					{
						v1 = getStackAddr(tokens[3]);
						t_r = tokens[3];
					}

					if( t_r[0] == '#')
					{
						mc += "li.s " + f1 + ", " + t_r.substr( 1, t_r.size() )+"\n";
					}
					else if(v1[0] == '*')
					{
						mc += "lwc1 "+f1+", "+v1.substr(1, v1.size())+"\n";
						mc += "lwc1 "+f1+", "+"("+f1+")\n";
					}
					else
					{
						mc += "lwc1 "+f1+", "+v1+"\n";
					}

					if( tokens.size() == 4 )
					{
						mc += "sub.s "+f1+ ", $zero, "+f1+"\n";
					}


					if( tokens.size() == 5 )
					{
						op = tokens[3];
						v2 = tokens[4];
						int t2 = 0;

						if( v2[0] == '#')
						{
							mc += "li.s " + f2 + ", " + v2.substr( 1, v2.size() )+"\n";
						}
						else if(v2[0] == '*')
						{
							mc += "lwc1 "+f2+", "+v2.substr(1, v2.size())+"\n";
							mc += "lwc1 "+f2+", "+"("+f2+")\n";
						}
						else
						{
							mc += "lwc1 "+f2+", "+v2+"\n";
						}

						if(op == "+f")
						{
							mc += "add.s "+ f3 + ", " + f1 + ", " + f2 + "\n";
						}
						else if(op == "-f")
						{
							mc += "sub.s "+ f3 + ", " + f1 + ", " + f2 + "\n";
						}
						else if(op == "*f")
						{
							mc += "mul.s "+ f3 + ", " + f1 + ", " + f2 + "\n";
						}
						else if(op == "/f")
						{
							mc += "div.s "+ f3 + ", " + f1 + ", " + f2 + "\n";
						}
						resreg = f3;
					}

					if( tokens.size() == 3 or tokens.size() == 4 )
					{
						resreg = f1;
					}

					if( res[0] == '*')
					{
						mc += "lwc1 " + f4 + ", " + res.substr(1, res.length()) + "\n";
						mc += "swc1 " + resreg + ", (" + f4 + ")\n";  
					}
					else
					{
						mc += "swc1 " + resreg + ", " + res + "\n";
					}
				}
				else if( eq == "=b" )
				{
					v1 = tokens[2];
					if( v1[0] == '#')
					{
						if( v1.substr(1, v1.size()) == "true" )
						{
							mc += "li " + reg1 + ", 1\n";
						}
						else if( v1.substr(1, v1.size()) == "false" )
						{
							mc += "li " + reg1 + ", 0\n";
						}
					}
					else
					{	
						v1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+v1+"\n";
					}

					if( res[0] == '*')
					{
						res = getStackAddr(tokens[0]);
						mc += "lw "+reg4+", "+res/*.substr(1, res.size())*/+"\n";
						mc += "sw "+reg1+", "+"("+reg4+")\n";
					}
					else
					{
						res = getStackAddr(tokens[0]);
						mc += "sw " + reg1 + ", " + res + "\n";
					}
				}
				else if( eq == "=s")
				{
					if (tokens[2] == "strcat")
					{
						mc += "lw $16, " + tokens[3] + "\n"; 

						string loop1 = "looplabel" + to_string(looplabel);
						looplabel++;
						string exit1 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "addi $t0, $zero, 0\n";
						mc += loop1  + ":\n";
						mc += "lb $t1, 0($16)\n";
						mc += "beqz $t1, " + exit1 + "\n";

						mc += "addi $16, $16, 1\n";
						mc += "addi $t0, $t0, 1\n";
						mc +=  "j " + loop1 + "\n";
						mc += exit1 + ":\n";

						string loop2 = "looplabel" + to_string(looplabel);
						looplabel++;
						string exit2 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "lw $16, " + tokens[4] + "\n"; 

						mc += loop2  + ":\n";
						mc += "lb $t1, 0($16)\n";
						mc += "beqz $t1, " + exit2 + "\n";

						mc += "addi $16, $16, 1\n";
						mc += "addi $t0, $t0, 1\n";
						mc +=  "j " + loop2 + "\n";
						mc += exit2 + ":\n";

						mc += "addi $t0, $t0, 1\n";

						mc += "li $2, 9\n";
						mc += "move $4, $t0\n";
						mc += "syscall\n";

						mc += "sw $2, " + tokens[0] + "\n";


						string loop3 = "looplabel" + to_string(looplabel);
						looplabel++;
						string out3 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "add $t0, $zero, $zero\n";
						mc += "lw $16, " + tokens[3] + "\n"; 
						mc += loop3 + ":\n";
						mc += "add $t1, $16, $t0\n";
						mc += "lb $t2, 0($t1)\n";
						mc += "beq $t2, $zero, " + out3 + "\n";
						mc += "add $t3, $2, $t0\n";
						mc += "sb $t2, 0($t3)\n";
						mc += "addi $t0, $t0, 1\n";
						mc += "j " + loop3 + "\n";
						mc += out3 + ":\n";

						string loop4 = "looplabel" + to_string(looplabel);
						looplabel++;
						string out4 = "looplabel" + to_string(looplabel);
						looplabel++;
						mc += "add $2, $2, $t0\n";
						mc += "add $t0, $zero, $zero\n";
						mc += "lw $16, " + tokens[4] + "\n"; 
						mc += loop4 + ":\n";
						mc += "lb $t2, 0($16)\n";
						mc += "sb $t2, 0($2)\n";
						mc += "addi $16, $16, 1\n";
						mc += "addi $2, $2, 1\n";
						mc += "beq $t2, $zero, " + out4 + "\n";
						mc += "j " + loop4 + "\n";
						mc += out4 + ":\n";

					}
					else if(tokens[2] == "strcatc")
					{  
						string arg1 = getStackAddr(tokens[3]);
						string arg2 = getStackAddr(tokens[4]);
						string res = getStackAddr(tokens[0]);
						mc += "lw $16, " + arg1 + "\n"; 

						string loop1 = "looplabel" + to_string(looplabel);
						looplabel++;
						string exit1 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "addi $t0, $zero, 0\n";
						mc += loop1  + ":\n";
						mc += "lb $t1, 0($16)\n";
						mc += "beqz $t1, " + exit1 + "\n";

						mc += "addi $16, $16, 1\n";
						mc += "addi $t0, $t0, 1\n";
						mc +=  "j " + loop1 + "\n";
						mc += exit1 + ":\n";

						mc += "addi $t0, $t0, 2\n";

						mc += "li $2, 9\n";
						mc += "move $4, $t0\n";
						mc += "syscall\n";

						mc += "sw $2, " + res + "\n";


						string loop3 = "looplabel" + to_string(looplabel);
						looplabel++;
						string out3 = "looplabel" + to_string(looplabel);
						looplabel++;

						mc += "add $t0, $zero, $zero\n";
						mc += "lw $16, " + arg1 + "\n"; 
						mc += loop3 + ":\n";
						mc += "add $t1, $16, $t0\n";
						mc += "lb $t2, 0($t1)\n";
						mc += "beq $t2, $zero, " + out3 + "\n";
						mc += "add $t3, $2, $t0\n";
						mc += "sb $t2, 0($t3)\n";
						mc += "addi $t0, $t0, 1\n";
						mc += "j " + loop3 + "\n";
						mc += out3 + ":\n";

						if( tokens[4][0] == '*' )
						{
							//mc += "lw $t2, " + tokens[4].substr(1, tokens[4].length()) + "\n";
							mc += "lw $t2, " + arg2 + "\n";
							mc += "lb $t2, 0($t2)\n";
						}
						else
						{
							mc += "lb $t2, " + arg2 + "\n";
						}
						mc += "add $2, $2, $t0\n";
						mc += "sb $t2, 0($2)\n";
						mc += "addi $2, $2, 1\n";
						mc += "sb $zero, 0($2)\n";
					}
					else if( tokens[2][0] == '#' )
					{
						v1 = tokens[2];
						string temp = v1.substr(1, v1.length());
						for( int i = 3 ; i < tokens.size() ; i++ )
						{
							temp += " " + tokens[i];
						}
						def += res + ": .asciiz " +temp + "\n";
					}
					else
					{
						v1 = getStackAddr(tokens[2]);

						if( tokens[2][0] == '*')
						{
							mc += "lw $8, "+v1 +"\n";
							mc += "lw $8, ($8)\n";
						}
						else
						{
							mc += "lw $8, "+v1+"\n";
						}

						res = getStackAddr(tokens[0]);
						if( res[0] == '*')
						{
							mc += "lw $9, "+res +"\n";
							mc += "sw $8, ($9)\n";
						}
						else
						{
							mc += "sw $8, " + res + "\n";
						}
					}

				}
				else if( eq == "=c")
				{
					v1 = tokens[2];

					if( v1[0] == '#')
					{
						if( v1.size() == 4 )
						{
							mc += "li " + reg1 + ", " + to_string((int)v1[2])+"\n";
						}
						else if( v1.size() == 5 )
						{
							if( v1[3] == 'n' )
							{
								mc += "li " + reg1 + ", 10\n";
							}
						}
					}
					else if(v1[0] == '*')
					{
						v1 = getStackAddr(tokens[2]);
						mc += "lw "+reg1+", "+v1/*.substr(1, v1.size())*/+"\n";
						mc += "lb "+reg1+", "+"("+reg1+")\n";
					}
					else
					{
						v1 = getStackAddr(tokens[2]);
						mc += "lb "+reg1+", "+v1+"\n";
					}

					if( res[0] == '*')
					{
						res = getStackAddr(tokens[0]);
						mc += "lw "+reg4+", "+res/*.substr(1, res.size())*/+"\n";
						mc += "sb "+reg1+", "+"("+reg4+")\n";
					}
					else
					{
						res = getStackAddr(tokens[0]);
						mc += "sb " + reg1 + ", " + res + "\n";
					}
				}
			}
		}

	}
	mc = def + mc;
	//cout<<mc;
	file.close();

	ofstream myfile("machine.asm");
	myfile << mc;
	//cout << "Successfully generated machine code" << endl;
	myfile.close();

	return 0;
}
