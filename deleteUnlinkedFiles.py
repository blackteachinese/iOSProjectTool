from nis import match
import os
from pickle import NONE
import re
import json
import argparse

parser = argparse.ArgumentParser(description="删除iOS工程中未链接的源代码文件")
parser.add_argument('--demo',action='help',help='python3 deleteUnlinkedFiles.py ../TargetFolder ../TargetProject.xcodeproj')
parser.add_argument("targetFolder",help='输入要分析的目录路径，')
parser.add_argument('projectPath',help='输入要分析的iOS工程文件路径')
args = parser.parse_args()
print(args)

def parsePBXFileReference(targetProject):
    # 1从project.pbxproj中匹配PBXFileReference的内容
    with open(targetProject + '/project.pbxproj','r') as f:
        content = f.read()
        matchobj = re.search(r'.*(Begin PBXFileReference section.*End PBXFileReference section).*', content,re.M|re.S)
        if not matchobj:
            return
        with open('PBXFileReference.txt','w') as f:
            f.write(matchobj.group(1))
    # 2.将PBXFileReference文本解析为数组，只匹配h,m,mm,swift文件
    linkfiles = []
    with open('PBXFileReference.txt','r') as f:
        line = f.readline()
        while line:
            matchobj = re.search(r'/\* (.*\.([h,m]|mm|swift)) \*/', line)
            if matchobj:
                linkfiles.append(matchobj.group(1))
            line = f.readline()
    with open('linkfile.json','w') as f:
        object = json.dumps(linkfiles)
        f.write(object)
    return linkfiles

def findAllFileInFolder(targetFolder):
    hashmap = {}
    for root, ds, fs in os.walk(targetFolder):
        for f in fs:
            matchObj = re.match(r'.*\.(mm|[hm]|swift)$', f)
            if matchObj == None:
                continue
            fullname = os.path.join(root, f)
            hashmap[f] = fullname
    return hashmap


def findNotLinkList(linkfiles,allFileMap):
    notLinkMap = {}
    linkSet = set(linkfiles)
    for name in allFileMap:
        if name not in linkSet:
            notLinkMap[name] = allFileMap[name]
    with open('nolinkfile.json','w') as f:
        object = json.dumps(notLinkMap)
        f.write(object)
    return notLinkMap


def deleteNotLinkList(noLinkFileMap):
    for key in noLinkFileMap:
        filePath = noLinkFileMap[key]
        os.remove(filePath)

if __name__ == "__main__":
    print("开始\n")
    # 匹配目录内所有只匹配h,m,mm,swift文件，保存文件名和路径名
    allFileMap = findAllFileInFolder(args.targetFolder)
    # 解析project.pbxproj里的PBXFileReference内容，得到所有link代码源文件
    linkfiles =parsePBXFileReference(args.projectPath)
    # 搜索目标目录的所有文件，匹配出没有link的源文件
    noLinkFileMap = findNotLinkList(linkfiles,allFileMap)
    # 删除目标目录中没有link的文件
    deleteNotLinkList(noLinkFileMap)
    print("搜索到未链接的文件 \n")
    print(noLinkFileMap)
    print("结束\n")
