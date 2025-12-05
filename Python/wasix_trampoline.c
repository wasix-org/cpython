#if defined(__wasi__)
#include <Python.h>

#include "pycore_runtime.h"
#include <wasix/reflection.h>
#include <wasix/call_dynamic.h>

#define CACHE_INITIAL_CAP 16
#define CACHE_MAX_LOAD 0.5
#define EMPTY_KEY 0
static int empty_key_value = -1; // Special value, returned for EMPTY_KEY
_Static_assert(EMPTY_KEY == 0,
               "EMPTY_KEY must be 0 so we can use calloc for initialization");

typedef struct {
  int key;            // Index of the function in the indirect function table
  int argument_count; // Number of arguments for the function
} cache_entry_t;

static cache_entry_t *argument_count_cache = NULL;
static size_t cache_capacity = 0;    // Current capacity of the cache
static size_t cache_entries = 0;     // Current number of entries in the cache
static size_t cache_max_entries = 0; // Maximum size before growing

static void cache_init(void) {
  argument_count_cache = calloc(CACHE_INITIAL_CAP, sizeof(cache_entry_t));
  cache_capacity = CACHE_INITIAL_CAP;
  cache_max_entries = cache_capacity * CACHE_MAX_LOAD;
}

static void cache_grow(void) {
  assert(argument_count_cache != NULL);

  size_t new_capacity = cache_capacity * 2;

  cache_entry_t *new_table = calloc(new_capacity, sizeof(cache_entry_t));

  for (size_t i = 0; i < cache_capacity; i++) {
    if (argument_count_cache[i].key != EMPTY_KEY) {
      size_t index = argument_count_cache[i].key % new_capacity;
      while (new_table[index].key != EMPTY_KEY) {
        index = (index + 1) % new_capacity; // Linear probing
      }
      new_table[index] = argument_count_cache[i];
    }
  }

  free(argument_count_cache);
  argument_count_cache = new_table;
  cache_capacity = new_capacity;
  cache_max_entries = cache_capacity * CACHE_MAX_LOAD;
}

// Returns a pointer to the value associated with the key
// Returns NULL if the key is not found
// Returns a pointer to -1 if the key is 0
static int *cache_get(int key) {
  if (argument_count_cache == NULL) {
    return NULL; // Hash table not initialized
  }
  if (key == EMPTY_KEY) {
    return &empty_key_value;
  }

  size_t index = key % cache_capacity;
  while (argument_count_cache[index].key != EMPTY_KEY) {
    if (argument_count_cache[index].key == key) {
      return &argument_count_cache[index]
                  .argument_count; // Return pointer to value
    }
    index = (index + 1) % cache_capacity; // Linear probing
  }
  return NULL; // Key not found
}

static int *cache_insert(int key, int value) {
  if (key == EMPTY_KEY) {
    return &empty_key_value;
  }

  if (argument_count_cache == NULL) {
    cache_init();
  }

  if (cache_entries >= cache_max_entries) {
    cache_grow();
  }

  size_t index = key % cache_capacity;
  while (argument_count_cache[index].key != EMPTY_KEY) {
    if (argument_count_cache[index].key == key) {
      return NULL; // Key already exists, we don't do updates
    }
    index = (index + 1) % cache_capacity; // Linear probing
  }
  argument_count_cache[index].key = key;
  argument_count_cache[index].argument_count = value;
  cache_entries++;
  return &argument_count_cache[index].argument_count; // Return pointer to value
}

typedef PyObject *(*zero_arg)(void);
typedef PyObject *(*one_arg)(PyObject *);
typedef PyObject *(*two_arg)(PyObject *, PyObject *);
typedef PyObject *(*three_arg)(PyObject *, PyObject *, PyObject *);

static bool PyWASIX_Reflection_Available(void) {
  wasix_reflection_result_t result;
  int code = wasix_reflect_signature(
    (wasix_function_pointer_t)1, NULL, 0, NULL, 0, &result);
  if (code == -1 && errno == ENOTSUP) {
    return false;
  }
  return true;
}

void _PyWASIX_Trampoline_Init(_PyRuntimeState *runtime) {
  runtime->wasm_type_reflection_available = PyWASIX_Reflection_Available();
}

int _PyWASIX_CountFuncParams(PyCFunctionWithKeywords func) {
  int *argument_count_ptr = cache_get((int)(size_t)func);
  if (argument_count_ptr != NULL) {
    return *argument_count_ptr; // Return cached value
  }
  // If not found, we assume 3 arguments for compatibility
  wasix_reflection_result_t result;
  int code;

  code = wasix_reflect_signature((wasix_function_pointer_t)func, NULL, 0, NULL,
                                 0, &result);

  // Use the returned argument count, if it is
  int argument_count =
      (code == 0 || errno == EOVERFLOW) ? result.arguments : -1;
  if (result.cacheable) {
    cache_insert((int)(size_t)func, argument_count);
  }
  return argument_count;
}

PyObject *_PyWASIX_TrampolineCall_Cached(PyCFunctionWithKeywords func, PyObject *self,
                                         PyObject *args, PyObject *kw) {
  int argument_count = _PyWASIX_CountFuncParams(func);

  switch (argument_count) {
  case 0:
    PyObject *result0 = ((zero_arg)func)();
    return result0;
  case 1:
    PyObject *result1 = ((one_arg)func)(self);
    return result1;
  case 2:
    PyObject *result2 = ((two_arg)func)(self, args);
    return result2;
  case 3:
    PyObject *result3 = ((three_arg)func)(self, args, kw);
    return result3;
  case -1:
    PyErr_SetString(PyExc_RuntimeError, "Failed to reflect function signature");
    return NULL;
  default:
    PyErr_SetString(PyExc_RuntimeError, "Unsupported number of arguments");
    return NULL;
  }
}

PyObject *_PyWASIX_TrampolineCall_Dynamic(PyCFunctionWithKeywords func, PyObject *self,
                                          PyObject *args, PyObject *kw) {
  wasix_raw_value_with_type_t wasm_args[3];
  wasm_args[0].type = WASIX_VALUE_TYPE_I32;
  memcpy(&wasm_args[0].value, &self, sizeof(PyObject *));
  wasm_args[1].type = WASIX_VALUE_TYPE_I32;
  memcpy(&wasm_args[1].value, &args, sizeof(PyObject *));
  wasm_args[2].type = WASIX_VALUE_TYPE_I32;
  memcpy(&wasm_args[2].value, &kw, sizeof(PyObject *));

  wasix_raw_value_with_type_t wasm_result;
  size_t result_count = 1;

  if (wasix_call_dynamic((wasix_function_pointer_t)func, wasm_args, 3,
                           &wasm_result, &result_count, false) != 0) {
    PyErr_SetString(PyExc_RuntimeError, "Failed to call function dynamically");
    return NULL;
  }

  // Note: in JS environments, where this code is actually used, WASIX has to
  // "guess" the return type based on how big the return value is. On a 32-bit
  // platform all pointers are 32-bit, so it will return WASIX_VALUE_TYPE_I32.
  if (result_count != 1 || wasm_result.type != WASIX_VALUE_TYPE_I32) {
    PyErr_SetString(PyExc_RuntimeError, "Unexpected function return type");
    return NULL;
  }

  PyObject *result;
  memcpy(&result, &wasm_result.value, sizeof(PyObject *));
  return result;
}

#endif
