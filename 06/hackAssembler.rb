class Parser
#Unpacks instructions into parts
end

class Code
#Translates each parsed part into Binary code
end

class SymbolTable
# Manages the symbol table

end

class Main
# Initialize I/O and drive the assembly
  attr_accessor :file

  def initialize
    @file = File.read(ARGV[0])
  end

  def strip_whitespace_and_comments
    @file = @file.each_line.reject do |line|
      line.strip == "" || /^\/\//.match(line.strip)
    end.each do |line|
      line.gsub!(/\/\/.*$/,'')
    end.join
  end
end

assembler=Main.new()
assembler.strip_whitespace_and_comments
puts assembler.file

