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
