#if defined(__wasi__)
// Based on emscripten_trampoline.c, but adapted for WASIX
#include <wasix/call_dynamic.h>
#include <Python.h>
#include "pycore_runtime.h"

int _PyEM_detect_type_reflection(void)
{
    return false;
}

void
_Py_EmscriptenTrampoline_Init(_PyRuntimeState *runtime)
{
    runtime->wasm_type_reflection_available = false;
}

/**
 * Backwards compatible trampoline works with all JS runtimes
 */
PyObject* _PyEM_TrampolineCall_JavaScript(void* func, 
                                         PyObject* arg1,
                                         PyObject* arg2,
                                         PyObject* arg3)
{
    PyObject* values[3] = {arg1, arg2, arg3};
    PyObject* results[1] = {0};
    wasix_call_dynamic(
        (__wasi_function_pointer_t)func,
        (char*)values,
        3 * sizeof(PyObject*),
        (char*)results,
        1 * sizeof(PyObject*),
        false
    );
    return results[0];
}

int _PyEM_CountFuncParams(PyCFunctionWithKeywords func)
{
    // Not supported as wasix does not provide reflection calls for now
    abort();
}

typedef PyObject* (*zero_arg)(void);
typedef PyObject* (*one_arg)(PyObject*);
typedef PyObject* (*two_arg)(PyObject*, PyObject*);
typedef PyObject* (*three_arg)(PyObject*, PyObject*, PyObject*);


PyObject*
_PyEM_TrampolineCall_Reflection(PyCFunctionWithKeywords func,
                                PyObject* self,
                                PyObject* args,
                                PyObject* kw)
{
    // Just using the call without reflection for now
    _PyEM_TrampolineCall_JavaScript(func, self, args, kw);
}

#endif
