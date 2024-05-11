今天同事讨论关于主键使用varchar和int的区别。  
  
我现在总结的3个问题：  
1、tablespace中空间浪费  
   当然我们知道使用varchar可能会导致辅助索引比较大，因为用到varchar可能存储的字符较多，同时  
   在行头也存在一个可变字段字符区域(1-2)字节  
   而辅助索引叶子结点毕竟都存储了主键值，这样至少会多varchar数据字节数量+1(或者2) 字节- 4(int)字节空间。  
   如果辅助索引比较多空间浪费是可想而知的。  
2、辅助索引B+树扫描性能  
    由于辅助索引B+树的空间要求更大，虽然在B+树层次一般都是3层-4层，索引单值定位I/O消耗并不明显，如果涉及到  
    范围查询(比如PAGE_CUR_G),需要访问的块就更多，同时比如例如辅助索引的using index，需要访问的块自然  
    更多  
3、比较更加复杂  
   innodb 在进行元组比较的时候，不管是DML，select都会涉及到元组的比较，同时回表的时候也涉及  
   到比较操作。而varchar类型的比较比int类型更为复杂一些。  
那么我们就来分析第三个问题，第一个问题和第二个问题是显而易见的。  
我这里数据库字符集为latin1\latin1_swedish_ci  
  
其实在innodb底层进行比较的时候都调用cmp_data这个函数  
在innodb中有自己的定义的数据类型如下：

```Cpp
1. /*-------------------------------------------*/  
    
2. /* The 'MAIN TYPE' of a column */  
    
3. #define DATA_MISSING    0    /* missing column */  
    
4. #define    DATA_VARCHAR    1    /* character varying of the  
    
5. latin1_swedish_ci charset-collation; note  
    
6. that the MySQL format for this, DATA_BINARY,  
    
7. DATA_VARMYSQL, is also affected by whether the  
    
8. 'precise type' contains  
    
9. DATA_MYSQL_TRUE_VARCHAR */  
    
10. #define DATA_CHAR    2    /* fixed length character of the  
    
11. latin1_swedish_ci charset-collation */  
    
12. #define DATA_FIXBINARY    3    /* binary string of fixed length */  
    
13. #define DATA_BINARY    4    /* binary string */  
    
14. #define DATA_BLOB    5    /* binary large object, or a TEXT type;  
    
15. if prtype & DATA_BINARY_TYPE == 0, then this is  
    
16. actually a TEXT column (or a BLOB created  
    
17. with < 4.0.14; since column prefix indexes  
    
18. came only in 4.0.14, the missing flag in BLOBs  
    
19. created before that does not cause any harm) */  
    
20. #define    DATA_INT    6    /* integer: can be any size 1 - 8 bytes */  
    
21. #define    DATA_SYS_CHILD    7    /* address of the child page in node pointer */  
    
22. #define    DATA_SYS    8    /* system column */
```

我们熟悉的int类型属于DATA_INT而varchar属于DATA_VARCHAR，rowid属于DATA_SYS  
在函数cmp_data根据各种类型的不同进行了不同比较的方式，这里就将int和varchar  
判断的方式进行说明：  
1、innodb int类型比较  
实际上是在cmp_data中进行了大概的方式如下

```Cpp
1. if (len) {  
    
2. #if defined __i386__ || defined __x86_64__ || defined _M_IX86 || defined _M_X64  
    
3. /* Compare the first bytes with a loop to avoid the call  
    
4. overhead of memcmp(). On x86 and x86-64, the GCC built-in  
    
5. (repz cmpsb) seems to be very slow, so we will be calling the  
    
6. libc version. http://gcc.gnu.org/bugzilla/show_bug.cgi?id=43052  
    
7. tracks the slowness of the GCC built-in memcmp().  
    
8.   
    
9.   
    
10. We compare up to the first 4..7 bytes with the loop.  
    
11. The (len & 3) is used for "normalizing" or  
    
12. "quantizing" the len parameter for the memcmp() call,  
    
13. in case the whole prefix is equal. On x86 and x86-64,  
    
14. the GNU libc memcmp() of equal strings is faster with  
    
15. len=4 than with len=3.  
    
16.   
    
17.   
    
18. On other architectures than the IA32 or AMD64, there could  
    
19. be a built-in memcmp() that is faster than the loop.  
    
20. We only use the loop where we know that it can improve  
    
21. the performance. */  
    
22. for (ulint i = 4 + (len & 3); i > 0; i--) {  
    
23. cmp = int(*data1++) - int(*data2++);  
    
24. if (cmp) {  
    
25. return(cmp);  
    
26. }  
    
27.   
    
28.   
    
29. if (!--len) {  
    
30. break;  
    
31. }  
    
32. }  
    
33. my_strnncollsp_simple  
    
34.   
    
35.   
    
36. if (len) {  
    
37. #endif /* IA32 or AMD64 */  
    
38. cmp = memcmp(data1, data2, len);  
    
39.   
    
40.   
    
41. if (cmp) {  
    
42. return(cmp);  
    
43. }  
    
44.   
    
45.   
    
46. data1 += len;  
    
47. data2 += len;  
    
48. #if defined __i386__ || defined __x86_64__ || defined _M_IX86 || defined _M_X64  
    
49. }  
    
50. #endif /* IA32 or AMD64 */  
    
51. }  
    
52.   
    
53.   
    
54. cmp = (int) (len1 - len2);  
    
55.   
    
56.   
    
57. if (!cmp || pad == ULINT_UNDEFINED) {  
    
58. return(cmp);  
    
59. }
60. 
```

可以看到整个方式比较简洁，对于我们常用的x86_64模型并没有直接使用memcpy进行而是  
进行了优化在注释中也有说明，才出现了for (ulint i = 4 + (len & 3); i > 0; i--)  
部分，如果是IA32 or AMD64则直接使用memcpy进行比较。感兴趣的可以仔细阅读一下  
  
2、innodb varchar类型比较  
实际上这个比较会通过cmp_data->cmp_whole_field->my_strnncollsp_simple调用最终调用  
my_strnncollsp_simple完成，而比如order by 会调用my_strnxfrm_simple他们都在一个  
文件中。  
下面是整个my_strnncollsp_simple函数

```Cpp
1. /*  
    
2.   Compare strings, discarding end space  
    
3.   
    
4.   
    
5.   SYNOPSIS  
    
6.     my_strnncollsp_simple()  
    
7.     cs    character set handler  
    
8.     a    First string to compare  
    
9.     a_length    Length of 'a'  
    
10.     b    Second string to compare  
    
11.     b_length    Length of 'b'  
    
12.     diff_if_only_endspace_difference  
    
13.        Set to 1 if the strings should be regarded as different  
    
14.                         if they only difference in end space  
    
15.   
    
16.   
    
17.   IMPLEMENTATION  
    
18.     If one string is shorter as the other, then we space extend the other  
    
19.     so that the strings have equal length.  
    
20.   
    
21.   
    
22.     This will ensure that the following things hold:  
    
23.   
    
24.   
    
25.     "a" == "a "  
    
26.     "a\0" < "a"  
    
27.     "a\0" < "a "  
    
28.   
    
29.   
    
30.   RETURN  
    
31.     < 0    a < b  
    
32.     = 0    a == b  
    
33.     > 0    a > b  
    
34. */  
    
35.   
    
36.   
    
37. int my_strnncollsp_simple(const CHARSET_INFO *cs, const uchar *a,  
    
38.                           size_t a_length, const uchar *b, size_t b_length,  
    
39.                           my_bool diff_if_only_endspace_difference)  
    
40. {  
    
41.   const uchar *map= cs->sort_order, *end;  
    
42.   size_t length;  
    
43.   int res;  
    
44.   
    
45.   
    
46. #ifndef VARCHAR_WITH_DIFF_ENDSPACE_ARE_DIFFERENT_FOR_UNIQUE  
    
47.   diff_if_only_endspace_difference= 0;  
    
48. #endif  
    
49.   
    
50.   
    
51.   end= a + (length= MY_MIN(a_length, b_length));  
    
52.   while (a < end)  
    
53.   {  
    
54.     if (map[*a++] != map[*b++])  
    
55.       return ((int) map[a[-1]] - (int) map[b[-1]]);  
    
56.   }  
    
57.   res= 0;  
    
58.   if (a_length != b_length)  
    
59.   {  
    
60.     int swap= 1;  
    
61.     if (diff_if_only_endspace_difference)  
    
62.       res= 1; /* Assume 'a' is bigger */  
    
63.     /*  
    
64.       Check the next not space character of the longer key. If it's < ' ',  
    
65.       then it's smaller than the other key.  
    
66.     */  
    
67.     if (a_length < b_length)  
    
68.     {  
    
69.       /* put shorter key in s */  
    
70.       a_length= b_length;  
    
71.       a= b;  
    
72.       swap= -1; /* swap sign of result */  
    
73.       res= -res;  
    
74.     }  
    
75.     for (end= a + a_length-length; a < end ; a++)  
    
76.     {  
    
77.       if (map[*a] != map[' '])  
    
78. return (map[*a] < map[' ']) ? -swap : swap;  
    
79.     }  
    
80.   }  
    
81.   return res;  
    
82. }
```

其中*map= cs->sort_order比较关键这是内存中已经存储好的字符集的顺序，  
循环进行  
map[*a++] != map[*b++]  
*a++和*b++ 会得到的字符集编码，然后在整个排序好的字符数组中找，  
则得到了实际字符集编码进行比较，不管是比较的复杂度还是需要比较的  
长度 varchar很可能都远远大于int类型，下面是打印cs->sort_order这片  
内存区域前128字节得到的结果，  
(gdb) x/128bx 0x258b000  
0x258b000 :          0x00    0x01    0x02    0x03    0x04    0x05    0x06    0x07  
0x258b008 :        0x08    0x09    0x0a    0x0b    0x0c    0x0d    0x0e    0x0f  
0x258b010 :       0x10    0x11    0x12    0x13    0x14    0x15    0x16    0x17  
0x258b018 :       0x18    0x19    0x1a    0x1b    0x1c    0x1d    0x1e    0x1f  
0x258b020 :       0x20    0x21    0x22    0x23    0x24    0x25    0x26    0x27  
0x258b028 :       0x28    0x29    0x2a    0x2b    0x2c    0x2d    0x2e    0x2f  
0x258b030 :       0x30    0x31    0x32    0x33    0x34    0x35    0x36    0x37  
0x258b038 :       0x38    0x39    0x3a    0x3b    0x3c    0x3d    0x3e    0x3f  
0x258b040 :       0x40    0x41    0x42    0x43    0x44    0x45    0x46    0x47  
0x258b048 :       0x48    0x49    0x4a    0x4b    0x4c    0x4d    0x4e    0x4f  
0x258b050 :       0x50    0x51    0x52    0x53    0x54    0x55    0x56    0x57  
0x258b058 :       0x58    0x59    0x5a    0x5b    0x5c    0x5d    0x5e    0x5f  
0x258b060 :       0x60    0x41    0x42    0x43    0x44    0x45    0x46    0x47  
0x258b068 :      0x48    0x49    0x4a    0x4b    0x4c    0x4d    0x4e    0x4f  
0x258b070 :      0x50    0x51    0x52    0x53    0x54    0x55    0x56    0x57  
0x258b078 :      0x58    0x59    0x5a    0x7b    0x7c    0x7d    0x7e    0x7f  
而从内存的地址0x258b000我们也能看到他确实是存在于堆内存空间中，它是一片堆内存区域。  
  
下面是varchar比较的调用栈帧以备后用

```Cpp
1. #0 my_strnncollsp_simple (cs=0x2d4b9c0, a=0x7fff57a71f93 "gaopeng", a_length=7, b=0x7fffbd7e807f "gaopeng", b_length=7, diff_if_only_endspace_difference=0 '\000')  
    
2.     at /root/mysql5.7.14/percona-server-5.7.14-7/strings/ctype-simple.c:165  
    
3. #1 0x0000000001ab8ec2 in cmp_whole_field (mtype=1, prtype=524303, a=0x7fff57a71f93 "gaopeng", a_length=7, b=0x7fffbd7e807f "gaopeng", b_length=7)  
    
4.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/rem/rem0cmp.cc:374  
    
5. #2 0x0000000001aba827 in cmp_data (mtype=1, prtype=524303, data1=0x7fff57a71f93 "gaopeng", len1=7, data2=0x7fffbd7e807f "gaopeng", len2=7)  
    
6.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/rem/rem0cmp.cc:468  
    
7. #3 0x0000000001ab9a05 in cmp_dtuple_rec_with_match_bytes (dtuple=0x7fff48ed3280, rec=0x7fffbd7e807f "gaopeng", index=0x7fff48ec78a0, offsets=0x7fff57a6bc50,  
    
8.     matched_fields=0x7fff57a6bf80, matched_bytes=0x7fff57a6bf78) at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/rem/rem0cmp.cc:880  
    
9. #4 0x0000000001a87fe2 in page_cur_search_with_match_bytes (block=0x7fffbcceafc0, index=0x7fff48ec78a0, tuple=0x7fff48ed3280, mode=PAGE_CUR_GE,  
    
10.     iup_matched_fields=0x7fff57a6cdf8, iup_matched_bytes=0x7fff57a6cdf0, ilow_matched_fields=0x7fff57a6cde8, ilow_matched_bytes=0x7fff57a6cde0, cursor=0x7fff57a713f8)  
    
11.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/page/page0cur.cc:850  
    
12. #5 0x0000000001c17a3e in btr_cur_search_to_nth_level (index=0x7fff48ec78a0, level=0, tuple=0x7fff48ed3280, mode=PAGE_CUR_GE, latch_mode=1, cursor=0x7fff57a713f0,  
    
13.     has_search_latch=0, file=0x2336938 "/root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/btr/btr0cur.cc", line=5744, mtr=0x7fff57a70ee0)  
    
14.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/btr/btr0cur.cc:1478  
    
15. #6 0x0000000001c222bf in btr_estimate_n_rows_in_range_low (index=0x7fff48ec78a0, tuple1=0x7fff48ed3280, mode1=PAGE_CUR_GE, tuple2=0x7fff48ed32e0, mode2=PAGE_CUR_G,  
    
16.     nth_attempt=1) at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/btr/btr0cur.cc:5744  
    
17. #7 0x0000000001c22a09 in btr_estimate_n_rows_in_range (index=0x7fff48ec78a0, tuple1=0x7fff48ed3280, mode1=PAGE_CUR_GE, tuple2=0x7fff48ed32e0, mode2=PAGE_CUR_G)  
    
18.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/btr/btr0cur.cc:6044  
    
19. #8 0x00000000019b3e0e in ha_innobase::records_in_range (this=0x7fff48e7e3b0, keynr=1, min_key=0x7fff57a71680, max_key=0x7fff57a716a0)  
    
20.     at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/handler/ha_innodb.cc:13938  
    
21. #9 0x0000000000f6ed5b in handler::multi_range_read_info_const (this=0x7fff48e7e3b0, keyno=1, seq=0x7fff57a71b90, seq_init_param=0x7fff57a71850, n_ranges_arg=0,  
    
22.     bufsz=0x7fff57a71780, flags=0x7fff57a71784, cost=0x7fff57a71d10) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/handler.cc:6440  
    
23. #10 0x0000000000f70662 in DsMrr_impl::dsmrr_info_const (this=0x7fff48e7e820, keyno=1, seq=0x7fff57a71b90, seq_init_param=0x7fff57a71850, n_ranges=0,  
    
24.     bufsz=0x7fff57a71d70, flags=0x7fff57a71d74, cost=0x7fff57a71d10) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/handler.cc:7112  
    
25. #11 0x00000000019be22f in ha_innobase::multi_range_read_info_const (this=0x7fff48e7e3b0, keyno=1, seq=0x7fff57a71b90, seq_init_param=0x7fff57a71850, n_ranges=0,  
    
26.     bufsz=0x7fff57a71d70, flags=0x7fff57a71d74, cost=0x7fff57a71d10) at /root/mysql5.7.14/percona-server-5.7.14-7/storage/innobase/handler/ha_innodb.cc:21351  
    
27. #12 0x000000000178c9e4 in check_quick_select (param=0x7fff57a71e30, idx=0, index_only=false, tree=0x7fff48e700e0, update_tbl_stats=true, mrr_flags=0x7fff57a71d74,  
    
28.     bufsize=0x7fff57a71d70, cost=0x7fff57a71d10) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/opt_range.cc:10030  
    
29. #13 0x0000000001783305 in get_key_scans_params (param=0x7fff57a71e30, tree=0x7fff48e70058, index_read_must_be_used=false, update_tbl_stats=true,  
    
30.     cost_est=0x7fff57a74190) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/opt_range.cc:5812  
    
31. #14 0x000000000177ce43 in test_quick_select (thd=0x7fff4801f4d0, keys_to_use=..., prev_tables=0, limit=18446744073709551615, force_quick_range=false,  
    
32.     interesting_order=st_order::ORDER_NOT_RELEVANT, tab=0x7fff48eacf20, cond=0x7fff48eacd50, needed_reg=0x7fff48eacf60, quick=0x7fff57a744c8)  
    
33.     at /root/mysql5.7.14/percona-server-5.7.14-7/sql/opt_range.cc:3066  
    
34. #15 0x000000000158b9bc in get_quick_record_count (thd=0x7fff4801f4d0, tab=0x7fff48eacf20, limit=18446744073709551615)  
    
35.     at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_optimizer.cc:5942  
    
36. #16 0x000000000158b073 in JOIN::estimate_rowcount (this=0x7fff48eac980) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_optimizer.cc:5689  
    
37. #17 0x00000000015893b5 in JOIN::make_join_plan (this=0x7fff48eac980) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_optimizer.cc:5046  
    
38. #18 0x000000000157d9b7 in JOIN::optimize (this=0x7fff48eac980) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_optimizer.cc:387  
    
39. #19 0x00000000015fab71 in st_select_lex::optimize (this=0x7fff48aa45c0, thd=0x7fff4801f4d0) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_select.cc:1009  
    
40. #20 0x00000000015f9284 in handle_query (thd=0x7fff4801f4d0, lex=0x7fff48021ab0, result=0x7fff48aa5dc8, added_options=0, removed_options=0)  
    
41.     at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_select.cc:164  
    
42. #21 0x00000000015ac159 in execute_sqlcom_select (thd=0x7fff4801f4d0, all_tables=0x7fff48aa54b8) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_parse.cc:5391  
    
43. #22 0x00000000015a4774 in mysql_execute_command (thd=0x7fff4801f4d0, first_level=true) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_parse.cc:2889  
    
44. #23 0x00000000015ad12a in mysql_parse (thd=0x7fff4801f4d0, parser_state=0x7fff57a76600) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_parse.cc:5836  
    
45. #24 0x00000000015a0fe9 in dispatch_command (thd=0x7fff4801f4d0, com_data=0x7fff57a76d70, command=COM_QUERY)  
    
46.     at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_parse.cc:1447  
    
47. #25 0x000000000159fe1a in do_command (thd=0x7fff4801f4d0) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/sql_parse.cc:1010  
    
48. #26 0x00000000016e1d6c in handle_connection (arg=0x6320740) at /root/mysql5.7.14/percona-server-5.7.14-7/sql/conn_handler/connection_handler_per_thread.cc:312  
    
49. ---Type <return> to continue, or q <return> to quit---  
    
50. #27 0x0000000001d723f4 in pfs_spawn_thread (arg=0x6320530) at /root/mysql5.7.14/percona-server-5.7.14-7/storage/perfschema/pfs.cc:2188  
    
51. #28 0x0000003ca62079d1 in start_thread () from /lib64/libpthread.so.0  
    
52. #29 0x0000003ca5ee8b6d in clone () from /lib64/libc.so.6
```

# 概念的理解

`sort_order` 是一个指向字符集排序顺序的指针，它定义了字符集中的字符如何排序。在MySQL中，字符集排序顺序通常是一个数组，其中包含了字符集中的所有字符，并且按照它们的排序顺序排列。

当MySQL需要对某个字符集中的字符进行排序时，它会使用这个排序顺序数组。例如，如果你有一个包含中文字符的字符串，并且你想要按照中文字符的排序顺序对它们进行排序，MySQL会使用`sort_order`数组来确定每个字符的位置。

具体来说，`sort_order`数组是一个256字节的数组，每个字节对应一个字符集中的字符。数组的索引是字符的编码，数组的值是该字符的排序权重。当MySQL需要比较两个字符时，它会查找这两个字符在`sort_order`数组中的值，然后比较这两个值。如果第一个字符的值小于第二个字符的值，那么第一个字符就被认为是“小于”第二个字符。

这是一个简化的例子，展示了如何使用`sort_order`数组来对字符进行排序：

```c
// 假设我们有两个字符，它们的编码分别是a和b
char a = 'a'; // 假设a的编码是97
char b = 'b'; // 假设b的编码是98

// 假设我们的sort_order数组是这样的：
// sort_order[97] = 10; // a的排序权重是10
// sort_order[98] = 20; // b的排序权重是20

// 现在我们比较a和b
if (sort_order[a] < sort_order[b]) {
    // a的排序权重小于b的排序权重，所以a应该排在b前面
    printf("a < b\n");
} else if (sort_order[a] > sort_order[b]) {
    // a的排序权重大于b的排序权重，所以a应该排在b后面
    printf("a > b\n");
} else {
    // a的排序权重等于b的排序权重，所以a和b的排序位置相同
    printf("a == b\n");
}
```

在实际的MySQL代码中，排序操作会更复杂，因为它需要处理多字节字符和字符串，并且还需要考虑字符集的状态（例如，是否处于某种特殊的排序状态）。但是，这个例子应该能帮助你理解MySQL是如何使用`sort_order`数组来对字符集中的字符进行排序的。

# gb2312是一个宽字符集。假设要比较'我‘与'他'的时候，是怎么比较的呢。

在GB2312字符集中，每个汉字或字符都由两个字节表示。当比较两个字符时，MySQL会首先比较第一个字节，然后比较第二个字节。这个过程是通过查阅`sort_order`数组来确定每个字节的排序顺序。

以下是GB2312字符集中的'我'和'他'的编码：

- '我'：GB2312编码为`CED2`，即高字节`C3`和低字节`ED`。
- '他'：GB2312编码为`CED3`，即高字节`C3`和低字节`EE`。

在`sort_order`数组中，每个字节的索引是其值，值是该字节的排序权重。当比较两个字符时，MySQL会首先比较高字节，然后比较低字节。

例如，比较'我'和'他'的排序顺序：

1. 比较高字节：
   - '我'的高字节是`C3`，排序权重是`sort_order[0xC3]`。
   - '他'的高字节也是`C3`，排序权重也是`sort_order[0xC3]`。
   - 由于两个高字节相同，继续比较低字节。

2. 比较低字节：
   - '我'的低字节是`ED`，排序权重是`sort_order[0xED]`。
   - '他'的低字节是`EE`，排序权重是`sort_order[0xEE]`。
   - 由于`sort_order[0xED]` < `sort_order[0xEE]`，所以'我'的排序顺序在'他'之前。

在MySQL中，实际的比较过程会更复杂，因为它需要处理多字节字符和字符串，并且还需要考虑字符集的状态（例如，是否处于某种特殊的排序状态）。但是，这个例子应该能帮助你理解MySQL是如何使用`sort_order`数组来对GB2312字符集中的字符进行排序的。