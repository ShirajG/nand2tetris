class AssertionError < RuntimeError
end

def assert &block
    raise AssertionError unless yield
end

def test_encoder
  encoder = Encoder.new
  # Jump assertions
  assert {encoder.encode('jump','null') == 000}
  assert {encoder.encode('jump','JGT') == 001}
  assert {encoder.encode('jump','JEQ') == 010}
  assert {encoder.encode('jump','JGE') == 011}
  assert {encoder.encode('jump','JLT') == 100}
  assert {encoder.encode('jump','JNE') == 101}
  assert {encoder.encode('jump','JLE') == 110}
  assert {encoder.encode('jump','JMP') == 111}

  # Dest assertions
  assert {encoder.encode('dest','null') == 000}
  assert {encoder.encode('dest','M') == 001}
  assert {encoder.encode('dest','D') == 010}
  assert {encoder.encode('dest','MD') == 011}
  assert {encoder.encode('dest','A') == 100}
  assert {encoder.encode('dest','AM') == 101}
  assert {encoder.encode('dest','AD') == 110}
  assert {encoder.encode('dest','AMD') == 111}

  # Comp assertions
  assert {encoder.encode('comp','0') == 0101010}
  assert {encoder.encode('comp','1') == 0111111}
  assert {encoder.encode('comp','-1') == 0111010}
  assert {encoder.encode('comp','D') == 0001100}
  assert {encoder.encode('comp','A') == 0110000}
  assert {encoder.encode('comp','M') == 1110000}
  assert {encoder.encode('comp','!D') == 0001101}
  assert {encoder.encode('comp','!A') == 0110001}
  assert {encoder.encode('comp','!M') == 1110001}
  assert {encoder.encode('comp','-D') == 0001111}
  assert {encoder.encode('comp','-A') == 0110011}
  assert {encoder.encode('comp','-M') == 1110011}
  assert {encoder.encode('comp','D+1') == 0011111}
  assert {encoder.encode('comp','A+1') == 0110111}
  assert {encoder.encode('comp','M+1') == 1110111}
  assert {encoder.encode('comp','D-1') == 0001110}
  assert {encoder.encode('comp','A-1') == 0110010}
  assert {encoder.encode('comp','M-1') == 1110010}
  assert {encoder.encode('comp','D+A') == 0000010}
  assert {encoder.encode('comp','D+M') == 1000010}
  assert {encoder.encode('comp','D-A') == 0010011}
  assert {encoder.encode('comp','D-M') == 1010011}
  assert {encoder.encode('comp','A-D') == 0000111}
  assert {encoder.encode('comp','M-D') == 1000111}
  assert {encoder.encode('comp','D&A') == 0000000}
  assert {encoder.encode('comp','D&M') == 1000000}
  assert {encoder.encode('comp','D|A') == 0010101}
  assert {encoder.encode('comp','D|M') == 1010101}
  puts "Encoder Passing"
end

class Parser
#unpacks instructions into parts
  def initialize()
    @encoder = Encoder.new()
  end
end

class Encoder
#translates each parsed part into binary code
  attr_reader :jump_encodings
  def initialize
    @jump_encodings = {
      'null': 000,
      'JGT': 001,
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

  def encode(type,symbol)
    case type
    when 'jump'
      @jump_encodings[symbol.to_sym]
    when 'dest'
      @dest_encodings[symbol.to_sym]
    when 'comp'
      @comp_encodings[symbol.to_sym]
    end
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
# puts assembler.file
test_encoder
