
#include <iostream>


#undef _XOPEN_SOURCE
#undef _POSIX_C_SOURCE
#include <Python.h>
#include <iostream>
#include <algorithm>
#include <memory>
#include <stdlib.h>

using namespace std;

PyObject* pGlobal = 0;
PyObject* pLocal = 0;
PyObject* pModBase = 0;
PyObject* pModVR = 0;
PyObject* err = 0;

// define popen, not just for here, but also for python API
#ifdef WASM
FILE *popen(const char *command, const char *type) { return 0; }
#endif

void initPyModules() {
    cout << " initPyModules" << endl;  
    Py_NoSiteFlag = 1;
    Py_Initialize();
    cout << "  Py_Initialize done" << endl;
    char* argv[1];
    argv[0] = (char*)"PolyVR";
    PySys_SetArgv(1, argv);
    PyEval_InitThreads();
    cout << "  PyEval_InitThreads done" << endl;
    err = PyErr_NewException((char *)"VR.Error", NULL, NULL);

    pGlobal = PyDict_New();

    //Create a new module object
    pModBase = PyImport_AddModule("PolyVR_base");
    PyModule_AddStringConstant(pModBase, "__file__", "");
    pLocal = PyModule_GetDict(pModBase); //Get the dictionary object from my module so I can pass this to PyRun_String

    PyDict_SetItemString(pLocal, "__builtins__", PyEval_GetBuiltins());
    PyDict_SetItemString(pGlobal, "__builtins__", PyEval_GetBuiltins());
    cout << "  Added module PolyVR_base" << endl;

    PyObject* sys_path = PySys_GetObject((char*)"path");
    PyList_Append(sys_path, PyString_FromString(".") );

    PyRun_SimpleString( // small test
        "print 'start test!'\n"
	"d = {1:2,3:4}\n"
	"print d\n"
	"print d.values()\n"
    );
}

void cleanup() {
    cout << " cleanup" << endl; 
    if (PyErr_Occurred() != NULL) PyErr_Print();
    if (pModVR) {
        int N = Py_REFCNT(pModVR);
        for (int i=0; i<N; i++) Py_DECREF(pModVR); // this destroys the VR module, helps with memory leaks :)
    }
    PyErr_Clear();
    err = 0;
    Py_Finalize();
}

PyObject* newModule(string name, PyMethodDef* methods, string doc) {
    string name2 = "VR."+name;
    PyObject* m = Py_InitModule3(name2.c_str(), methods, doc.c_str());
    PyModule_AddObject(pModVR, name.c_str(), m);
    return m;
}


int main(int argc, char **argv) {
	initPyModules();
	cleanup();
}



