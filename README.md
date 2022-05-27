# iOS架构治理常用工具集合（持续更新）

## git传送门
https://github.com/blackteachinese/iOSProjectTool

## 1.删除iOS工程所有unlinked源代码文件

随着业务迭代，iOS工程目录里会有大量没有链接的代码文件。unlinked文件不参与构建，平时不会对App造成影响。可以重构迁移文件时，很容易重新链接这些文件，导致编译错误，包大小增加。举个例子，我们有一个APP的主工程有大量代码，组件化时出现各种编译问题，原因是source目录中夹杂着300多个unlinked文件。
一开始手动删除unlinked文件，但发现成本高并且容易遗漏，最后只好开发了一个工具，批量删除iOS工程中的unlinked源文件（.h,.m,.mm,.swift）。

### 核心逻辑
iOS的工程描述都在project.pbxproj文件里，哪些文件需要被Link会被描述在PBXFileReference里，解析PBXFileReference内容可以得到所有link的文件名。

Begin PBXFileReference section
...
End PBXFileReference section

正则匹配整段文本，得到所有linked的文件名列表
re.search(r'.*(Begin PBXFileReference section.*End PBXFileReference section).*', content,re.M|re.S)

扫描目标的source目录，得到目录中所有文件名和路径
re.match(r'.*\.(mm|[hm]|swift)$', f)

将两个结果集进行differ，得到unlinked的文件列表，然后删除所有unlinked文件。注意，删除后要确保编译成功，因为如果存在同名文件可能会被误删。

### 使用说明
python3 deleteUnlinkedFiles.py "../TargetFolder" "../TargetProject.xcodeproj"


## 2. 扫描iOS工程是否包含某个函数符号或字符串

Appstore审核时会检测APP是否调用了私有API，为了确保审核顺利，发版前需要扫描私有API符号调用。于是开发了一个扫描工具，用于扫描iOS工程的源代码和framework，扫描OC函数符号表和cstring。

### 核心逻辑

遍历工程Pods文件的的所有源码Pod和Framework，使用nm命令扫描OC symbol，使用strings命令扫描CString。源码文件格式范围：.a & .m & .cpp & .c & .swift framework格式范围：.framework

### 使用说明
步骤1：chmod +x findsymbol.sh
步骤2：findsymbol.sh xxx 注意：不要使用sh findsymbol.sh 执行脚本，否则结果输出为空

## 3. 生成指定模块之间的依赖关系图

工程中难免有些不规范的Pod模块，Podspec的dependence描述不全。下面的工具可以帮组你还原podspec的依赖关系，并且生成模块之间的关系图。

### 核心逻辑

读取Pod模块的源码，从import声明中解析出外部依赖的Pod，最后将依赖关系的映射表转化为dot描述文件。

### 使用说明
步骤1：配置需要分析的模块名到podNames.txt文件
步骤2（可选）：podName和frameworkName不一致的模块，需要配映射关系
步骤2：ruby dependenceRelation.rb mainProjectPath(主工程路径) targetReposPath(待分析模块路径) isCircleMode(1/0)
