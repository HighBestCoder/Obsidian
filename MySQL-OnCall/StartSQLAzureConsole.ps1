# StartApp.ps1

# 定义模块导入命令
$importCommands = @"
Import-Module 'C:\Users\yoj\code\RP\scripts\ps\Common\MySqlFS.Common.psm1';
Import-Module 'C:\Users\yoj\code\RP\scripts\ps\Devops\MySqlFS.DevOps.psm1';
Import-Module 'C:\Users\yoj\SqlAzureConsole\SqlAzureShell.psd1' -ArgumentList 'SQL Azure Console';
Import-Module 'C:\Users\yoj\code\Obsidian\MySQL-OnCall\yoj.psm1' -Force
"@

# 定义启动命令
$startCommand = @"
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NoExit -ExecutionPolicy Unrestricted -Command "$importCommands";
"@

# 执行启动命令
Invoke-Expression -Command $startCommand
