#!/bin/zsh

echo "步骤1：chmod +x findsymbol.sh;步骤2：findsymbol.sh xxx"
echo "⚠️注意不要使用sh findsymbol.sh 执行脚本，否则结果输出为空"
# macOS查看文件内容常用的命令小结 https://juejin.cn/post/6844904050278793229
searchSymbol=""
if [ $# -eq 0 ]
then
    echo 'Please input search Target Symbol'
    exit 0
else
    searchSymbol=$1
fi
echo "------------<开始递归搜索当前目录的源码文件和Framework文件>-------------"
searchPath="."
usefullSourceArray=()
usefullArray=()
echo "------------<扫描源码文件是否包含字符，格式包括*.a & .m & .cpp & .c & .swift>-------------"
find -L $searchPath \( -name "*.m" -o -name "*.cpp" -o -name "*.c" -o -name "*.swift" \) | while read file; do
    if grep -E "$searchSymbol" $file > /dev/null;
    then
        echo "⚠️The following strings or symbol appear a in "$file"";
        grep -nE "$searchSymbol" $file
        usefullSourceArray+=("$file")
    else
        echo "✅ No strings or symbol ${searchSymbol}  found in "$file"";
    fi;
done

echo "------------<扫描framework的符号和字符串，*.framework>-------------"
find -L $searchPath \( -name "*.framework" -o -name "*.a" \) | while read file; do
    # 查找字符串
    if strings "$file"/`basename "$file" | sed -e s/\\.framework$//g` 2>/dev/null | grep -E "$searchSymbol" > /dev/null;
    then
        echo "⚠️The following strings appear a in "$file"";
        strings "$file"/`basename "$file" | sed -e s/\\.framework$//g` 2>/dev/null | grep -nE "$searchSymbol"
        usefullArray+=("$file")
    else
        echo "✅ No strings ${searchSymbol}  found in framework "$file"";
    fi;
    # 查找符号
    if nm "$file"/`basename "$file" | sed -e s/\\.framework$//g` 2>/dev/null | grep -nE "$searchSymbol" > /dev/null;
    then
        echo "⚠️The following Symbol appear a in "$file"";
        nm "$file"/`basename "$file" | sed -e s/\\.framework$//g` 2>/dev/null | grep -nE "$searchSymbol"
        usefullArray+=("$file")
    else
        echo "✅ No symbol ${searchSymbol}  found in framework "$file"";
    fi;
done

echo "------------------------<异常汇总>------------------------"

for i in "${usefullSourceArray[@]}"
do
echo "⚠️ The following strings or symbol ${searchSymbol} appears in "$i"";
grep "$searchSymbol" $i
done
for i in "${usefullArray[@]}"
do
echo "⚠️ The following strings  ${searchSymbol} appears in "$i"";
strings "$i"/`basename "$i" | sed -e s/\\.framework$//g` 2>/dev/null | grep -nE "$searchSymbol"
echo "⚠️ The following symbol  ${searchSymbol} appears in "$i"";
nm "$i"/`basename "$i" | sed -e s/\\.framework$//g` 2>/dev/null | grep  -nE "$searchSymbol"
done
echo "------------------------<异常汇总>------------------------"

echo "🎉Done!"