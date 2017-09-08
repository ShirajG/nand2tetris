class Parser
#Unpacks instructions into parts
  def initialize()
    @encoder = Encoder.new()
  end
end

class Encoder
#Translates each parsed part into Binary code
  def initialize
    @jump_encodings = {
      'null': 000,
      'GT': 001,
      'JEQ': 010,
      'JGE': 011,
      'JLT': 100,
      'JNE': 101,
      'JLE': 110,
      'JMP': 111
    }
    @dest_encodings = {
      'null': 000,
      'M': 001,
      'D': 010,
      'MD': 011,
      'A': 100,
      'AM': 101,
      'AD': 110,
      'AMD': 111
    }
    @comp_encodings = {
      '0':   0101010,
      '1':   0111111,
      '-1':  0111010,
      'D':   0001100,
      'A':   0110000,
      'M':   1110000,
      '!D':  0001101,
      '!A':  0110001,
      '!M':  1110001,
      '-D':  0001111,
      '-A':  0110011,
      '-M':  1110011,
      'D+1': 0011111,
      'A+1': 0110111,
      'M+1': 1110111,
      'D-1': 0001110,
      'A-1': 0110010,
      'M-1': 1110010,
      'D+A': 0000010,
      'D+M': 1000010,
      'D-A': 0010011,
      'D-M': 1010011,
      'A-D': 0000111,
      'M-D': 1000111,
      'D&A': 0000000,
      'D&M': 1000000,
      'D|A': 0010101,
      'D|M': 1010101
    }
  end

  def encode(symbol)
    @encodings[symbol]
  end
end

class SymbolTable
# Manages the symbol table

end

class Main
# Initialize I/O and drive the assembly
  attr_accessor :file

  def initialize
    @file = File.read(ARGV[0])
    @parser = Parser.new
    @symbol_table = SymbolTable.new

    strip_whitespace_and_comments
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
puts assembler.file

