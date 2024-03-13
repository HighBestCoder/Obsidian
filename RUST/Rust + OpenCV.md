# 第一步：根据

REF: [Get started with vcpkg](https://vcpkg.io/en/getting-started) 安装vcpkg

**Step 1: Clone the vcpkg repo**

```

git clone https://github.com/Microsoft/vcpkg.git
```

我的安装目录位于D:\vcpkg
Make sure you are in the directory you want the tool installed to before doing this.

**Step 2: Run the bootstrap script to build vcpkg**

```

.\vcpkg\bootstrap-vcpkg.bat
```

这里操作好了之后，需要把vcpkg.exe的所在路径添加到system path中。

# 第二步: 安装llvm

```
vcpkg install llvm opencv4[world] --triplet x64-windows-static --recurse
```

输出信息
```
The package llvm provides CMake targets:

    find_package(LLVM CONFIG REQUIRED)

    list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
    include(HandleLLVMOptions)
    add_definitions(${LLVM_DEFINITIONS})

    target_include_directories(main PRIVATE ${LLVM_INCLUDE_DIRS})

    # Find the libraries that correspond to the LLVM components that we wish to use
    llvm_map_components_to_libnames(llvm_libs Support Core IRReader ...)

    # Link against LLVM libraries
    target_link_libraries(main PRIVATE ${llvm_libs})

If you do not install the meta-port *opencv*, the package opencv4 is compatible with CMake
if you set the OpenCV_DIR *before* the find_package call

    set(OpenCV_DIR "${VCPKG_INSTALLED_DIR}/x64-windows-static/share/opencv4")
    find_package(OpenCV REQUIRED)
```

然后再安装

```
vcpkg install llvm[tools,utils]  --triplet x64-windows --recurse
```

这里安装完成之后，需要把`D:\vcpkg\installed\x64-windows\tools\llvm` 添加以system path中。

# 第三步：rust + opencv 项目

要设置的环境变量，这些都加到system环境变量里面

```
OpenCV_DIR = D:\vcpkg\packages\opencv4_x86-windows\share\opencv4
OPENCV_INCLUDE_PATHS = D:\vcpkg\installed\x64-windows\include
OPENCV_LINK_LIBS = opencv_world4
OPENCV_LINK_PATHS = D:\vcpkg\installed\x64-windows\lib
```

Path中要添加`D:\vcpkg\installed\x64-windows\tools\llvm`

```
Stored binaries in 1 destinations in 19 min.
Elapsed time to handle llvm:x64-windows: 4.1 h
llvm:x64-windows package ABI: e825ca87c913b27d1f744e7961a292d07925e68b51836f72bbf71c3f012cc06b
Total install time: 4.1 h
The package llvm provides CMake targets:

    find_package(LLVM CONFIG REQUIRED)

    list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
    include(HandleLLVMOptions)
    add_definitions(${LLVM_DEFINITIONS})

    target_include_directories(main PRIVATE ${LLVM_INCLUDE_DIRS})

    # Find the libraries that correspond to the LLVM components that we wish to use
    llvm_map_components_to_libnames(llvm_libs Support Core IRReader ...)

    # Link against LLVM libraries
    target_link_libraries(main PRIVATE ${llvm_libs})
```
