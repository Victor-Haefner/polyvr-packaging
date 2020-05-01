cmake_minimum_required (VERSION 3.0)

#set( CMAKE_VERBOSE_MAKEFILE on )

project(pyTest)

message( "Configuring for system name / version: " ${CMAKE_SYSTEM_NAME} " / " ${CMAKE_SYSTEM_VERSION} )

#-s WASM=1 -s USE_ZLIB=1 -lz
#-s USE_BOOST_HEADERS=1
#-s ALLOW_MEMORY_GROWTH=1

set(LINKER_FLAGS "${LINKER_FLAGS} -g -s ALLOW_MEMORY_GROWTH=1 -s EXIT_RUNTIME=1 -s DISABLE_EXCEPTION_CATCHING=0 -s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE=[$Browser]")
  
add_definitions( -DWASM=1 )
add_definitions( -DGLUT_glut_LIBRARY=1 )
add_definitions( -DGLUT_Xi_LIBRARY=1 )
add_definitions( -DGLUT_Xmu_LIBRARY=1 )
add_definitions( -DCMAKE_TOOLCHAIN_FILE=../emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake )
add_definitions( -DCMAKE_MODULE_PATH=../emsdk/upstream/emscripten/cmake/Modules )

add_definitions( -D__USE_MISC=1 )


function(FIND_ZLIB)
	if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
		set(ZLIB_INCLUDE_DIR "~/.emscripten_ports/zlib/zlib-version_1")
		set(ZLIB_LIBRARY_DIR "~/.emscripten_cache/wasm-obj/")
		set(ZLIB_LIBRARIES "-lz")
		set(LINKER_FLAGS "${LINKER_FLAGS} ${ZLIB_LIBRARIES}" PARENT_SCOPE)
	endif()
	include_directories(SYSTEM PUBLIC ${ZLIB_INCLUDE_DIR})
	link_directories(${ZLIB_LIBRARY_DIR})
endfunction()

function(FIND_LIBXML)
	if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
		set(LIBXML_INCLUDE_DIR "../include/libxml2")
		set(LIBXML_LIBRARY_DIR "../lib")
		set(LIBXML_LIBRARIES "-lxml2")
		set(LINKER_FLAGS "${LINKER_FLAGS} ${LIBXML_LIBRARIES}" PARENT_SCOPE)
	endif()
	include_directories(SYSTEM PUBLIC ${LIBXML_INCLUDE_DIR})
	link_directories(${LIBXML_LIBRARY_DIR})
endfunction()

function(FIND_BOOST)
	if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
		set(BOOST_INCLUDE_DIR "~/.emscripten_ports/boost_headers")
		set(BOOST_LIBRARY_DIR "../lib")
		#set(BOOST_LIBRARIES "-lboost_system -lboost_thread -lboost_program_options -lboost_serialization -lboost_filesystem -lboost_regex")
		set(BOOST_LIBRARIES "-lboost_system -lboost_program_options -lboost_serialization -lboost_filesystem")
		set(LINKER_FLAGS "${LINKER_FLAGS} ${BOOST_LIBRARIES}" PARENT_SCOPE)
	endif()
	include_directories(SYSTEM PUBLIC ${BOOST_INCLUDE_DIR})
endfunction()

function(FIND_PYTHON)
	if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
		set(PYTHON_INCLUDE_DIR "../include/Python")
		set(PYTHON_LIBRARY_DIR "../lib")
		set(PYTHON_LIBRARIES "-lpython2.7")
		set(LINKER_FLAGS "${LINKER_FLAGS} ${PYTHON_LIBRARIES}" PARENT_SCOPE)
	endif()
	include_directories(SYSTEM PUBLIC ${PYTHON_INCLUDE_DIR})
endfunction()

FIND_ZLIB()
FIND_LIBXML()
FIND_BOOST()
FIND_PYTHON()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

string(STRIP ${LINKER_FLAGS} LINKER_FLAGS)

add_executable(pyTest main.cpp)

target_compile_options(pyTest PRIVATE ${COMPILER_FLAGS})
target_link_libraries(pyTest PRIVATE ${LINKER_FLAGS})







