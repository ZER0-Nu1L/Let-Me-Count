cmake_minimum_required(VERSION 3.1)

project(trailingZeroBits)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(trailingZeroBits trailingZeroBits.cpp ./uint128_t/uint128_t.cpp)

target_compile_options(trailingZeroBits PRIVATE -Wall -Wextra -Werror -pedantic)