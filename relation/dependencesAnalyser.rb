require 'rubygems'
require 'cocoapods'
require 'cocoapods-core'
require 'xcodeproj'
require 'set'
require 'find'
require 'json'

module DependencesAnalyser

  def DependencesAnalyser.getSourceHeaderPath(sourceDir)
    Dir::chdir(sourceDir)
    allheadPaths = Dir::glob("**/*.{h,m}")
    return allheadPaths
  end

  def DependencesAnalyser.parseHeaderNameFromQuotationImport(allheadPaths)
    importHeaders = Set.new
    allheadPaths.each do |headerPath|
      IO.foreach(headerPath) {|line|
        if line =~ /#import.*"(.*)"/
          importHeaders << $1
        elsif line =~ /#import.*<([^\/]*)>/
          puts $1
          importHeaders << $1
        end
      }
    end
    return importHeaders
  end

  def DependencesAnalyser.parseFrameworkNameFromAngleBracketsImport(allheadPaths)
    dependences = Set.new
    allheadPaths.each do |headerPath|
      IO.foreach(headerPath) {|line|
        if line =~ /#import.*<(.*)\/.*>/
          dependences << $1
        end
      }
    end
    return dependences
  end

  def DependencesAnalyser.findFrameNameFromQuatationImportHeader(podDir, importHeaders)
    dependencesFromQuatationImport = Set.new()
    podheadPaths = findPodsHeadPaths(podDir)
    # 3.2 在podheadPaths中匹配依赖的头文件
    importHeaders.each do |targetHeader|
      for path in podheadPaths
        # include初步判断
        includeExpress = '/' + targetHeader
        if (path.include?includeExpress) == false
          next
        end
        # # 精准匹配链接
        if path =~ /Headers\/Public\/([^\/]*).*/
          # puts "取出来#{targetHeader} 属于 #{$1}"
          dependencesFromQuatationImport << $1
        end
        # Mantle.framework/Headers/Mantle.h
        if path =~ /([^\/]*).framework\/.*/
          # puts "取出来#{targetHeader} 属于 #{$1}"
          dependencesFromQuatationImport << $1
        end
      end
    end
    return dependencesFromQuatationImport
  end

  def DependencesAnalyser.findPodsHeadPaths(podDir)
    podheadPaths = []
    Dir::foreach(podDir) do |f|
      c = podDir + '/' + f
      if File::directory?(c) == false
        next
      end
      # p c + '====\n'
      Dir::chdir(c)
      rs = Dir.glob("**/*.{h,m}")
      podheadPaths = podheadPaths + rs
    end
    return podheadPaths
  end

  # TODO：生成外部依赖的头文件列表
  # 返回依赖关系，只分析白名单的列表
  def DependencesAnalyser.outPutDependence(contextHelper, whiteListfileName,podNameMapping, moduleName)
      projectToolPath = Dir::pwd
      allModuleNames = getAllModuleNames(whiteListfileName,projectToolPath)
      filtedDependences = main(contextHelper, projectToolPath, moduleName,allModuleNames,podNameMapping)
      return filtedDependences
  end

  def DependencesAnalyser.main(contextHelper,projectToolPath, moduleName, allModuleNames,podNameMapping)
    # 1修复import格式
    iOSProjectDir = contextHelper.projectDir
    podDir = contextHelper.podDir
    iOSProjectName = contextHelper.projectName
    # 读取source_files路径
    sourceDir = contextHelper.sourceDir
    if sourceDir.nil?
      puts '[Error]' + moduleName + '依赖修复失败，找不到正确的sourceDir'
      return nil
    end

    # 1 读取源文件目录下的所有.h和.m文件的路径
    allheadPaths = getSourceHeaderPath(sourceDir)
    # puts "allheadPaths：#{allheadPaths}"
    # 2 遍历所有源文件，读取文件的每一行，正则匹配出所有import的代码行
    # 2.2 如果是import "" 或者 import <xx.h> 规则引用的,解析出依赖的头文件
    importHeaders = parseHeaderNameFromQuotationImport(allheadPaths)
    # puts "import "" 引用的：#{importHeaders}"
    # 2.1 如果是import <xx/xx.h> 规则引用的直接截断出framework名
    dependences = parseFrameworkNameFromAngleBracketsImport(allheadPaths)
    # puts "过滤前 import <> 引用的：#{dependences}"
    # dependences = Set.new
    # puts importHeaders
    # 3 如果是import "" 规则引用的，判断引用的头文件是否存在Pod目录下，如果存在记录所在Pod的Framework名
    # 3.1 读取主工程Pod文件目录下所有依赖库的.h文件的路径
    dependencesFromQuatationImport = findFrameNameFromQuatationImportHeader(podDir, importHeaders)
    dependences = dependences + dependencesFromQuatationImport
    filtedDependences = filterDepencences(dependences,projectToolPath, moduleName, allModuleNames,podNameMapping)
    # 5 输出依赖关系文件
    return filtedDependences
  end

  # 只分析工程依赖的所有模块的依赖关系
  def DependencesAnalyser.filterDepencences(dependences,projectToolPath, moduleName,allModuleNames,podNameMapping)
    Dir::chdir(projectToolPath)
    filted = []
    dependences.each do |object|
      object = frameworkNameToPodName(object,podNameMapping)
      if allModuleNames.include?(object) && object != moduleName
        filted << object
      end
    end
    return filted
  end

  # 获取工程依赖的所有模块列表
  def DependencesAnalyser.getAllModuleNames(whiteListfileName,projectToolPath)
    Dir::chdir(projectToolPath)
    modules = []
    IO.foreach(whiteListfileName) do |line|
      name = line.sub!(/\n/, '') # 删除换行符
      modules << name
    end
    return modules
  end

  def DependencesAnalyser.frameworkNameToPodName(frameworkName,podNameMapping)
    # Read JSON from a file, iterate over objects
    file = open(podNameMapping)
    json = file.read
    parsed = JSON.parse(json)
    podName=parsed[frameworkName]
    if podName.nil?
      return frameworkName
    else
      p 'framework不一样，需要映射:'+ frameworkName
      return podName
    end
  end

end