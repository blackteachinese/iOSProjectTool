require 'rubygems'
require 'cocoapods'
require 'cocoapods-core'
require 'xcodeproj'
require_relative './contextHelper'
require 'set'
require  'find'
require_relative './dependencesAnalyser'


#  生成图片的dot命令
# dot -Tpng -o relation.png relation.dot
def dependenceRelation(mainProjectPath,targetReposPath,isCircleMode)
    # 缓存当前路径
    rootPath=Dir::pwd
    # 依赖文件模版
    # 坑:必须用双引号换行符才会被识别
    template = "digraph G {\nrankdir=TB\nranksep=2\dependenceContent\n}"
    if isCircleMode == '1'
        # 循环依赖
        dependenceContent = getCircleRelationsDependenceContent(mainProjectPath,targetReposPath)
    else
        # 所有关系
        dependenceContent = getAllRelationsDependenceContent(mainProjectPath,targetReposPath)
    end
    
    # 替换占位符
    template.gsub!(/dependenceContent/,dependenceContent)
    # 输出到文件
    # 切换到当前目录
    Dir::chdir(rootPath)
    File.new("relation.dot","w")
    File.open("relation.dot", "r+") do |aFile|
        aFile.syswrite(template)
     end
end

def getAllRelationsDependenceContent(mainProjectPath,targetReposPath)
    dependenceContent = ''
    Dir::foreach(targetReposPath) do  |moduleName|
        if moduleName != "." && moduleName != ".." && moduleName != ".DS_Store"
            filtedDependences = getModuleDependencs(mainProjectPath,targetReposPath,moduleName)
            if filtedDependences.nil?
                p "[Error]:filtedDependences:" + moduleName
                next
            end
            # 格式化为dot
            filtedDependences.each do | object |
                dependenceContent = dependenceContent + "\n" + moduleName + " -> " + object
            end
        end
    end
    return dependenceContent
end

def getCircleRelationsDependenceContent(mainProjectPath,targetReposPath)
    relationHash = Hash.new
    dependenceContent = ''
    Dir::foreach(targetReposPath) do  |moduleName|
        if moduleName != "." && moduleName != ".." && moduleName != ".DS_Store"
            filtedDependences = getModuleDependencs(mainProjectPath,targetReposPath,moduleName)
            if filtedDependences.nil?
                p "[Error]:filtedDependences:" + moduleName
                next
            end
            # 关系存到set里
            filtedDependences.each do | object |
                array = [moduleName, object]
                array = array.sort
                key=array.join(',')
                value = relationHash[key]
                if value.nil?
                    value = 0
                end
                relationHash[key] = value + 1
            end
        end
    end
    relationHash.each do | key, value |
        p 'key' + key.to_s + 'Value:' + value.to_s
        if value >= 2
            out = key.split(',')
            dependenceContent = dependenceContent + "\n" + out[0] + " -> "  + out[1]
            dependenceContent = dependenceContent + "\n" + out[1] + " -> "  + out[0]
        end
    end
    return dependenceContent
end

def getModuleDependencs(mainProjectPath,targetReposPath,moduleName)    
    modulePath = targetReposPath + '/' + moduleName
    p '[Info]:开始解析' + modulePath
    contextHelper = ContextHelper.new(modulePath, mainProjectPath)
    if contextHelper.podSpec.nil?
        return nil
    end
    # 获取依赖关系
    filtedDependences = DependencesAnalyser::outPutDependence(contextHelper, $whiteListfileName,$podNameMapping ,moduleName)
    p filtedDependences
    if filtedDependences.nil?
        p "[Error]:filtedDependences:" + moduleName
    end
    return filtedDependences
end

mainProjectPath=ARGV[0] # 主工程 "../project/xxxMainClient"
targetReposPath=ARGV[1] # 要分析的模块所在的文件夹路径，"../project/repo"
isCircleMode = ARGV[2] #是否只统计循环依赖关系
$whiteListfileName = 'podNames.txt' #声明需要分析依赖关系的模块名单
$podNameMapping ="frameworkToPodName.json"
dependenceRelation(mainProjectPath,targetReposPath,isCircleMode)
system 'dot -Tpng -o relation.png relation.dot' #  生成图片的dot命令