require 'cocoapods'
require 'cocoapods-core'
require 'xcodeproj'
require 'rubygems'

class ContextHelper
  def initialize(modulePath, mainProjectPath)
    @modulePath = modulePath
    @mainProjectPath = Pathname.new(mainProjectPath)
    @root_path = Pathname.new(@modulePath)
    @podSpec = podSpec()
  end

  def rootPath()
    @root_path
  end

  def podSpec()
    podSpecFinder = Pod::Sandbox::PodspecFinder.new(@root_path)
    podspecs = podSpecFinder.podspecs
    podspec = nil
    podspecs.each_value do |value|
      podspec = value
    end

    if podspec.nil?
      p "[Error]:" + @modulePath.to_s
      return nil
    end
    return podspec
  end

  def projectDir()
    iOSProjectDir = @root_path.to_s + '/'
  end

  def podDir()
    podDir = @mainProjectPath.join('Pods').to_s # TODO:要保证podspec文件里的dependence完成
  end

  def projectName()
    iOSProjectName = @podSpec.name
  end

  def sourceDir()
    consumer = Pod::Specification::Consumer.new(@podSpec,Pod::Platform.ios)
    sourceFiles = consumer.source_files[0]
    puts sourceFiles
    if sourceFiles.nil?
      return nil
    end
    sourcePath = sourceFiles.split('/')[0]
    sourceDir = projectDir() + sourcePath
  end
end

