cmake_minimum_required(VERSION 3.20)
project(webview-boost-app CXX)
set(CMAKE_CXX_STANDARD 20)

include(FetchContent)

# Lightweight HTTP server.
FetchContent_Declare(httplib
    GIT_REPOSITORY https://github.com/yhirose/cpp-httplib
    GIT_TAG        master
)
FetchContent_MakeAvailable(httplib)

# Native desktop webview window.
FetchContent_Declare(webview
    GIT_REPOSITORY https://github.com/webview/webview
    GIT_TAG        master
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(webview)

# Boost — fetched as the official CMake-aware source tarball.
# Only the listed component libraries are configured/built; everything else is skipped.
set(BOOST_INCLUDE_LIBRARIES asio system)
set(BOOST_ENABLE_CMAKE ON)
FetchContent_Declare(Boost
    URL https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.tar.gz
)
FetchContent_MakeAvailable(Boost)

# Embed static frontend files into the binary.
FetchContent_Declare(cpp-embedlib
    GIT_REPOSITORY https://github.com/yhirose/cpp-embedlib
    GIT_TAG        main
)
FetchContent_MakeAvailable(cpp-embedlib)

cpp_embedlib_add(WebAssets
    FOLDER    ${CMAKE_CURRENT_SOURCE_DIR}/public
    NAMESPACE Web
)

add_executable(webview-app src/main.cpp)

target_link_libraries(webview-app PRIVATE
    httplib::httplib
    webview::core
    WebAssets
    cpp-embedlib-httplib
    Boost::asio
    Boost::system
)

if(APPLE)
    target_link_libraries(webview-app PRIVATE
        "-framework CoreFoundation"
        "-framework Security"
    )
endif()

if(WIN32)
    # Boost.Asio on Windows requires Winsock and the correct API-level define.
    # _WIN32_WINNT=0x0A00 targets Windows 10 and enables modern async I/O APIs.
    # WIN32_LEAN_AND_MEAN keeps windows.h slim so it doesn't clash with Boost/STL.
    # NOMINMAX prevents the windows.h min/max macros from conflicting with std::min/max.
    target_compile_definitions(webview-app PRIVATE
        _WIN32_WINNT=0x0A00
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
    target_link_libraries(webview-app PRIVATE
        ws2_32
        mswsock
    )
endif()

if(WIN32)
    # WebView2Loader.dll is shipped inside the MSWebView2 NuGet package that the
    # webview cmake fetches via FetchContent. Its path is architecture-specific.
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|arm64|aarch64")
        set(_wv2_arch "arm64")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(_wv2_arch "x64")
    else()
        set(_wv2_arch "x86")
    endif()
    set(_webview2_loader_dll
        "${CMAKE_BINARY_DIR}/_deps/microsoft_web_webview2-src/build/native/${_wv2_arch}/WebView2Loader.dll"
    )

    add_custom_command(TARGET webview-app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_webview2_loader_dll}"
            $<TARGET_FILE_DIR:webview-app>/WebView2Loader.dll
        COMMAND ${CMAKE_COMMAND} -E make_directory
            $<TARGET_FILE_DIR:webview-app>/icons
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_icon_small.ico
            $<TARGET_FILE_DIR:webview-app>/icons/app_icon_small.ico
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_icon.ico
            $<TARGET_FILE_DIR:webview-app>/icons/app_icon.ico
        COMMENT "Copying runtime files to executable directory"
    )
endif()
