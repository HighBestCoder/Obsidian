# MySQL: Connection Character Sets and Collations

## 一、字符集相关系统变量
1. **服务器端字符集变量**
   - `character_set_server`：指示服务器字符集。
   - `collation_server`：与`character_set_server`对应的校对规则。
   - `character_set_database`：指示默认数据库的字符集。
   - `collation_database`：默认数据库的校对规则。
2. **客户端连接相关字符集变量**
   - 每个客户端都有特定于会话的连接相关字符集和校对系统变量，这些会话系统变量值在连接时初始化，但可以在会话中更改。
   - `character_set_client`：服务器将其作为客户端发送语句的字符集，该变量不能设置为`ucs2`、`utf16`、`utf16le`、`utf32`。
   - `character_set_results`：指示服务器查询结果返回到客户端的字符集，包括结果数据（如列值）、结果元数据（如列名称）和错误消息。
   - `character_set_connection`：服务器将客户端发送的语句从`character_set_client`转换为`character_set_connection`。`collation_connection`对于文字字符串的比较很重要，但对于字符串与列值的比较，列自身的排序规则优先级更高。

## 二、编码转换过程
1. **写入数据时**
   - mysql client使用`character_set_client`编码的字符转换为`character_set_connection`编码字符，然后服务器将其从`character_set_connection`编码格式二进制流解码成字符，再使用`character_set_server`/`character_set_database`对字符进行再次编码，生成二进制流存储。
2. **读取数据时**
   - 服务器使用`character_set_server`/`character_set_database`对读取到的二进制流进行解码成字符，然后使用`character_set_results`对字符进行二次编码，生成二进制流发给mysql client。

## 三、设置字符集
1. **使用`SET NAMES`命令**
   - `SET NAMES 'charset_name'`相当于执行以下三个语句：
     - `SET character_set_client = charset_name;`
     - `SET character_set_results = charset_name;`
     - `SET character_set_connection = charset_name;`
2. **使用`SET CHARACTER SET`命令**
   - `SET CHARACTER SET 'charset_name'`相当于执行以下三个语句：
     - `SET character_set_client = charset_name;`
     - `SET character_set_results = charset_name;`
     - `SET collation_connection = @@collation_database;`
3. **其他设置方式**
   - C应用程序可以通过`mysql_options()`在连接到服务器之前调用，根据操作系统设置使用字符集自动检测：
     - `mysql_options(mysql, MYSQL_SET_CHARSET_NAME, MYSQL_AUTODETECT_CHARSET_NAME);`
   - 每个客户端都支持`--default-character-set`选项，允许用户显式指定字符集以覆盖客户端默认值。
   - 使用mysql客户端，若要使用与默认值不同的字符集，可每次连接到服务器时显式执行`SET NAMES`语句，或在选项文件中指定字符集，如在`[mysql]`下设置`default-character-set=koi8r`。若启用了自动重新连接的mysql客户端，建议使用`charset`命令（`charset koi8r`相当于执行`SET NAMES 'koi8r'`且更改重新连接时的默认字符集）。

## 四、查看字符集和排序规则系统变量的值
使用以下语句查看适用于当前会话的字符集和排序规则系统变量的值：
```sql
SELECT * FROM performance_schema.session_variables
WHERE VARIABLE_NAME IN (
'character_set_client', 'character_set_connection',
'character_set_results', 'collation_connection'
) ORDER BY VARIABLE_NAME;
```

## 五、版本差异及特殊情况
1. **MySQL 5.7和8.0中`utf8mb4`的默认排序规则不同**
   - MySQL 5.7的默认排序规则是`utf8mb4_general_ci`，8.0的默认排序规则是`utf8mb4_0900_ai_ci`。当8.0客户端请求字符集`utf8mb4`时，发送给5.7服务器的是`utf8mb4_0900_ai_ci`，但5.7服务器无法识别，会回退到默认字符集`latin1`和排序规则`latin1_swedish_ci`。客户端可在连接后通过`SET NAMES 'utf8mb4'`使用`utf8mb4`，此时排序规则为5.7默认的`utf8mb4_general_ci`。若客户端需要`utf8mb4_0900_ai_ci`排序规则，则无法实现，需从MySQL 8.0或更高版本连接到服务器。
2. **`--character-set-client-handshake`选项影响**
   - 在MySQL 4.0中，服务器和客户端有一个“全局”字符集，由服务器管理员决定。从MySQL 4.1开始，客户端连接时会向服务器发送要使用的字符集名称，服务器据此设置相关系统变量（相当于执行`SET NAMES`操作）。但有些亚洲客户可能更喜欢MySQL 4.0的行为，为此可使用`--skip-character-set-client-handshake`选项关闭客户端发送字符集名称的“握手”过程。例如，服务器设置`--character-set-server=utf8`，客户端设置`--default-character-set=utf8`，正常情况下客户端连接后相关变量会根据客户端设置，但使用`--skip-character-set-client-handshake`后，服务器会忽略客户端设置，使用服务器端默认设置。

## 六、参考资料
https://dev.mysql.com/doc/refman/8.0/en/faqs-cjk.html（A.11 MySQL 8.0 FAQ：MySQL中文，日文和韩文字符集）

**分类**：MySQL, 字符编码与存储
**标签**：mysql, 字符集


# 问
所以在读数据的时候 在从磁盘上读好二进制数据之后，先要转成 character_set_server/character_set_database或者table/column的character set 然后再转成character_set_results 。不会再有character_set_connection/character_set_client参与了是吗？ 

# 答
是的，在读取数据时，从磁盘读取二进制数据后的转换流程如下： 

### 1. 第一次解码

- 首先会使用`character_set_server`/`character_set_database`或者表/列的字符集（如果表/列单独设置了字符集，则优先使用其设置，否则使用`character_set_database`，若`character_set_database`未设置，则使用`character_set_server`）对从磁盘读取的二进制数据进行解码，将其转换为字符。这一步是将存储时的编码格式转换为服务器端内部处理的字符格式。 
### 2. 第二次编码
- 接着，将解码后的字符使用`character_set_results`进行编码，转换为适合发送给客户端的二进制流格式。 在这个过程中，`character_set_connection`和`character_set_client`不参与从磁盘读取数据后的转换操作。`character_set_client`主要用于客户端向服务器发送数据（如SQL语句等）时的初始编码，`character_set_connection`主要用于服务器在处理客户端发送的语句时，将`character_set_client`编码的字符转换为服务器内部处理使用的编码格式，但在读取数据并发送给客户端的流程中，这两个字符集不再参与。

