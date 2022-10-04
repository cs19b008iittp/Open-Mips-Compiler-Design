#include <iostream>
#include <fstream>
#include <cstring>
#include <vector>
#include <bits/stdc++.h>
using namespace std;

vector<vector<string>> instructions;

void getIntructions(string filename){

        fstream file; 
	    file.open(filename,ios::in); 

        if(file.is_open())
        {
            string s;
            vector<string> var;
            while(getline(file, s))
            {
	    	vector<string> tokens;
		instructions.push_back(tokens);
		stringstream ss(s);
		string intermediate;
                while( getline(ss, intermediate, ' ') )
                {
                    cout << instructions[0].size() << endl;
		    instructions[instructions.size()-1].push_back(intermediate); 
                    cout << string(intermediate) << endl;
                }
            }
	    for( int i = 0 ; i < instructions.size() ; i++ )
	    {
		    for( int j = 0 ; j < instructions[i].size() ; j++ )
		    {
			    cout << instructions[i][j] << " ";
		    }
		    cout << endl;
	    }
            file.close();
        }
        else 
	{
            cout << " Unable to open file" ;
        }
}


int main(int argcount, char* arguments[]){
       
        getIntructions(string(arguments[1]));

        // for (int i = 0; i < instructions.size(); i++)
        // {
        //     for (int j = 0; j < instructions[i].size(); j++)
        //     {
        //         cout << instructions[i][j] << " ";
        //     }   
        //     cout << endl;
        // }
        
}
