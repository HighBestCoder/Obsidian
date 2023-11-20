# recover主要与file number相关

在mysql/storage/innobase/srv/srv0start.cc这个文件中
```C++
/********************************************************************
Starts InnoDB and creates a new database if database files are not found and the user wants. @return DB_SUCCESS or error code */
dberr_t
innobase_start_or_create_for_mysql(void) 
```

主要代码是在

```C++
        if (srv_force_recovery < SRV_FORCE_NO_IBUF_MERGE) {
            /* Open or Create SYS_TABLESPACES and SYS_DATAFILES
            so that tablespace names and other metadata can be
            found. */
            srv_sys_tablespaces_open = true;
            err = dict_create_or_check_sys_tablespace();
            ib::info() << "dict_create_or_check_sys_tablespace function completed.";
            if (err != DB_SUCCESS) {
                return(srv_init_abort(err));
            }

            /* The following call is necessary for the insert
            buffer to work with multiple tablespaces. We must
            know the mapping between space id's and .ibd file
            names.

            In a crash recovery, we check that the info in data
            dictionary is consistent with what we already know
            about space id's from the calls to fil_ibd_load().
            In a normal startup, we create the space objects for
            every table in the InnoDB data dictionary that has
            an .ibd file.

            We also determine the maximum tablespace id used.

            The 'validate' flag indicates that when a tablespace
            is opened, we also read the header page and validate
            the contents to the data dictionary. This is time
            consuming, especially for databases with lots of ibd
            files.  So only do it after a crash and not forcing
            recovery.  Open rw transactions at this point is not
            a good reason to validate. */

            bool validate = recv_needed_recovery
                && srv_force_recovery == 0;

  
            dict_check_tablespaces_and_store_max_id(validate);
            ib::info() << "dict_check_tablespaces_and_store_max_id function completed.";

        }
```

# 代码的含义

这段代码位于MySQL InnoDB存储引擎的启动过程中的 `innobase_start_or_create_for_mysql` 函数中，主要是在数据库启动阶段的一些初始化工作。下面是对代码的解读：

1. 首先，代码检查 `srv_force_recovery` 变量的值是否小于 `SRV_FORCE_NO_IBUF_MERGE`。`srv_force_recovery` 是控制InnoDB启动行为的一个变量，`SRV_FORCE_NO_IBUF_MERGE` 是一个常量，用于表示不强制执行insert buffer合并的级别。如果 `srv_force_recovery` 值小于此级别，说明需要执行一些特定的初始化工作。

2. 如果 `srv_force_recovery` 达到初始化要求，代码会执行以下操作：
   - 打开或创建 `SYS_TABLESPACES` 和 `SYS_DATAFILES`，这是系统数据字典表，用于存储表空间和数据文件的元数据信息。这是为了确保表空间名称和其他元数据信息可以被找到。如果出现错误，将进行错误处理。
   - 然后，调用 `dict_check_tablespaces_and_store_max_id` 函数来检查表空间并存储最大的表空间ID。这个函数还会根据需要验证表空间的内容，但只在需要执行恢复操作时以及不强制恢复的情况下才执行验证。验证是一个相对耗时的操作，特别是对于包含大量 `.ibd` 文件的数据库。

3. 在代码中，有一些日志记录（`ib::info() << ...`），用于记录函数执行的情况。这有助于调试和跟踪代码执行过程。

这段代码主要用于在InnoDB存储引擎启动时执行一些特定的初始化任务，包括打开系统表空间和数据文件，以及检查和验证表空间的信息。这些操作是确保数据库正常启动和运行的重要步骤。


validate 这个参数表明当一个表空间被打开时，同时会去读取其 ibd 文件的头页（header page）来验证数据字典的一致性，而当数据库包含许多 ibd 文件时，这个过程就会比较久，所以只在崩溃恢复且非强制恢复时执行表空间校验操作！


# dict_check_tablespaces_and_store_max_id

最后看下 **dict_check_tablespaces_and_store_max_id** 函数，根据注释介绍，这个函数会检查所有在数据字典中发现的表空间， 先检查每个共享表空间，然后检查每个独立表空间。

在**崩溃恢复**中，部分表空间已经在处理 redolog 时被打开（对应之前 GDB 调试时部分表未继续走下去），而其他没有被打开的表空间，将会通过比较数据字典中的 space_id 与表空间文件是否一致的方式进行验证（也就是之前所说的**表空间校验过程**）。

- 这个函数会先检查系统表+共公表空间
- 然后再检查所有的file-per-table的表空间

```C++
/** Check each tablespace found in the data dictionary.
Look at each general tablespace found in SYS_TABLESPACES.
Then look at each table defined in SYS_TABLES that has a space_id > 0
to find all the file-per-table tablespaces.

In a crash recovery we already have some tablespace objects created from
processing the REDO log.  Any other tablespace in SYS_TABLESPACES not
previously used in recovery will be opened here.  We will compare the
space_id information in the data dictionary to what we find in the
tablespace file. In addition, more validation will be done if recovery
was needed and force_recovery is not set.

We also scan the biggest space id, and store it to fil_system.
@param[in]	validate	true if recovery was needed */
void
dict_check_tablespaces_and_store_max_id(
	bool	validate)
{
	mtr_t	mtr;

	DBUG_ENTER("dict_check_tablespaces_and_store_max_id");

	rw_lock_x_lock(dict_operation_lock);
	mutex_enter(&dict_sys->mutex);

	/* Initialize the max space_id from sys header */
	mtr_start(&mtr);
	ulint	max_space_id = mtr_read_ulint(
		dict_hdr_get(&mtr) + DICT_HDR_MAX_SPACE_ID,
		MLOG_4BYTES, &mtr);
	mtr_commit(&mtr);

	fil_set_max_space_id_if_bigger(max_space_id);

	/* Open all general tablespaces found in SYS_TABLESPACES. */
	ulint	max1 = dict_check_sys_tablespaces(validate);

	/* Open all tablespaces referenced in SYS_TABLES.
	This will update SYS_TABLESPACES and SYS_DATAFILES if it
	finds any file-per-table tablespaces not already there. */
	ulint	max2 = dict_check_sys_tables(validate);

	/* Store the max space_id found */
	max_space_id = ut_max(max1, max2);
	fil_set_max_space_id_if_bigger(max_space_id);

	mutex_exit(&dict_sys->mutex);
	rw_lock_x_unlock(dict_operation_lock);

	DBUG_VOID_RETURN;
}
```

在这里，我们主要看`max2`，这里是去查看了所有的表空间.

```c++
/** Load and check each non-predefined tablespace mentioned in SYS_TABLES.
Search SYS_TABLES and check each tablespace mentioned that has not
already been added to the fil_system.  If it is valid, add it to the
file_system list.  Perform extra validation on the table if recovery from
the REDO log occurred.
@param[in]	validate	Whether to do validation on the table.
@return the highest space ID found. */
UNIV_INLINE
ulint
dict_check_sys_tables(
	bool		validate)
{
	ulint		max_space_id = 0;
	btr_pcur_t	pcur;
	const rec_t*	rec;
	mtr_t		mtr;
#ifndef DISABLE_INNODB_SKIP_CHECK_IBD
	uint		checked_ibd = 0;
#endif

	DBUG_ENTER("dict_check_sys_tables");

	ut_ad(rw_lock_own(dict_operation_lock, RW_LOCK_X));
	ut_ad(mutex_own(&dict_sys->mutex));

	mtr_start(&mtr);

	/* Before traversing SYS_TABLES, let's make sure we have
	SYS_TABLESPACES and SYS_DATAFILES loaded. */
	dict_table_t*	sys_tablespaces;
	dict_table_t*	sys_datafiles;
	sys_tablespaces = dict_table_get_low("SYS_TABLESPACES");
	ut_a(sys_tablespaces != NULL);
	sys_datafiles = dict_table_get_low("SYS_DATAFILES");
	ut_a(sys_datafiles != NULL);

	for (rec = dict_startscan_system(&pcur, &mtr, SYS_TABLES);
	     rec != NULL;
	     rec = dict_getnext_system(&pcur, &mtr)) {
		const byte*	field;
		ulint		len;
		char*		space_name;
		table_name_t	table_name;
		table_id_t	table_id;
		ulint		space_id;
		ulint		n_cols;
		ulint		flags;
		ulint		flags2;

		/* If a table record is not useable, ignore it and continue
		on to the next record. Error messages were logged. */
		if (dict_sys_tables_rec_check(rec) != NULL) {
			continue;
		}

		/* Copy the table name from rec */
		field = rec_get_nth_field_old(
			rec, DICT_FLD__SYS_TABLES__NAME, &len);
		table_name.m_name = mem_strdupl((char*) field, len);
		DBUG_PRINT("dict_check_sys_tables",
			   ("name: %p, '%s'", table_name.m_name,
			    table_name.m_name));

		dict_sys_tables_rec_read(rec, table_name,
					 &table_id, &space_id,
					 &n_cols, &flags, &flags2);
		if (flags == ULINT_UNDEFINED
		    || is_system_tablespace(space_id)) {
			ut_free(table_name.m_name);
			continue;
		}

		if (flags2 & DICT_TF2_DISCARDED) {
			ib::info() << "Ignoring tablespace " << table_name
				<< " because the DISCARD flag is set .";
			ut_free(table_name.m_name);
			continue;
		}

		/* If the table is not a predefined tablespace then it must
		be in a file-per-table or shared tablespace.
		Note that flags2 is not available for REDUNDANT tables,
		so don't check those. */
		ut_ad(DICT_TF_HAS_SHARED_SPACE(flags)
		      || !DICT_TF_GET_COMPACT(flags)
		      || flags2 & DICT_TF2_USE_FILE_PER_TABLE);

		/* Look up the tablespace name in the data dictionary if this
		is a shared tablespace.  For file-per-table, the table_name
		and the tablespace_name are the same.
		Some hidden tables like FTS AUX tables may not be found in
		the dictionary since they can always be found in the default
		location. If so, then dict_space_get_name() will return NULL,
		the space name must be the table_name, and the filepath can be
		discovered in the default location.*/
		char*	shared_space_name = dict_space_get_name(space_id, NULL);
		space_name = shared_space_name == NULL
			? table_name.m_name
			: shared_space_name;

		/* Now that we have the proper name for this tablespace,
		whether it is a shared tablespace or a single table
		tablespace, look to see if it is already in the tablespace
		cache. */
		if (fil_space_for_table_exists_in_mem(
			    space_id, space_name, false, true, NULL, 0)) {
			/* Recovery can open a datafile that does not
			match SYS_DATAFILES.  If they don't match, update
			SYS_DATAFILES. */
			char *dict_path = dict_get_first_path(space_id);
			char *fil_path = fil_space_get_first_path(space_id);
			if (dict_path && fil_path
			    && strcmp(dict_path, fil_path)) {
				dict_update_filepath(space_id, fil_path);
			}
			ut_free(dict_path);
			ut_free(fil_path);
			ut_free(table_name.m_name);
			ut_free(shared_space_name);
			continue;
		}

		/* Set the expected filepath from the data dictionary.
		If the file is found elsewhere (from an ISL or the default
		location) or this path is the same file but looks different,
		fil_ibd_open() will update the dictionary with what is
		opened. */
		char*	filepath = dict_get_first_path(space_id);

		/* Check that the .ibd file exists. */
		bool	is_temp = flags2 & DICT_TF2_TEMPORARY;
		bool	is_encrypted = flags2 & DICT_TF2_ENCRYPTION;
		ulint	fsp_flags = dict_tf_to_fsp_flags(flags,
							 is_temp,
							 is_encrypted);

#ifndef DISABLE_INNODB_SKIP_CHECK_IBD
		my_bool skip_check_ibd = srv_skip_check_ibd;

		if (skip_check_ibd) {
			if (checked_ibd < srv_skip_ibd_limit)
				skip_check_ibd = FALSE;
		}

		if (validate || !skip_check_ibd)
#endif
		{
			dberr_t	err = fil_ibd_open(
				validate,
				!srv_read_only_mode && srv_log_file_size != 0,
				FIL_TYPE_TABLESPACE,
				space_id,
				fsp_flags,
				space_name,
				filepath);

			if (err != DB_SUCCESS) {
				ib::warn() << "Ignoring tablespace "
					<< id_name_t(space_name)
					<< " because it could not be opened.";
			}
#ifndef DISABLE_INNODB_SKIP_CHECK_IBD
			else {
				++checked_ibd;
			}
#endif
		}

		max_space_id = ut_max(max_space_id, space_id);

		ut_free(table_name.m_name);
		ut_free(shared_space_name);
		ut_free(filepath);
	}

	mtr_commit(&mtr);

	DBUG_RETURN(max_space_id);
}
```