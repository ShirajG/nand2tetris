require './JackTokenizer'
require './CompilationEngine'
require './SymbolTable'
require './VMWriter'

class JackCompiler
  # Converts a source file into VM code
  def initialize
    if File.file?(ARGV[0])
      CompilationEngine.new(JackTokenizer.new(ARGV[0])).analyzed_file
    end

    if File.directory?(ARGV[0])
      files = Dir[ARGV[0] + "/*.jack"]
      files.each do |file|
        CompilationEngine.new(JackTokenizer.new(file)).analyzed_file
      end
    end
  end
end

JackCompiler.new()
