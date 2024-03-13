
首先根据windbg找到源码行数

```Cpp
bool store_create_info(THD *thd, Table_ref *table_list, String *packet,

                       HA_CREATE_INFO *create_info_arg, bool show_database,

                       bool for_show_create_stmt) {

  char tmp[MAX_FIELD_WIDTH], buff[128], def_value_buf[MAX_FIELD_WIDTH];

  const char *alias;

  String type(tmp, sizeof(tmp), system_charset_info);

  String def_value(def_value_buf, sizeof(def_value_buf), system_charset_info);

  Field **ptr, *field;

  uint primary_key;

  KEY *key_info;

  TABLE *table = table_list->table;

  handler *file = table->file;   <---- 1950行在这里

  TABLE_SHARE *share = table->s;

  HA_CREATE_INFO create_info;

  bool show_table_options = false;

  bool foreign_db_mode = (thd->variables.sql_mode & MODE_ANSI) != 0;

  my_bitmap_map *old_map;

  bool error = false;

  DBUG_TRACE;

  DBUG_PRINT("enter", ("table: %s", table->s->table_name.str));
```

那么，我们需要看一下`table_list`这个结构体的内容
```Cpp
0:000> dt table_list
Local var @ rsi Type Table_ref*
   +0x000 next_local       : (null) 
   +0x008 next_global      : (null) 
   +0x010 prev_global      : 0x00007703`4e2f89c0  -> 0x000076fc`85fc1338 Table_ref
   +0x018 db               : 0x000076fc`85fc19a0  "prd-spark-trf-be-reporting"
   +0x020 table_name       : 0x000076fc`85fc0cd0  "movements"
   +0x028 alias            : 0x000076fc`85fc1328  "movements"
   +0x030 target_tablespace_name : MYSQL_LEX_CSTRING
   +0x040 option           : (null) 
   +0x048 opt_hints_table  : (null) 
   +0x050 opt_hints_qb     : (null) 
   +0x058 m_tableno        : 0
   +0x060 m_map            : 1
   +0x068 m_join_cond      : (null) 
   +0x070 m_is_sj_or_aj_nest : 0
   +0x078 sj_inner_tables  : 0
   +0x080 natural_join     : (null) 
   +0x088 is_natural_join  : 0
   +0x090 join_using_fields : (null) 
   +0x098 join_columns     : (null) 
   +0x0a0 is_join_columns_complete : 0
   +0x0a8 next_name_resolution_table : (null) 
   +0x0b0 index_hints      : (null) 
   +0x0b8 table            : (null)    <-- !!!!这里为空!!!!!!
   +0x0c0 table_id         : Table_id
   +0x0c8 derived_result   : (null) 
   +0x0d0 correspondent_table : (null) 
   +0x0d8 table_function   : (null) 
   +0x0e0 access_path_for_derived : (null) 
   +0x0e8 derived          : (null) 
   +0x0f0 m_common_table_expr : (null) 
   +0x0f8 m_derived_column_names : (null) 
   +0x100 schema_table     : (null) 
   +0x108 schema_query_block : (null) 
   +0x110 schema_table_reformed : 0
   +0x118 query_block      : 0x000076fc`85fc0fa8 Query_block
   +0x120 view             : (null) 
   +0x128 field_translation : (null) 
   +0x130 field_translation_end : (null) 
   +0x138 merge_underlying_list : (null) 
   +0x140 view_tables      : (null) 
   +0x148 belong_to_view   : (null) 
   +0x150 referencing_view : (null) 
   +0x158 parent_l         : (null) 
   +0x160 security_ctx     : (null) 
   +0x168 view_sctx        : (null) 
   +0x170 next_leaf        : (null) 
   +0x178 derived_where_cond : (null) 
   +0x180 check_option     : (null) 
   +0x188 replace_filter   : (null) 
   +0x190 select_stmt      : MYSQL_LEX_STRING
   +0x1a0 source           : MYSQL_LEX_STRING
   +0x1b0 timestamp        : MYSQL_LEX_STRING
   +0x1c0 definer          : LEX_USER
   +0x2a0 updatable_view   : 0
   +0x2a8 algorithm        : 0
   +0x2b0 view_suid        : 0
   +0x2b8 with_check       : 0
   +0x2c0 effective_algorithm : 0 ( VIEW_ALGORITHM_UNDEFINED )
   +0x2c4 m_lock_descriptor : Lock_descriptor
   +0x2d0 grant            : GRANT_INFO
   +0x308 outer_join       : 0
   +0x309 join_order_swapped : 0
   +0x30c shared           : 0
   +0x310 db_length        : 0x1a
   +0x318 table_name_length : 9
   +0x320 m_updatable      : 0
   +0x321 m_insertable     : 0
   +0x322 m_updated        : 0
   +0x323 m_inserted       : 0
   +0x324 m_deleted        : 0
   +0x325 m_fulltext_searched : 0
   +0x326 straight         : 0
   +0x327 updating         : 0
   +0x328 ignore_leaves    : 0
   +0x330 dep_tables       : 0
   +0x338 join_cond_dep_tables : 0
   +0x340 nested_join      : (null) 
   +0x348 embedding        : (null) 
   +0x350 join_list        : (null) 
   +0x358 cacheable_table  : 1
   +0x35c open_type        : 0 ( OT_TEMPORARY_OR_BASE )
   +0x360 contain_auto_increment : 0
   +0x361 check_option_processed : 0
   +0x362 replace_filter_processed : 0
   +0x364 required_type    : 0 ( INVALID_TABLE )
   +0x368 timestamp_buffer : [20]  ""
   +0x37c prelocking_placeholder : 0
   +0x380 open_strategy    : 0 ( OPEN_NORMAL )
   +0x384 internal_tmp_table : 0
   +0x385 is_alias         : 0
   +0x386 is_fqtn          : 0
   +0x387 m_was_scalar_subquery : 0
   +0x388 view_creation_ctx : (null) 
   +0x390 view_client_cs_name : MYSQL_LEX_CSTRING
   +0x3a0 view_connection_cl_name : MYSQL_LEX_CSTRING
   +0x3b0 view_body_utf8   : MYSQL_LEX_STRING
   +0x3c0 is_system_view   : 0
   +0x3c1 is_dd_ctx_table  : 0
   +0x3c8 derived_key_list : List<Derived_key>
   +0x3e0 trg_event_map    : 0 ''
   +0x3e1 schema_table_filled : 0
   +0x3e8 mdl_request      : MDL_request
   +0x5a8 view_no_explain  : 0
   +0x5b0 partition_names  : (null) 
   +0x5b8 m_join_cond_optim : (null) 
   +0x5c0 cond_equal       : (null) 
   +0x5c8 optimized_away   : 0
   +0x5c9 derived_keys_ready : 0
   +0x5ca m_is_recursive_reference : 0
   +0x5cc m_table_ref_type : 0 ( TABLE_REF_NULL )
   +0x5d0 m_table_ref_version : 0
   +0x5d8 covering_keys_saved : Bitmap<64>
   +0x5e0 merge_keys_saved : Bitmap<64>
   +0x5e8 keys_in_use_for_query_saved : Bitmap<64>
   +0x5f0 keys_in_use_for_group_by_saved : Bitmap<64>
   +0x5f8 keys_in_use_for_order_by_saved : Bitmap<64>
   +0x600 nullable_saved   : 0
   +0x601 force_index_saved : 0
   +0x602 force_index_order_saved : 0
   +0x603 force_index_group_saved : 0
   +0x608 lock_partitions_saved : MY_BITMAP
   +0x620 read_set_saved   : MY_BITMAP
   +0x638 write_set_saved  : MY_BITMAP
   +0x650 read_set_internal_saved : MY_BITMAP

```

这里看到`table_list->table`是空的，那么切换到上一层栈看看
```Cpp
0:000> kb
 # RetAddr               : Args to Child                                                           : Call Site
00 00007703`5c94601e     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!syscall_no_intercept+0x1d [/__w/1/s/thirdparty/syscall_intercept/src/util.S @ 71] 
01 00007703`5c947f75     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_routine+0x13e [/__w/1/s/thirdparty/syscall_intercept/src/intercept.c @ 691] 
02 00007703`5caefe6a     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_wrapper+0x141 [/__w/1/s/thirdparty/syscall_intercept/src/intercept_wrapper.S @ 171] 
03 00006302`df28e16d     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!__pthread_kill_implementation+0xea [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_kill.c @ 43] 
04 00007703`5caa4e30     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_fatal_signal+0x8d [/source/sql/signal_handler.cc @ 238] 
05 00006302`df19a6d6     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_restore_rt
06 (Inline Function)     : --------`-------- --------`-------- --------`-------- --------`-------- : mysqld!String::String+0xffffffff`ffffffa2 [/source/include/sql_string.h @ 205] 
07 00006302`df1a1286     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!store_create_info+0x66 [/source/sql/sql_show.cc @ 1950] 
08 00006302`df1a3dcc     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysqld_show_create+0x9f6 [/source/sql/sql_show.cc @ 1186] 
09 00006302`df126196     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!Sql_cmd_show_create_table::execute_inner+0xec [/source/sql/sql_show.cc @ 409] 
0a 00006302`df12a064     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysql_execute_command+0xd66 [/source/sql/sql_parse.cc @ 3816] 
0b 00006302`df12b314     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_sql_command+0x4f4 [/source/sql/sql_parse.cc @ 5903] 
0c 00006302`df12d727     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_command+0xd14 [/source/sql/sql_parse.cc @ 2445] 
0d 00006302`df27eb18     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!do_command+0x1e7 [/source/sql/sql_parse.cc @ 1826] 
0e 00006302`e0801225     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_connection+0x2b8 [/source/sql/conn_handler/connection_handler_per_thread.cc @ 320] 
0f 00007703`5caee1d2     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!pfs_spawn_thread+0xf5 [/source/storage/perfschema/pfs.cc @ 3045] 
10 00007703`5cb6f084     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!start_thread+0x2c2 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_create.c @ 442] 
11 ffffffff`ffffffff     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_GI___clone+0x44 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/misc/../sysdeps/unix/sysv/linux/x86_64/clone.S @ 102] 
12 00000000`00000000     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : 0xffffffff`ffffffff
0:000> .frame 08
08 00007703`4e2f7e60 00006302`df1a3dcc     mysqld!mysqld_show_create+0x9f6 [/source/sql/sql_show.cc @ 1186] 

```

调用代码的位置

```Cpp
函数 mysqld_show_create() {

   //....
  if (table_list->is_view())
    view_store_create_info(thd, table_list, &buffer);
  else if (store_create_info(thd, table_list, &buffer, nullptr,  <-- 1186
                             false /* show_database */,
                             true /* SHOW CREATE TABLE */))

    goto exit;
}
```

我们再看调用`mysql_show_create()`的位置
```Cpp
  

bool Sql_cmd_show_create_table::execute_inner(THD *thd) {

  // Prepare a local LEX object for expansion of table/view

  LEX *old_lex = thd->lex;

  LEX local_lex;

  

  Pushed_lex_guard lex_guard(thd, &local_lex);

  

  LEX *lex = thd->lex;

  

  lex->only_view = m_is_view;

  lex->sql_command = old_lex->sql_command;

  

  // Disable constant subquery evaluation as we won't be locking tables.

  lex->context_analysis_only = CONTEXT_ANALYSIS_ONLY_VIEW;

  

  if (lex->query_block->add_table_to_list(thd, m_table_ident, nullptr, 0) ==

      nullptr)

    return true;

  Table_ref *tbl = lex->query_tables;   <-- 这里设置table_list!

  

  /*

    Access check:

    SHOW CREATE TABLE require any privileges on the table level (ie

    effecting all columns in the table).

    SHOW CREATE VIEW require the SHOW_VIEW and SELECT ACLs on the table level.

    NOTE: SHOW_VIEW ACL is checked when the view is created.

  */

  DBUG_PRINT("debug", ("lex->only_view: %d, table: %s.%s", lex->only_view,

                       tbl->db, tbl->table_name));

  if (lex->only_view) {

    if (check_table_access(thd, SELECT_ACL, tbl, false, 1, false)) {

      DBUG_PRINT("debug", ("check_table_access failed"));

      my_error(ER_TABLEACCESS_DENIED_ERROR, MYF(0), "SHOW",

               thd->security_context()->priv_user().str,

               thd->security_context()->host_or_ip().str, tbl->alias);

      return true;

    }

    DBUG_PRINT("debug", ("check_table_access succeeded"));

  

    // Ignore temporary tables if this is "SHOW CREATE VIEW"

    tbl->open_type = OT_BASE_ONLY;

  } else {

    /*

      Temporary tables should be opened for SHOW CREATE TABLE, but not

      for SHOW CREATE VIEW.

    */

    if (open_temporary_tables(thd, tbl)) return true;

  

    /*

      The fact that check_some_access() returned false does not mean that

      access is granted. We need to check if first_table->grant.privilege

      contains any table-specific privilege.

    */

    DBUG_PRINT("debug", ("tbl->grant.privilege: %lx", tbl->grant.privilege));

    if (check_some_access(thd, TABLE_OP_ACLS, tbl) ||

        (tbl->grant.privilege & TABLE_OP_ACLS) == 0) {

      my_error(ER_TABLEACCESS_DENIED_ERROR, MYF(0), "SHOW",

               thd->security_context()->priv_user().str,

               thd->security_context()->host_or_ip().str, tbl->alias);

      return true;

    }

  }

  

  if (mysqld_show_create(thd, tbl)) return true;   <-- 在这里调用!!

  

  return false;

}
```

然后上一层的调用

![[Pasted image 20240304112159.png]]


```
Local source search path is: SRV*
0:000> kb
*** WARNING: Unable to verify timestamp for libc.so.6
*** WARNING: Unable to verify timestamp for mysqld
 # RetAddr               : Args to Child                                                           : Call Site
00 00007703`5c94601e     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!syscall_no_intercept+0x1d [/__w/1/s/thirdparty/syscall_intercept/src/util.S @ 71] 
01 00007703`5c947f75     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_routine+0x13e [/__w/1/s/thirdparty/syscall_intercept/src/intercept.c @ 691] 
02 00007703`5caefe6a     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_wrapper+0x141 [/__w/1/s/thirdparty/syscall_intercept/src/intercept_wrapper.S @ 171] 
03 00006302`df28e16d     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!__pthread_kill_implementation+0xea [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_kill.c @ 43] 
04 00007703`5caa4e30     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_fatal_signal+0x8d [/source/sql/signal_handler.cc @ 238] 
05 00006302`df19a6d6     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_restore_rt
06 (Inline Function)     : --------`-------- --------`-------- --------`-------- --------`-------- : mysqld!String::String+0xffffffff`ffffffa2 [/source/include/sql_string.h @ 205] 
07 00006302`df1a1286     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!store_create_info+0x66 [/source/sql/sql_show.cc @ 1950] 
08 00006302`df1a3dcc     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysqld_show_create+0x9f6 [/source/sql/sql_show.cc @ 1186] 
09 00006302`df126196     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!Sql_cmd_show_create_table::execute_inner+0xec [/source/sql/sql_show.cc @ 409] 
0a 00006302`df12a064     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysql_execute_command+0xd66 [/source/sql/sql_parse.cc @ 3816] 
0b 00006302`df12b314     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_sql_command+0x4f4 [/source/sql/sql_parse.cc @ 5903] 
0c 00006302`df12d727     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_command+0xd14 [/source/sql/sql_parse.cc @ 2445] 
0d 00006302`df27eb18     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!do_command+0x1e7 [/source/sql/sql_parse.cc @ 1826] 
0e 00006302`e0801225     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_connection+0x2b8 [/source/sql/conn_handler/connection_handler_per_thread.cc @ 320] 
0f 00007703`5caee1d2     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!pfs_spawn_thread+0xf5 [/source/storage/perfschema/pfs.cc @ 3045] 
10 00007703`5cb6f084     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!start_thread+0x2c2 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_create.c @ 442] 
11 ffffffff`ffffffff     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_GI___clone+0x44 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/misc/../sysdeps/unix/sysv/linux/x86_64/clone.S @ 102] 
12 00000000`00000000     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : 0xffffffff`ffffffff
0:000> .frame 0a
0a 00007703`4e2f9360 00006302`df12a064     mysqld!mysql_execute_command+0xd66 [/source/sql/sql_parse.cc @ 3816] 
0:000> dt thd
???? 
Memory read error 0000000000f86196
0:000> dt lex
Local var @ r15 Type LEX*
   +0x008 sql_command      : 18 ( SQLCOM_SHOW_CREATE )
   +0x010 query_tables     : (null) 
   +0x018 query_tables_last : 0x00007703`55339410  -> (null) 
   +0x020 query_tables_own_last : (null) 
   +0x028 sroutines        : std::unique_ptr<malloc_unordered_map<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, Sroutine_hash_entry*, std::hash<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::equal_to<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > >, std::default_delete<malloc_unordered_map<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, Sroutine_hash_entry*, std::hash<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::equal_to<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > > > >
   +0x030 sroutines_list   : SQL_I_List<Sroutine_hash_entry>
   +0x048 sroutines_list_own_last : 0x00007703`55339438  -> (null) 
   +0x050 sroutines_list_own_elements : 0
   +0x054 lock_tables_state : 0 ( LTS_NOT_LOCKED )
   +0x058 table_count      : 0
   +0x05c binlog_stmt_flags : 0
   +0x060 stmt_accessed_table_flag : 0
   +0x064 using_match      : 0
   +0x065 stmt_unsafe_with_mixed_mode : 0
   +0x000 _vptr.LEX        : 0x00006302`e1c25570  -> 0x00006302`df0fc4f0     int  mysqld!LEX::~LEX+0
   +0x068 unit             : 0x000076fc`85fc0870 Query_expression
   +0x070 query_block      : 0x000076fc`85fc0950 Query_block
   +0x078 all_query_blocks_list : 0x000076fc`85fc0950 Query_block
   +0x080 m_current_query_block : 0x000076fc`85fc0950 Query_block
   +0x088 is_explain_analyze : 0
   +0x089 using_hypergraph_optimizer : 0
   +0x090 name             : MYSQL_LEX_STRING
   +0x0a0 help_arg         : (null) 
   +0x0a8 to_log           : (null) 
   +0x0b0 x509_subject     : (null) 
   +0x0b8 x509_issuer      : (null) 
   +0x0c0 ssl_cipher       : (null) 
   +0x0c8 wild             : (null) 
   +0x0d0 result           : (null) 
   +0x0d8 binlog_stmt_arg  : MYSQL_LEX_STRING
   +0x0e8 ident            : MYSQL_LEX_STRING
   +0x0f8 grant_user       : (null) 
   +0x100 alter_password   : LEX_ALTER
   +0x12c alter_user_attribute : 0 ( ALTER_USER_COMMENT_NOT_USED )
   +0x130 alter_user_comment_text : MYSQL_LEX_STRING
   +0x140 grant_as         : LEX_GRANT_AS
   +0x158 thd              : 0x00007703`55361000 THD
   +0x160 opt_hints_global : (null) 
   +0x168 plugins          : Prealloced_array<st_plugin_int*, 16>
   +0x1f0 insert_table     : (null) 
   +0x1f8 insert_table_leaf : (null) 
   +0x200 create_view_query_block : MYSQL_LEX_STRING
   +0x210 part_info        : (null) 
   +0x218 definer          : (null) 
   +0x220 users_list       : List<LEX_USER>
   +0x238 columns          : List<LEX_COLUMN>
   +0x250 dynamic_privileges : List<MYSQL_LEX_CSTRING>
   +0x268 default_roles    : (null) 
   +0x270 bulk_insert_row_cnt : 0
   +0x278 purge_value_list : List<Item>
   +0x290 kill_value_list  : List<Item>
   +0x2a8 var_list         : List<set_var_base>
   +0x2c0 set_var_list     : List<Item_func_set_user_var>
   +0x2d8 param_list       : List<Item_param>
   +0x2f0 insert_update_values_map : (null) 
   +0x2f8 context_stack    : List<Name_resolution_context>
   +0x310 in_sum_func      : (null) 
   +0x318 udf              : udf_func
   +0x370 check_opt        : HA_CHECK_OPT
   +0x380 create_info      : 0x000076fc`85fc0d88 HA_CREATE_INFO
   +0x388 key_create_info  : KEY_CREATE_INFO
   +0x3e0 mi               : LEX_MASTER_INFO
   +0x548 slave_connection : struct_slave_connection
   +0x568 server_options   : Server_options
   +0x5f0 mqh              : user_resources
   +0x604 reset_slave_info : LEX_RESET_SLAVE
   +0x608 type             : 0
   +0x610 allow_sum_func   : 0
   +0x618 m_deny_window_func : 0
   +0x620 m_subquery_to_derived_is_impossible : 0
   +0x628 m_sql_cmd        : 0x000076fc`85fc0d40 Sql_cmd
   +0x630 expr_allows_subselect : 1
   +0x634 reparse_common_table_expr_at : 0
   +0x638 reparse_derived_table_condition : 0
   +0x640 reparse_derived_table_params_at : std::vector<unsigned int, std::allocator<unsigned int> >
   +0x658 ssl_type         : 0xffffffff (No matching name)
   +0x65c duplicates       : 0 ( DUP_ERROR )
   +0x660 tx_isolation     : 0 ( ISO_READ_UNCOMMITTED )
   +0x664 option_type      : 0 ( OPT_DEFAULT )
   +0x668 create_view_mode : 0 ( VIEW_CREATE_NEW )
   +0x66c show_profile_query_id : 0
   +0x670 profile_options  : 0
   +0x674 grant            : 0
   +0x678 grant_tot_col    : 0
   +0x67c grant_privilege  : 0
   +0x680 slave_thd_opt    : 0
   +0x684 start_transaction_opt : 0
   +0x688 select_number    : 0n1
   +0x68c create_view_algorithm : 0 ''
   +0x68d create_view_check : 0 ''
   +0x68e context_analysis_only : 0 ''
   +0x68f drop_if_exists   : 0
   +0x690 grant_if_exists  : 0
   +0x691 ignore_unknown_user : 0
   +0x692 drop_temporary   : 0
   +0x693 autocommit       : 0
   +0x694 verbose          : 0
   +0x695 no_write_to_binlog : 0
   +0x696 m_extended_show  : 0
   +0x698 tx_chain         : 0 ( TVL_YES )
   +0x69c tx_release       : 0 ( TVL_YES )
   +0x6a0 safe_to_cache_query : 1
   +0x6a1 m_has_udf        : 0
   +0x6a2 ignore           : 0
   +0x6a3 parsing_options  : st_parsing_options
   +0x6a8 alter_info       : (null) 
   +0x6b0 prepared_stmt_name : MYSQL_LEX_CSTRING
   +0x6c0 prepared_stmt_code : MYSQL_LEX_STRING
   +0x6d0 prepared_stmt_code_is_varref : 0
   +0x6d8 prepared_stmt_params : List<MYSQL_LEX_STRING>
   +0x6f0 sphead           : (null) 
   +0x6f8 spname           : (null) 
   +0x700 sp_lex_in_use    : 0
   +0x701 all_privileges   : 0
   +0x702 contains_plaintext_password : 0
   +0x704 keep_diagnostics : 0 ( DA_KEEP_NOTHING )
   +0x708 next_binlog_file_nr : 0
   +0x70c m_broken         : 0
   +0x70d m_exec_started   : 0
   +0x70e m_exec_completed : 0
   +0x710 sp_current_parsing_ctx : (null) 
   +0x718 m_statement_options : 0
   +0x720 sp_chistics      : st_sp_chistics
   +0x740 event_parse_data : (null) 
   +0x748 only_view        : 0
   +0x749 create_view_suid : 0x1 ''
   +0x750 stmt_definition_begin : (null) 
   +0x758 stmt_definition_end : (null) 
   +0x760 use_only_table_context : 0
   +0x761 is_lex_started   : 1
   +0x762 in_update_value_clause : 0
   +0x768 explain_format   : (null) 
   +0x770 max_execution_time : 0
   +0x778 binlog_need_explicit_defaults_ts : 0
   +0x779 will_contextualize : 1
   +0x780 m_IS_table_stats : dd::info_schema::Table_statistics
   +0x840 m_IS_tablespace_stats : dd::info_schema::Tablespace_statistics
   +0x958 m_secondary_engine_context : (null) 
   +0x960 m_is_replication_deprecated_syntax_used : 0
   +0x961 m_was_replication_command_executed : 0
   +0x962 rewrite_required : 0
0:000> kb
 # RetAddr               : Args to Child                                                           : Call Site
00 00007703`5c94601e     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!syscall_no_intercept+0x1d [/__w/1/s/thirdparty/syscall_intercept/src/util.S @ 71] 
01 00007703`5c947f75     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_routine+0x13e [/__w/1/s/thirdparty/syscall_intercept/src/intercept.c @ 691] 
02 00007703`5caefe6a     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libsyscall_intercept!intercept_wrapper+0x141 [/__w/1/s/thirdparty/syscall_intercept/src/intercept_wrapper.S @ 171] 
03 00006302`df28e16d     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!__pthread_kill_implementation+0xea [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_kill.c @ 43] 
04 00007703`5caa4e30     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_fatal_signal+0x8d [/source/sql/signal_handler.cc @ 238] 
05 00006302`df19a6d6     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_restore_rt
06 (Inline Function)     : --------`-------- --------`-------- --------`-------- --------`-------- : mysqld!String::String+0xffffffff`ffffffa2 [/source/include/sql_string.h @ 205] 
07 00006302`df1a1286     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!store_create_info+0x66 [/source/sql/sql_show.cc @ 1950] 
08 00006302`df1a3dcc     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysqld_show_create+0x9f6 [/source/sql/sql_show.cc @ 1186] 
09 00006302`df126196     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!Sql_cmd_show_create_table::execute_inner+0xec [/source/sql/sql_show.cc @ 409] 
0a 00006302`df12a064     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!mysql_execute_command+0xd66 [/source/sql/sql_parse.cc @ 3816] 
0b 00006302`df12b314     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_sql_command+0x4f4 [/source/sql/sql_parse.cc @ 5903] 
0c 00006302`df12d727     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!dispatch_command+0xd14 [/source/sql/sql_parse.cc @ 2445] 
0d 00006302`df27eb18     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!do_command+0x1e7 [/source/sql/sql_parse.cc @ 1826] 
0e 00006302`e0801225     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!handle_connection+0x2b8 [/source/sql/conn_handler/connection_handler_per_thread.cc @ 320] 
0f 00007703`5caee1d2     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : mysqld!pfs_spawn_thread+0xf5 [/source/storage/perfschema/pfs.cc @ 3045] 
10 00007703`5cb6f084     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!start_thread+0x2c2 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/nptl/pthread_create.c @ 442] 
11 ffffffff`ffffffff     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : libc_so!_GI___clone+0x44 [/usr/src/debug/glibc-2.35-6.cm2.x86_64/misc/../sysdeps/unix/sysv/linux/x86_64/clone.S @ 102] 
12 00000000`00000000     : 00000000`00000000 00000000`00000000 00000000`00000000 00000000`00000000 : 0xffffffff`ffffffff
0:000> .frame 0a
0a 00007703`4e2f9360 00006302`df12a064     mysqld!mysql_execute_command+0xd66 [/source/sql/sql_parse.cc @ 3816] 
0:000> dt all_tables
Local var Type Table_ref*
Value unavailable.
0:000> dt all_tables
Local var Type Table_ref*
Value unavailable.
0:000> dv
                            sctx = <value unavailable>
                             thd = 0x00007703`55361000
                     first_level = true
                             res = 0n0
                             lex = 0x00007703`55339400
                     query_block = <value unavailable>
                     first_table = 0x00000000`00000000
                      all_tables = <value unavailable>
gtid_consistency_violation_state = false
                         ktr_cmd = SQLCOM_SHOW_CREATE (0n24)
      early_error_on_rep_command = false
                             ots = Opt_trace_start
                   trace_command = Opt_trace_object
             trace_command_steps = Opt_trace_array
                autocommit_guard = <value unavailable>
                        __func__ = char [22] "mysql_execute_command"
0:000> .frame 09
09 00007703`4e2f89a0 00006302`df126196     mysqld!Sql_cmd_show_create_table::execute_inner+0xec [/source/sql/sql_show.cc @ 409] 
0:000> dt lex
Local var @ r12 Type LEX*
   +0x008 sql_command      : 18 ( SQLCOM_SHOW_CREATE )
   +0x010 query_tables     : 0x000076fc`85fc1338 Table_ref
   +0x018 query_tables_last : 0x000076fc`85fc1340  -> (null) 
   +0x020 query_tables_own_last : (null) 
   +0x028 sroutines        : std::unique_ptr<malloc_unordered_map<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, Sroutine_hash_entry*, std::hash<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::equal_to<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > >, std::default_delete<malloc_unordered_map<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, Sroutine_hash_entry*, std::hash<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::equal_to<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > > > >
   +0x030 sroutines_list   : SQL_I_List<Sroutine_hash_entry>
   +0x048 sroutines_list_own_last : 0x00007703`4e2f89e8  -> (null) 
   +0x050 sroutines_list_own_elements : 0
   +0x054 lock_tables_state : 0 ( LTS_NOT_LOCKED )
   +0x058 table_count      : 0
   +0x05c binlog_stmt_flags : 0
   +0x060 stmt_accessed_table_flag : 0
   +0x064 using_match      : 0
   +0x065 stmt_unsafe_with_mixed_mode : 0
   +0x000 _vptr.LEX        : 0x00006302`e1c25570  -> 0x00006302`df0fc4f0     int  mysqld!LEX::~LEX+0
   +0x068 unit             : 0x000076fc`85fc0ec8 Query_expression
   +0x070 query_block      : 0x000076fc`85fc0fa8 Query_block
   +0x078 all_query_blocks_list : 0x000076fc`85fc0fa8 Query_block
   +0x080 m_current_query_block : 0x000076fc`85fc0fa8 Query_block
   +0x088 is_explain_analyze : 0
   +0x089 using_hypergraph_optimizer : 0
   +0x090 name             : MYSQL_LEX_STRING
   +0x0a0 help_arg         : 0x00006302`df3a0540  "UH???"
   +0x0a8 to_log           : 0x00000005`00002560  "--- memory read error at address 0x00000005`00002560 ---"
   +0x0b0 x509_subject     : (null) 
   +0x0b8 x509_issuer      : (null) 
   +0x0c0 ssl_cipher       : (null) 
   +0x0c8 wild             : (null) 
   +0x0d0 result           : (null) 
   +0x0d8 binlog_stmt_arg  : MYSQL_LEX_STRING
   +0x0e8 ident            : MYSQL_LEX_STRING
   +0x0f8 grant_user       : 0x00007703`5538c180 LEX_USER
   +0x100 alter_password   : LEX_ALTER
   +0x12c alter_user_attribute : 0 ( ALTER_USER_COMMENT_NOT_USED )
   +0x130 alter_user_comment_text : MYSQL_LEX_STRING
   +0x140 grant_as         : LEX_GRANT_AS
   +0x158 thd              : 0x00007703`55361000 THD
   +0x160 opt_hints_global : (null) 
   +0x168 plugins          : Prealloced_array<st_plugin_int*, 16>
   +0x1f0 insert_table     : (null) 
   +0x1f8 insert_table_leaf : (null) 
   +0x200 create_view_query_block : MYSQL_LEX_STRING
   +0x210 part_info        : (null) 
   +0x218 definer          : 0x000076fc`85ced278 LEX_USER
   +0x220 users_list       : List<LEX_USER>
   +0x238 columns          : List<LEX_COLUMN>
   +0x250 dynamic_privileges : List<MYSQL_LEX_CSTRING>
   +0x268 default_roles    : (null) 
   +0x270 bulk_insert_row_cnt : 0
   +0x278 purge_value_list : List<Item>
   +0x290 kill_value_list  : List<Item>
   +0x2a8 var_list         : List<set_var_base>
   +0x2c0 set_var_list     : List<Item_func_set_user_var>
   +0x2d8 param_list       : List<Item_param>
   +0x2f0 insert_update_values_map : (null) 
   +0x2f8 context_stack    : List<Name_resolution_context>
   +0x310 in_sum_func      : (null) 
   +0x318 udf              : udf_func
   +0x370 check_opt        : HA_CHECK_OPT
   +0x380 create_info      : (null) 
   +0x388 key_create_info  : KEY_CREATE_INFO
   +0x3e0 mi               : LEX_MASTER_INFO
   +0x548 slave_connection : struct_slave_connection
   +0x568 server_options   : Server_options
   +0x5f0 mqh              : user_resources
   +0x604 reset_slave_info : LEX_RESET_SLAVE
   +0x608 type             : 0x20
   +0x610 allow_sum_func   : 0
   +0x618 m_deny_window_func : 0
   +0x620 m_subquery_to_derived_is_impossible : 0
   +0x628 m_sql_cmd        : (null) 
   +0x630 expr_allows_subselect : 1
   +0x634 reparse_common_table_expr_at : 0
   +0x638 reparse_derived_table_condition : 0
   +0x640 reparse_derived_table_params_at : std::vector<unsigned int, std::allocator<unsigned int> >
   +0x658 ssl_type         : 0xffffffff (No matching name)
   +0x65c duplicates       : 0 ( DUP_ERROR )
   +0x660 tx_isolation     : 0xe21da3e0 (No matching name)
   +0x664 option_type      : 0 ( OPT_DEFAULT )
   +0x668 create_view_mode : 0 ( VIEW_CREATE_NEW )
   +0x66c show_profile_query_id : 0x7703
   +0x670 profile_options  : 0
   +0x674 grant            : 0
   +0x678 grant_tot_col    : 0
   +0x67c grant_privilege  : 0
   +0x680 slave_thd_opt    : 0xe5a27be0
   +0x684 start_transaction_opt : 0x76fc
   +0x688 select_number    : 0n1
   +0x68c create_view_algorithm : 0 ''
   +0x68d create_view_check : 0x77 'w'
   +0x68e context_analysis_only : 0x2 ''
   +0x68f drop_if_exists   : 0
   +0x690 grant_if_exists  : 0
   +0x691 ignore_unknown_user : 0
   +0x692 drop_temporary   : 0
   +0x693 autocommit       : 55
   +0x694 verbose          : 3
   +0x695 no_write_to_binlog : 77
   +0x696 m_extended_show  : 0
   +0x698 tx_chain         : 0xe21da3e0 (No matching name)
   +0x69c tx_release       : 0x6302 (No matching name)
   +0x6a0 safe_to_cache_query : 1
   +0x6a1 m_has_udf        : 0
   +0x6a2 ignore           : 0
   +0x6a3 parsing_options  : st_parsing_options
   +0x6a8 alter_info       : (null) 
   +0x6b0 prepared_stmt_name : MYSQL_LEX_CSTRING
   +0x6c0 prepared_stmt_code : MYSQL_LEX_STRING
   +0x6d0 prepared_stmt_code_is_varref : ffffffffffffff90
   +0x6d8 prepared_stmt_params : List<MYSQL_LEX_STRING>
   +0x6f0 sphead           : (null) 
   +0x6f8 spname           : (null) 
   +0x700 sp_lex_in_use    : 0
   +0x701 all_privileges   : 0
   +0x702 contains_plaintext_password : 0
   +0x704 keep_diagnostics : 0 ( DA_KEEP_NOTHING )
   +0x708 next_binlog_file_nr : 0
   +0x70c m_broken         : 0
   +0x70d m_exec_started   : 0
   +0x70e m_exec_completed : 0
   +0x710 sp_current_parsing_ctx : (null) 
   +0x718 m_statement_options : 0
   +0x720 sp_chistics      : st_sp_chistics
   +0x740 event_parse_data : (null) 
   +0x748 only_view        : 0
   +0x749 create_view_suid : 0x1 ''
   +0x750 stmt_definition_begin : (null) 
   +0x758 stmt_definition_end : 0x00007703`553ff018  ""
   +0x760 use_only_table_context : 0
   +0x761 is_lex_started   : 1
   +0x762 in_update_value_clause : 0
   +0x768 explain_format   : (null) 
   +0x770 max_execution_time : 0
   +0x778 binlog_need_explicit_defaults_ts : 0
   +0x779 will_contextualize : 1
   +0x780 m_IS_table_stats : dd::info_schema::Table_statistics
   +0x840 m_IS_tablespace_stats : dd::info_schema::Tablespace_statistics
   +0x958 m_secondary_engine_context : (null) 
   +0x960 m_is_replication_deprecated_syntax_used : 0
   +0x961 m_was_replication_command_executed : 0
   +0x962 rewrite_required : 0
0:000> dt tbl
Local var @ r13 Type Table_ref*
   +0x000 next_local       : (null) 
   +0x008 next_global      : (null) 
   +0x010 prev_global      : 0x00007703`4e2f89c0  -> 0x000076fc`85fc1338 Table_ref
   +0x018 db               : 0x000076fc`85fc19a0  "prd-spark-trf-be-reporting"
   +0x020 table_name       : 0x000076fc`85fc0cd0  "movements"
   +0x028 alias            : 0x000076fc`85fc1328  "movements"
   +0x030 target_tablespace_name : MYSQL_LEX_CSTRING
   +0x040 option           : (null) 
   +0x048 opt_hints_table  : (null) 
   +0x050 opt_hints_qb     : (null) 
   +0x058 m_tableno        : 0
   +0x060 m_map            : 1
   +0x068 m_join_cond      : (null) 
   +0x070 m_is_sj_or_aj_nest : 0
   +0x078 sj_inner_tables  : 0
   +0x080 natural_join     : (null) 
   +0x088 is_natural_join  : 0
   +0x090 join_using_fields : (null) 
   +0x098 join_columns     : (null) 
   +0x0a0 is_join_columns_complete : 0
   +0x0a8 next_name_resolution_table : (null) 
   +0x0b0 index_hints      : (null) 
   +0x0b8 table            : (null) 
   +0x0c0 table_id         : Table_id
   +0x0c8 derived_result   : (null) 
   +0x0d0 correspondent_table : (null) 
   +0x0d8 table_function   : (null) 
   +0x0e0 access_path_for_derived : (null) 
   +0x0e8 derived          : (null) 
   +0x0f0 m_common_table_expr : (null) 
   +0x0f8 m_derived_column_names : (null) 
   +0x100 schema_table     : (null) 
   +0x108 schema_query_block : (null) 
   +0x110 schema_table_reformed : 0
   +0x118 query_block      : 0x000076fc`85fc0fa8 Query_block
   +0x120 view             : (null) 
   +0x128 field_translation : (null) 
   +0x130 field_translation_end : (null) 
   +0x138 merge_underlying_list : (null) 
   +0x140 view_tables      : (null) 
   +0x148 belong_to_view   : (null) 
   +0x150 referencing_view : (null) 
   +0x158 parent_l         : (null) 
   +0x160 security_ctx     : (null) 
   +0x168 view_sctx        : (null) 
   +0x170 next_leaf        : (null) 
   +0x178 derived_where_cond : (null) 
   +0x180 check_option     : (null) 
   +0x188 replace_filter   : (null) 
   +0x190 select_stmt      : MYSQL_LEX_STRING
   +0x1a0 source           : MYSQL_LEX_STRING
   +0x1b0 timestamp        : MYSQL_LEX_STRING
   +0x1c0 definer          : LEX_USER
   +0x2a0 updatable_view   : 0
   +0x2a8 algorithm        : 0
   +0x2b0 view_suid        : 0
   +0x2b8 with_check       : 0
   +0x2c0 effective_algorithm : 0 ( VIEW_ALGORITHM_UNDEFINED )
   +0x2c4 m_lock_descriptor : Lock_descriptor
   +0x2d0 grant            : GRANT_INFO
   +0x308 outer_join       : 0
   +0x309 join_order_swapped : 0
   +0x30c shared           : 0
   +0x310 db_length        : 0x1a
   +0x318 table_name_length : 9
   +0x320 m_updatable      : 0
   +0x321 m_insertable     : 0
   +0x322 m_updated        : 0
   +0x323 m_inserted       : 0
   +0x324 m_deleted        : 0
   +0x325 m_fulltext_searched : 0
   +0x326 straight         : 0
   +0x327 updating         : 0
   +0x328 ignore_leaves    : 0
   +0x330 dep_tables       : 0
   +0x338 join_cond_dep_tables : 0
   +0x340 nested_join      : (null) 
   +0x348 embedding        : (null) 
   +0x350 join_list        : (null) 
   +0x358 cacheable_table  : 1
   +0x35c open_type        : 0 ( OT_TEMPORARY_OR_BASE )
   +0x360 contain_auto_increment : 0
   +0x361 check_option_processed : 0
   +0x362 replace_filter_processed : 0
   +0x364 required_type    : 0 ( INVALID_TABLE )
   +0x368 timestamp_buffer : [20]  ""
   +0x37c prelocking_placeholder : 0
   +0x380 open_strategy    : 0 ( OPEN_NORMAL )
   +0x384 internal_tmp_table : 0
   +0x385 is_alias         : 0
   +0x386 is_fqtn          : 0
   +0x387 m_was_scalar_subquery : 0
   +0x388 view_creation_ctx : (null) 
   +0x390 view_client_cs_name : MYSQL_LEX_CSTRING
   +0x3a0 view_connection_cl_name : MYSQL_LEX_CSTRING
   +0x3b0 view_body_utf8   : MYSQL_LEX_STRING
   +0x3c0 is_system_view   : 0
   +0x3c1 is_dd_ctx_table  : 0
   +0x3c8 derived_key_list : List<Derived_key>
   +0x3e0 trg_event_map    : 0 ''
   +0x3e1 schema_table_filled : 0
   +0x3e8 mdl_request      : MDL_request
   +0x5a8 view_no_explain  : 0
   +0x5b0 partition_names  : (null) 
   +0x5b8 m_join_cond_optim : (null) 
   +0x5c0 cond_equal       : (null) 
   +0x5c8 optimized_away   : 0
   +0x5c9 derived_keys_ready : 0
   +0x5ca m_is_recursive_reference : 0
   +0x5cc m_table_ref_type : 0 ( TABLE_REF_NULL )
   +0x5d0 m_table_ref_version : 0
   +0x5d8 covering_keys_saved : Bitmap<64>
   +0x5e0 merge_keys_saved : Bitmap<64>
   +0x5e8 keys_in_use_for_query_saved : Bitmap<64>
   +0x5f0 keys_in_use_for_group_by_saved : Bitmap<64>
   +0x5f8 keys_in_use_for_order_by_saved : Bitmap<64>
   +0x600 nullable_saved   : 0
   +0x601 force_index_saved : 0
   +0x602 force_index_order_saved : 0
   +0x603 force_index_group_saved : 0
   +0x608 lock_partitions_saved : MY_BITMAP
   +0x620 read_set_saved   : MY_BITMAP
   +0x638 write_set_saved  : MY_BITMAP
   +0x650 read_set_internal_saved : MY_BITMAP
0:000> dt m_table_ident

```


看起来是这里

```Cpp
bool Sql_cmd_show_create_table::execute_inner(THD *thd) {
  // Prepare a local LEX object for expansion of table/view
  LEX *old_lex = thd->lex;
  LEX local_lex;
  Pushed_lex_guard lex_guard(thd, &local_lex);
  LEX *lex = thd->lex;
  lex->only_view = m_is_view;
  lex->sql_command = old_lex->sql_command;
  // Disable constant subquery evaluation as we won't be locking tables.
  lex->context_analysis_only = CONTEXT_ANALYSIS_ONLY_VIEW;
  /// -----> !!!! add_table_to_list !!! 这里修改了query_tables
  if (lex->query_block->add_table_to_list(thd, m_table_ident, nullptr, 0) ==
      nullptr)
    return true;
  Table_ref *tbl = lex->query_tables;
  /*
    Access check:
    SHOW CREATE TABLE require any privileges on the table level (ie
    effecting all columns in the table).
    SHOW CREATE VIEW require the SHOW_VIEW and SELECT ACLs on the table level.
    NOTE: SHOW_VIEW ACL is checked when the view is created.
  */
  DBUG_PRINT("debug", ("lex->only_view: %d, table: %s.%s", lex->only_view,
                       tbl->db, tbl->table_name));
  if (lex->only_view) {
    if (check_table_access(thd, SELECT_ACL, tbl, false, 1, false)) {
      DBUG_PRINT("debug", ("check_table_access failed"));
      my_error(ER_TABLEACCESS_DENIED_ERROR, MYF(0), "SHOW",
               thd->security_context()->priv_user().str,
               thd->security_context()->host_or_ip().str, tbl->alias);
      return true;
    }
    DBUG_PRINT("debug", ("check_table_access succeeded"));
    // Ignore temporary tables if this is "SHOW CREATE VIEW"
    tbl->open_type = OT_BASE_ONLY;
  } else {
    /*
      Temporary tables should be opened for SHOW CREATE TABLE, but not
      for SHOW CREATE VIEW.
    */

    if (open_temporary_tables(thd, tbl)) return true;

    /*
      The fact that check_some_access() returned false does not mean that
      access is granted. We need to check if first_table->grant.privilege
      contains any table-specific privilege.
    */
    DBUG_PRINT("debug", ("tbl->grant.privilege: %lx", tbl->grant.privilege));
    if (check_some_access(thd, TABLE_OP_ACLS, tbl) ||
        (tbl->grant.privilege & TABLE_OP_ACLS) == 0) {
      my_error(ER_TABLEACCESS_DENIED_ERROR, MYF(0), "SHOW",
               thd->security_context()->priv_user().str,
               thd->security_context()->host_or_ip().str, tbl->alias);
      return true;
    }
  }

  if (mysqld_show_create(thd, tbl)) return true;

  return false;

}
```

在这个函数的这个位置

```Cpp
  /// -----> !!!! add_table_to_list !!! 这里修改了query_tables
  if (lex->query_block->add_table_to_list(thd, m_table_ident, nullptr, 0) ==
      nullptr)
    return true;
  Table_ref *tbl = lex->query_tables;
```

会去修改query_tables

# mysql_show_create

```Cpp
bool mysqld_show_create(THD *thd, Table_ref *table_list) {
  Protocol *protocol = thd->get_protocol();
  char buff[2048];
  mem_root_deque<Item *> field_list(thd->mem_root);
  String buffer(buff, sizeof(buff), system_charset_info);
  bool error = true;
  DBUG_TRACE;
  DBUG_PRINT("enter",
             ("db: %s  table: %s", table_list->db, table_list->table_name));

  /*
    Metadata locks taken during SHOW CREATE should be released when
    the statmement completes as it is an information statement.
  */
  MDL_savepoint mdl_savepoint = thd->mdl_context.mdl_savepoint();

  /*
    Use open_tables() instead of open_tables_for_query(). If an error occurs,
    this will ensure that tables are not closed on error, but remain open
    for the rest of the processing of the SHOW statement.
  */
  Prepared_stmt_arena_holder ps_arena_holder(thd);
  uint counter;
  bool open_error = open_tables(thd, &table_list, &counter,
                                MYSQL_OPEN_FORCE_SHARED_HIGH_PRIO_MDL);
  if (open_error && (thd->killed || thd->is_error())) goto exit;

  buffer.length(0);

  if (store_create_info(thd, table_list, &buffer, nullptr,
                        false /* show_database */,
                        true /* SHOW CREATE TABLE */))
    goto exit;
}

```

注意，在这个函数这里会去调用

```Cpp
  bool open_error = open_tables(thd, &table_list, &counter,
                                MYSQL_OPEN_FORCE_SHARED_HIGH_PRIO_MDL);
  if (open_error && (thd->killed || thd->is_error())) goto exit;
```

去打开表！

