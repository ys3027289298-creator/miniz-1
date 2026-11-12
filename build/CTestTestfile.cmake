# CMake generated Testfile for 
# Source directory: /home/ys/feedback/uidreczz28Ypc2VLEbr
# Build directory: /home/ys/feedback/uidreczz28Ypc2VLEbr/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(catch_tests "/home/ys/feedback/uidreczz28Ypc2VLEbr/bin/catch_tests")
set_tests_properties(catch_tests PROPERTIES  _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;322;add_test;/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;0;")
add_test(png_roundtrip_python "/home/ys/.local/bin/python" "/home/ys/feedback/uidreczz28Ypc2VLEbr/tests/png_roundtrip_check.py" "/home/ys/feedback/uidreczz28Ypc2VLEbr/bin/png_roundtrip_gen" "/home/ys/feedback/uidreczz28Ypc2VLEbr/build/png_roundtrip")
set_tests_properties(png_roundtrip_python PROPERTIES  SKIP_RETURN_CODE "77" _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;339;add_test;/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;0;")
add_test(install_test "/usr/bin/cmake" "-DSOURCE_DIR=/home/ys/feedback/uidreczz28Ypc2VLEbr" "-DTEST_DIR=/home/ys/feedback/uidreczz28Ypc2VLEbr/build/install_test" "-DGENERATOR=Unix Makefiles" "-DGENERATOR_PLATFORM=" "-DGENERATOR_TOOLSET=" "-DC_COMPILER=/usr/bin/cc" "-DTOOLCHAIN_FILE=" "-DBUILD_SHARED_LIBS=OFF" "-DAMALGAMATE_SOURCES=OFF" "-DBUILD_HEADER_ONLY=OFF" "-DCONFIG=Release" "-P" "/home/ys/feedback/uidreczz28Ypc2VLEbr/tests/test_install.cmake")
set_tests_properties(install_test PROPERTIES  _BACKTRACE_TRIPLES "/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;347;add_test;/home/ys/feedback/uidreczz28Ypc2VLEbr/CMakeLists.txt;0;")
