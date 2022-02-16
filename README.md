# iOS 工程治理和管理的工具集合

## 删除iOS工程所有unlinked源代码文件
随着业务迭代，iOS工程会存在越来越多unlinked的代码文件。工程不改造时，unlinked文件不影响运行逻辑，可是迁移组件时会重新引入unlinked文件，导致编译错误，包大小增加等问题。举个例子，我们有一个APP的主工程有大量代码，组件化时出现各种编译问题，原因是source目录中夹杂着300多个unlinked文件。
人工区分unlinked文件成本高并且容易遗漏，因此开发了一个工具，批量删除iOS工程中的unlinked源文件（.h,.m,.mm,.swift）。

### 工具
https://github.com/blackteachinese/iOSProjectTool

### 使用说明
python3 deleteUnlinkedFiles.py "../TargetFolder" "../TargetProject.xcodeproj"

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

## 扫描iOS工程是否包含某个函数符号或字符串
findsymbol.sh脚本可以用于扫描iOS工程的源代码和framework，扫描函数符号表和数据段里的字符串， 源码文件格式范围：.a & .m & .cpp & .c & .swift framework格式范围：.framework

### 使用说明
步骤1：chmod +x findsymbol.sh
步骤2：findsymbol.sh xxx 注意：不要使用sh findsymbol.sh 执行脚本，否则结果输出为空

## 生成指定模块之间的依赖关系图

### 使用说明
步骤1：配置需要分析的模块名到podNames.txt文件
步骤2（可选）：podName和frameworkName不一致的模块，需要配映射关系
步骤2：ruby dependenceRelation.rb mainProjectPath(主工程路径) targetReposPath(待分析模块路径) isCircleMode(1/0)
