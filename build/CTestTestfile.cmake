# CMake generated Testfile for 
# Source directory: /home/ys/feedback/uidreczz28Z0d8oVSjR
# Build directory: /home/ys/feedback/uidreczz28Z0d8oVSjR/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(catch_tests "/home/ys/feedback/uidreczz28Z0d8oVSjR/bin/catch_tests")
set_tests_properties(catch_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;327;add_test;/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;0;")
add_test(png_roundtrip_python "/home/ys/.local/bin/python" "/home/ys/feedback/uidreczz28Z0d8oVSjR/tests/png_roundtrip_check.py" "/home/ys/feedback/uidreczz28Z0d8oVSjR/bin/png_roundtrip_gen" "/home/ys/feedback/uidreczz28Z0d8oVSjR/build/png_roundtrip")
set_tests_properties(png_roundtrip_python PROPERTIES  SKIP_RETURN_CODE "77" _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;344;add_test;/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;0;")
add_test(install_test "/usr/bin/cmake" "-DSOURCE_DIR=/home/ys/feedback/uidreczz28Z0d8oVSjR" "-DTEST_DIR=/home/ys/feedback/uidreczz28Z0d8oVSjR/build/install_test" "-DGENERATOR=Unix Makefiles" "-DGENERATOR_PLATFORM=" "-DGENERATOR_TOOLSET=" "-DC_COMPILER=/usr/bin/cc" "-DTOOLCHAIN_FILE=" "-DBUILD_SHARED_LIBS=OFF" "-DAMALGAMATE_SOURCES=OFF" "-DBUILD_HEADER_ONLY=OFF" "-DCONFIG=Release" "-P" "/home/ys/feedback/uidreczz28Z0d8oVSjR/tests/test_install.cmake")
set_tests_properties(install_test PROPERTIES  _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;352;add_test;/home/ys/feedback/uidreczz28Z0d8oVSjR/CMakeLists.txt;0;")
