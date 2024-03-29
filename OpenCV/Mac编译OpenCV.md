```
git clone https://github.com/opencv/opencv.git

cd opencv
mkdir build && cd build

cmake ..

# OpenCV 4.9.0
arch -arm64 cmake .. -DBUILD_SHARED_LIBS=OFF -DBUILD_opencv_world=ON -DWITH_QT=OFF -DWITH_OPENGL=OFF -DFORCE_VTK=OFF -DWITH_TBB=OFF -DWITH_GDAL=OFF -DWITH_XINE=OFF -DBUILD_EXAMPLES=OFF -DBUILD_ZLIB=OFF -DBUILD_TESTS=OFF

# OpenCV 3.4.1
arch -arm64 cmake .. -DBUILD_SHARED_LIBS=OFF -DBUILD_opencv_world=ON -DWITH_QT=OFF -DWITH_OPENGL=OFF -DFORCE_VTK=OFF -DWITH_TBB=OFF -DWITH_GDAL=OFF -DWITH_XINE=OFF -DBUILD_EXAMPLES=OFF -DBUILD_ZLIB=OFF -DBUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/tmp/opencv

arch -arm64 make -j 4

```


如果出现如下错误：

```
[ 31%] Building CXX object modules/world/CMakeFiles/opencv_world.dir/__/dnn/misc/tensorflow/attr_value.pb.cc.o
In file included from /Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/function.pb.cc:4:
/Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/function.pb.h:17:2: error: This file was generated by an older version of protoc which is
#error This file was generated by an older version of protoc which is
 ^
/Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/function.pb.h:18:2: error: incompatible with your Protocol Buffer headers. Please
#error incompatible with your Protocol Buffer headers. Please
 ^
/Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/function.pb.h:19:2: error: regenerate this file with a newer version of protoc.
#error regenerate this file with a newer version of protoc.
 ^
In file included from /Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/attr_value.pb.cc:4:
/Users/youji/Documents/code/opencv-4.9.0/modules/dnn/misc/tensorflow/attr_value.pb.h:17:2: error: This file was generated by an older version of protoc which is
#error This file was generated by an older version of protoc which is
 ^

```

这里是系统的protobuf与opencv带的protobuf版本冲突了。需要删除系统带的protobuf
```
brew uninstall protobuf
```

很好，看起来你已经解决了问题。当你卸载了系统中的 Protocol Buffers（Protobuf）后，编译器可能找到了 OpenCV 源码中包含的相应版本的 Protobuf，所以编译能够成功。

请注意，卸载系统中的 Protobuf 可能会影响到其他依赖于 Protobuf 的项目。如果你在其他项目中遇到了问题，你可能需要重新安装 Protobuf，或者安装一个特定版本的 Protobuf。

# OpenCV 3.4.1的处理



在Mac OS上需要将文件
`youji@satdccevepms14 ~ % cat /Users/youji/Documents/code/rm-300a/src/lib/opencv/lib/pkgconfig/opencv.pc`修改为如下内容。



```
# Package Information for pkg-config

prefix=/tmp/opencv
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir_old=${prefix}/include/opencv
includedir_new=${prefix}/include

Name: OpenCV
Description: Open Source Computer Vision Library
Version: 3.4.1
Libs: -L${exec_prefix}/lib -lopencv_world -L${exec_prefix}/share/OpenCV/3rdparty/lib -llibprotobuf -llibjpeg -llibwebp -llibpng -llibtiff -llibjasper -lIlmImf -ltegra_hal -framework Accelerate -framework AVFoundation -framework CoreGraphics -framework CoreMedia -framework CoreVideo -framework QuartzCore -framework Cocoa -L/Library/Developer/CommandLineTools/SDKs/MacOSX14.2.sdk/usr/lib -lz -framework OpenCL -L/Library/Developer/CommandLineTools/SDKs/MacOSX14.2.sdk/System/Library/Frameworks -framework Accelerate -lm -ldl
Cflags: -I${includedir_old} -I${includedir_new}
```

# OpenCV 4.9的处理

