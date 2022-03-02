#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "CppMicroServices" for configuration "RelWithDebInfo"
set_property(TARGET CppMicroServices APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CppMicroServices PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libCppMicroServices.so.4.0.0"
  IMPORTED_SONAME_RELWITHDEBINFO "libCppMicroServices.so.4.0.0"
  )

list(APPEND _IMPORT_CHECK_TARGETS CppMicroServices )
list(APPEND _IMPORT_CHECK_FILES_FOR_CppMicroServices "${_IMPORT_PREFIX}/lib/libCppMicroServices.so.4.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
