cmake_minimum_required(VERSION 3.5)

project(Printf LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(${PROJECT_NAME})
add_subdirectory(source)

target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:${DEBUG_FLAGS}>)
target_compile_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:${DEBUG_FLAGS}>)

target_link_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Debug>:${DEBUG_FLAGS}>)
target_link_options(${PROJECT_NAME} PRIVATE $<$<CONFIG:Release>:${DEBUG_FLAGS}>)
