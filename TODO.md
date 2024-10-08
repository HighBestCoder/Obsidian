

1. 写一个functional index的查询SQL的PR
   - **[卡住]** 需要二毛那边重新复现这个问题，可能需要update SQL来更精确地定位这个问题
   - [TODO] 已经重现，需要问一下怎么重现
1. 写一个CAS command用来调用mysql-import - **进行中**
2. 写一个月报，用来说一下mysql import的报表
   - **[未开始]**
3. 写一个关于japan pitr cost的回复
   - **[DONE]** 写了summary关于问题2的回复
   - [DONE]
4. 写一个mysql import table corruption的RCA:
   - **[DONE]** 时间点+前后的三个snapshot PITR single server -> 都是好的
   - **[DONE]** 尝试auto migration的结果，看一下迁过去之后是不是好的 -> 问题可以复现
   - **[DONE]** 现在开始尝试使用import tablespace 到用户出现issue的server中 -> 导入成功，可以正常使用。(table名字为movements_mocked)
   - **[DONE]** 使用mysql 8.0.15, 8.0.28, 8.0.35的docker image成功加载了movements.ibd文件-> 成功，说明ibd文件本身没有问题
   - **[DONE]** 建一个自己的single-server，将ibd引入到single-server中，然后尝试mysql-import到flex中 -> 成功导入并迁移成功，不能复现
   - **[DONE]** 测试了删除dryrun节点上的userconfig文件，重启MySQL -> 问题仍然出现。
   - **[TODO]** 需要缩小一下issue server，然后copy out data，然后看看是不是系统表坏了。
   - **[TODO]** strace一下，在执行show create table xxx的时候，出错的情况下，访问了哪些文件，然后在哪些访问挂掉了？
   - **[TODO]** 注意看一下小版本的区别: https://bugs.mysql.com/bug.php?id=107941
   - **[TODO]** 否可以在迁移之后，只运行8.0.15呢？
   - [DONE] 这个是由于histogram info导致的table can not open
5. 测试Fairfax prod环境的帐号
   - **[DONE]** judy可以成功登陆
   - **[DONE]** 我这边也可以成功登陆（帐号必须全部使用小写）
   - **[DONE]** 接下来需要测试这个帐号是否可以使用mysql-import
   - [DONE] 已经完成
6. mooncake有用户要使用mysql-import cli来迁移SBS的server
   - **[备注]** 默认SBS的log_bin是OFF
   - **[备注]** 但是在migration的时候，是一定要打开的，因为pfs - replica需要binlog来工作，然后再迁移pfs-replica到flex-server
   - CSS Danny Liu给了一个excel，上面记载了SBS server的列表
   - 与suna讨论一下看看SBS的Log_bin我们应该如何处理
   - 给Sai ＆ Aditi邮件说一下我们的讨论结果
   - **[新]** Danny Liu给了我们一个server amamysqlsit01，但是这个好像是在china easte 1 标记为需要客户确认。
   - **[备注]** 我们只在china east2 和china north2支持migration
   - **[新]** Danny Liu遇到了一个 mysql-import + log_bin=ON的失败的case，需要我们trouble-shoot
	   - [vnet] vnet卡住太久
	[TODO] M29上天之后，把log_bin的error改成user error之后，从dashboard上移除。
1. 把自己写的各种powershell的函数推到PR里面，并且说明一下怎么用 - **进行中**
   - 需要添加一个参数 MainContent_WorkItemID_TextBox=IcMId
   - 需要更新一下函数的名字，要更加统一和更加容易使用
2. 计算机基础入门知识
   - **[TODO]** 讲解一下简单的计算机系统是怎么工作的
3. 两本数学的新书
    - **[TODO]** 图解数学基础入门 -> 川保久胜夫
    - **[TODO]** 数学的奥秘 -> 川保久胜夫
    - **[TODO]** 程序员的数学 用python学线性代数和微积分
    - [TODO] 漫画计算机原理 [DONE]
    - [TODO] 漫画CPU
    - [TODO] 数学乐 网站
    - [TODO] 中学数学实验教材/数量化自学丛书/数学题解辞典系列
    - [TODO] 数学要素
    - [TODO] An Excursion through Elementary - 初等数学之旅
    - [TODO] 微积分与解析几何
    - [TODO] 中学数学基础知识丛书 可能就是数学基础知识丛书 24本
    - [TODO] 数学甲种本
    - [TODO] 北京四中高中数学讲义
    - [TODO] 数学公式手册 / 高观点下的初等数学
    - [TODO] 初中数学 自学读本
    - [TODO] 中学衔接大学 教材 国外的
    - [TODO] Geometry The Easy way & Algebra The easy way
    - [TODO] 自然哲学的数学原理 / 几何原本
    - [TODO] 初等数学小丛书
    - [TODO] 线性代数的艺术
    - [TODO] 数学的故事 / 魔鬼数学 / 爱与数学 / 数学思维
    - [TODO] 代数学方法
    - [TODO] 孙维刚的四本书
    - [TODO] 形形色色的曲线
    - [TODO] 高校强基计划数学冲刺十一讲 - 周逸飞
    - [TODO] 数学的雨伞下
    - [TODO] The Art of Problem Solving Introduction to Algebra
    - [TODO] 数学基础 汪芳庭
    - [TODO] 初中数学入门学习 代数篇 张文庆
    - [TODO] 初等数学解证方法辞典
    - [TODO] 美国新数学丛书
    - [TODO]  无穷分析引论
    - [TODO] 穿越平行宇宙
    - [TODO] 数论概论  用Mathematica探索数字世界的乐趣
    - [TODO]《_数论基础_》是2011年哈尔滨工业大学出版社出版的图书，作者是_维诺格拉多夫_
    - [TODO] 微积分学教程 https://www.zhihu.com/question/31075525
    - [TODO] 天才引导的历程
	    - ![[Pasted image 20240325165959.png]]
	    - 丘维声初中数学知识补习课本
	    - 丘维声数学基础版第一册，第二册，第三册
	    - https://fanqienovel.com/reader/7340121397710031909 [初中几何解题指导]
	    - 数学题解辞典
	    - 问题解法系列数学辞典
	    - 近代欧氏几何学
	    - 数学奥林匹克中的欧几里得几何
	    - 创知路学员资料-平面几何篇
	    - 代数学辞典 几何学辞典 续几何学辞典
	    - 续几何学辞典
1. 语文语料丛书
	1. [TODO] 最佳景色描写辞典
	2. [TODO] 文学描写辞典
	3. [TODO] 写作成语分类词典
	4. [TODO] 学生作文分类成语词典
	5. ![[Pasted image 20240324215329.png]]


