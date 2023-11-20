# 1. main函数的位置

main函数是在sql/main.cc。

```Cpp
extern int mysqld_main(int argc, char **argv);

int main(int argc, char **argv)
{
  return mysqld_main(argc, argv);

}
```

在设计的时候，并没有直接将代码写在`main`函数里面。这是为了方便一些程序为了集成mysql-server，链接的时候，就可以调用`mysqld_main`函数。

因此，真正的函数是在`sql/mysqld.cc`这个文件中，函数代码定义如下：

```Cpp
int mysqld_main(int argc, char **argv)
{
	my_init(); // 初始化文件系统，全局变量等
	load_defaults(MYSQL_CONFIG_NAME, load_default_groups, &argc, &argv);
	// ....
}
```

注意：这里的`load_default_groups`就是`ini`文件里面由`[]`括起来的部分。

```ini
[mysql_cluster]

[mysqld]

[server]
```

这一部分的内容是在`sql/mysqld.cc`中由源码定义的

```Cpp
const char *load_default_groups[]= {
#ifdef WITH_NDBCLUSTER_STORAGE_ENGINE
"mysql_cluster",
#endif
"mysqld","server", MYSQL_BASE_VERSION, 0, 0};
```
# 2. load defaults

```Cpp
int load_defaults(const char *conf_file, const char **groups,
                  int *argc, char ***argv)
{
  return my_load_defaults(conf_file, groups, argc, argv, &default_directories);
}
```

首先看一下`my_load_defaults`函数。

```Cpp
int my_load_defaults(const char *conf_file, const char **groups,

                  int *argc, char ***argv, const char ***default_directories)

{
	init_alloc_root(key_memory_defaults, &alloc,512,0);
	dirs = init_default_directories(&alloc);

	if (*argc >= 2 && !strcmp(argv[0][1], "--no-defaults"))
	    found_no_defaults= TRUE;


}
```
