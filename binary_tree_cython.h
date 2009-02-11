/** Constructs a new object of type zzz_type by calling tp_new
*  directly, with no arguments. 
*/

#define PY_NEW(zzz_type, args) \
(((PyTypeObject*)(zzz_type))->tp_new((PyTypeObject*)(zzz_type), args, NULL)) 
