# A package config for CppMicroServices.
# This file loads component specific configuration files and
# sets the following variables which can be used in other
# CMake projects to build and link against CppMicroServices:
#
#   US_LIBRARIES
#   US_RUNTIME_LIBRARY_DIRS
#
# The following variables are aliases for the ones above:
#
#   CppMicroServices_LIBRARIES
#   CppMicroServices_RUNTIME_LIBRARY_DIRS
#
# To specify a compatible version for a specific component,
# set the following variable before calling find_package:
#
#   US_<component>_FIND_VERSION
#
# After find_package returns successfully, the following additional
# variables will be set:
#
#   US_FOUND
#   CPPMICROSERVICES_FOUND
#
#   US_RCC_EXECUTABLE_TARGET
#
#   US_VERSION
#   US_VERSION_MAJOR
#   US_VERSION_MINOR
#   US_VERSION_PATCH
#   US_VERSION_TWEAK
#   US_VERSION_COUNT
#
# Additional component specific variables:
#
#   US_<component>_FOUND
#
#   US_<component>_VERSION
#   US_<component>_VERSION_MAJOR
#   US_<component>_VERSION_MINOR
#   US_<component>_VERSION_PATCH
#   US_<component>_VERSION_TWEAK
#   US_<component>_VERSION_COUNT
#


####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was CppMicroServicesConfig.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

####################################################################################

set(US_CMAKE_MINIMUM_REQUIRED_VERSION 3.2)
set(US_ENABLE_THREADING_SUPPORT ON)

cmake_minimum_required(VERSION ${US_CMAKE_MINIMUM_REQUIRED_VERSION})

list(APPEND CMAKE_MODULE_PATH "${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake")

set(US_BUNDLE_INIT_TEMPLATE "${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/BundleInit.cpp")
set(US_RESOURCE_RC_TEMPLATE "${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/cppmicroservices_resources.rc.in")
set(US_CMAKE_RESOURCE_DEPENDENCIES_CPP "${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/CMakeResourceDependencies.cpp")

set(US_RCC_EXECUTABLE_TARGET usResourceCompiler)
if(NOT TARGET ${US_RCC_EXECUTABLE_TARGET})
  include("${CMAKE_CURRENT_LIST_DIR}/CppMicroServicesTargets.cmake")
endif()

# Include helper macros
include(CMakeParseArguments)
include(FindPackageHandleStandardArgs)

include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionGenerateBundleInit.cmake")
include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionAddResources.cmake")
include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionCheckCompilerFlags.cmake")
include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionEmbedResources.cmake")
include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionCheckResourceLinking.cmake")
include("${PACKAGE_PREFIX_DIR}/share/cppmicroservices4/cmake/usFunctionGetResourceSource.cmake")

usFunctionCheckResourceLinking()

# Required packages

if(US_ENABLE_THREADING_SUPPORT AND NOT CMAKE_THREAD_LIBS_INIT)
  set(THREADS_PREFER_PTHREAD_FLAG 1)
  find_package(Threads REQUIRED)
endif()

# Clear variables
set(US_LIBRARIES )
set(US_RUNTIME_LIBRARY_DIRS )

# Components support
set(US_BUNDLES Framework HttpService WebConsole ShellService) # ConfigAdmin EventAdmin ...

set(US_Framework_BUNDLE_DEPS )
set(US_HttpService_BUNDLE_DEPS Framework)
set(US_WebConsole_BUNDLE_DEPS ${US_HttpService_BUNDLE_DEPS} HttpService)
set(US_ShellService_BUNDLE_DEPS Framework)

if(NOT CppMicroServices_FIND_COMPONENTS)
  set(CppMicroServices_FIND_COMPONENTS Framework)
endif()

set(US_BUNDLES_NEEDED )
foreach(component ${CppMicroServices_FIND_COMPONENTS})
  list(APPEND US_BUNDLES_NEEDED ${US_${component}_BUNDLE_DEPS} ${component})
endforeach()
list(REMOVE_DUPLICATES US_BUNDLES_NEEDED)

set(CppMicroServices_FOUND TRUE)
foreach(component ${US_BUNDLES_NEEDED})
  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/us${component}Config.cmake")
    set(US_${component}_FOUND 0)
    set(CppMicroServices_${component}_FOUND 0)
  else()
    find_package(us${component} ${US_${component}_FIND_VERSION} QUIET REQUIRED
                 HINTS ${CMAKE_CURRENT_LIST_DIR}
                 NO_DEFAULT_PATH
                )
    mark_as_advanced(us${component}_DIR)
    set(US_${component}_FOUND ${us${component}_FOUND})
    set(CppMicroServices_${component}_FOUND ${US_${component}_FOUND})
  endif()

  if(US_${component}_FOUND)
    list(APPEND US_LIBRARIES ${US_${component}_LIBRARIES})
    list(APPEND US_RUNTIME_LIBRARY_DIRS ${US_${component}_RUNTIME_LIBRARY_DIRS})

    set(US_${component}_VERSION ${${component}_VERSION})
    set(US_${component}_VERSION_MAJOR ${${component}_VERSION_MAJOR})
    set(US_${component}_VERSION_MINOR ${${component}_VERSION_MINOR})
    set(US_${component}_VERSION_PATCH ${${component}_VERSION_PATCH})
    set(US_${component}_VERSION_TWEAK ${${component}_VERSION_TWEAK})
    set(US_${component}_VERSION_COUNT ${${component}_VERSION_COUNT})
  else()
    if(CppMicroServices_FIND_REQUIRED_${component})
      set(CppMicroServices_FOUND FALSE)
    endif()
  endif()
endforeach()

if(US_LIBRARIES)
  list(REMOVE_DUPLICATES US_LIBRARIES)
endif()
if(US_RUNTIME_LIBRARY_DIRS)
  list(REMOVE_DUPLICATES US_RUNTIME_LIBRARY_DIRS)
endif()

set(CppMicroServices_LIBRARIES ${US_LIBRARIES})
set(CppMicroServices_RUNTIME_LIBRARY_DIRS ${US_RUNTIME_LIBRARY_DIRS})

set(CppMicroServices_CONFIG ${CMAKE_CURRENT_LIST_FILE})
find_package_handle_standard_args(CppMicroServices
  HANDLE_COMPONENTS
  CONFIG_MODE
)

string(TOUPPER "CppMicroServices" CppMicroServices_UPPER)
set(US_FOUND ${${CppMicroServices_UPPER}_FOUND})
