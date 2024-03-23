我自己常用的onenote 那个页面设置了一个密码fedora12@，但是不是用来登陆onenote的密码，只是这个页面进行了一个加密

# StartSQLAzureConsole.ps1
这个主要是用来启动ASC Console的，可以在桌面上建个快捷方式。

![[Pasted image 20240226084249.png]]

![[Pasted image 20240226084304.png]]填写内容
```
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NoExit -ExecutionPolicy Unrestricted -File "C:\Users\yoj\code\Obsidian\MySQL-OnCall\StartSQLAzureConsole.ps1"
```
这样可以在一开始的时候，就把我想要加载的内容加载好。

# yoj.psm1

我自己实现的一些帮助函数。
