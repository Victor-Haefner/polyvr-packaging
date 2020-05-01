#define GL_GLEXT_PROTOTYPES
#define EGL_EGLEXT_PROTOTYPES

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <sys/time.h>
#include <unistd.h>
#include <emscripten.h>

#include <fstream>
#include <iostream>
#include <string>
#include <map>
#include <vector>

#include <ft2build.h>
#include FT_FREETYPE_H


using namespace std;




class FTUtils {
    private:
        FT_Library  library;
        FT_Face     face;

    public:
        FTUtils() {
            int e = FT_Init_FreeType( &library );
            if (e) cout << "FT_Init_FreeType failed!" << endl;

            e = FT_New_Face( library, "/usr/share/fonts/truetype/arial.ttf", 0, &face );
            if (e) cout << "FT_New_Face failed!" << endl;
        }
};






string data = "input some text";

extern "C" {
const char* getVertexShader() {
	return data.c_str();
}

EMSCRIPTEN_KEEPALIVE void setVertexShader(const char* s) {
	printf("store data: %s\n", s);
	data = string(s);
}
}

int main(int argc, char *argv[]) {
	//while(true) sleep(0.01);
	printf("hi %s\n", getVertexShader());

	string line;
	ifstream infile("data/dat2");
	cout << "read file 'data' " << infile.is_open() << endl;
	while (getline(infile, line)) cout << line << endl;

	cout << "\nTest memory" << endl;
	map<int, vector<char> > chunks;
	for (int i=0; i<0; i++) {
		cout << " chunk " << i << endl;
		chunks[i] = vector<char>(1024*1024, 0); // 1 mb pro chunk 
	}

	try {
		throw "blub";
	} catch(string& s) {
		cout << "catch string " << s << endl;
	} catch(...) {
		cout << "catch unknown " << endl;
	}

	string b = "blaöüä";
	cout << "unicode test: " << b << ", " << endl;

	return 0;
}



