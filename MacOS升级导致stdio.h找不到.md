# Xcode升级

#xcode 升级之后导致stdio.h找不到。

目上前根本原因还不是特别清楚。

xcode升级后导致

```
In file included from /Users/youji/Documents/code/rm-300a/src/irq.cpp:1:
In file included from /Users/youji/Documents/code/rm-300a/src/include/nce/irq.h:4:
/Users/youji/Documents/code/rm-300a/src/include/nce/util.h:11:10: fatal error: 'assert.h' file not found
#include <assert.h>
         ^~~~~~~~~~
In file included from /Users/youji/Documents/code/rm-300a/src/locator.cpp:1:
/Users/youji/Documents/code/rm-300a/src/include/nce/locator.h:6:10: fatal error: 'atomic' file not found
#include <atomic>
         ^~~~~~~~
In file included from /Users/youji/Documents/code/rm-300a/src/motor.cpp:1:
/Users/youji/Documents/code/rm-300a/src/include/nce/motor.h:4:10: fatal error: 'stdio.h' file not found
#include <stdio.h>
         ^~~~~~~~~
1 error generated.
In file included from /Users/youji/Documents/code/rm-300a/src/camera.cpp:1:
In file included from /Users/youji/Documents/code/rm-300a/src/include/nce/camera.h:4:
/Users/youji/Documents/code/rm-300a/src/include/nce/chan.h:4:10: fatal error: 'vector' file not found
#include <vector>
         ^~~~~~~~
make[2]: *** [src/CMakeFiles/rm_lib.dir/irq.cpp.o] Error 1
make[2]: *** Waiting for unfinished jobs....
1 error generated.
make[2]: *** [src/CMakeFiles/rm_lib.dir/motor.cpp.o] Error 1
1 error generated.
1 error generated.
make[2]: *** [src/CMakeFiles/rm_lib.dir/locator.cpp.o] Error 1
make[2]: *** [src/CMakeFiles/rm_lib.dir/camera.cpp.o] Error 1
make[1]: *** [src/CMakeFiles/rm_lib.dir/all] Error 2
make: *** [all] Error 2
```

解决方案：

[1] 将cmake的build目录重新生成
[2] 修改Cmake里面的目录的版本，使用软链接。

```
     link_directories(
         ${CMAKE_CURRENT_SOURCE_DIR}/lib/opencv/lib
         ${CMAKE_CURRENT_SOURCE_DIR}/lib/opencv/share/OpenCV/3rdparty/lib
-        /Library/Developer/CommandLineTools/SDKs/MacOSX14.2.sdk/usr/lib
-        /Library/Developer/CommandLineTools/SDKs/MacOSX14.2.sdk/System/Library/Frameworks
+        /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
+        /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks
     )
```

# 可以参考

解决这个问题之前，我们要弄清楚开发工具是引用了系统哪个目录的这些头文件的，也就是说stdio.h头文件要在哪里开发工具才能引用到。
  
这个目录就是/usr/local/include/
我们进入/usr/local/include/发现确实没有stdio.h等头文件。原因可能是系统更新等原因丢失了。
解决方法：
  1.安装CommandLineTools，该开发工具SDK就含有stdio.h等基础头文件
  		安装方法：xcode-select --install
  2.查看stdio.h等基础头文件是否存在
  		打开Finder，command+shift+g，输入/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/ 可以定位到头文件目录。
  3.将/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/下头文件软连接到/usr/local/include/下
  		sudo ln -s /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/* /usr/local/include/
