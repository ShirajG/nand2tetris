class AssertionError < RuntimeError
end

def assert &block
    raise AssertionError unless yield
end

def test_encoder
  # Jump assertions
  assert {Encoder.encode('jump','null') == 000}
  assert {Encoder.encode('jump','JGT') == 001}
  assert {Encoder.encode('jump','JEQ') == 010}
  assert {Encoder.encode('jump','JGE') == 011}
  assert {Encoder.encode('jump','JLT') == 100}
  assert {Encoder.encode('jump','JNE') == 101}
  assert {Encoder.encode('jump','JLE') == 110}
  assert {Encoder.encode('jump','JMP') == 111}

  # Dest assertions
  assert {Encoder.encode('dest','null') == 000}
  assert {Encoder.encode('dest','M') == 001}
  assert {Encoder.encode('dest','D') == 010}
  assert {Encoder.encode('dest','MD') == 011}
  assert {Encoder.encode('dest','A') == 100}
  assert {Encoder.encode('dest','AM') == 101}
  assert {Encoder.encode('dest','AD') == 110}
  assert {Encoder.encode('dest','AMD') == 111}

  # Comp assertions
  assert {Encoder.encode('comp','0') == 0101010}
  assert {Encoder.encode('comp','1') == 0111111}
  assert {Encoder.encode('comp','-1') == 0111010}
  assert {Encoder.encode('comp','D') == 0001100}
  assert {Encoder.encode('comp','A') == 0110000}
  assert {Encoder.encode('comp','M') == 1110000}
  assert {Encoder.encode('comp','!D') == 0001101}
  assert {Encoder.encode('comp','!A') == 0110001}
  assert {Encoder.encode('comp','!M') == 1110001}
  assert {Encoder.encode('comp','-D') == 0001111}
  assert {Encoder.encode('comp','-A') == 0110011}
  assert {Encoder.encode('comp','-M') == 1110011}
  assert {Encoder.encode('comp','D+1') == 0011111}
  assert {Encoder.encode('comp','A+1') == 0110111}
  assert {Encoder.encode('comp','M+1') == 1110111}
  assert {Encoder.encode('comp','D-1') == 0001110}
  assert {Encoder.encode('comp','A-1') == 0110010}
  assert {Encoder.encode('comp','M-1') == 1110010}
  assert {Encoder.encode('comp','D+A') == 0000010}
  assert {Encoder.encode('comp','D+M') == 1000010}
  assert {Encoder.encode('comp','D-A') == 0010011}
  assert {Encoder.encode('comp','D-M') == 1010011}
  assert {Encoder.encode('comp','A-D') == 0000111}
  assert {Encoder.encode('comp','M-D') == 1000111}
  assert {Encoder.encode('comp','D&A') == 0000000}
  assert {Encoder.encode('comp','D&M') == 1000000}
  assert {Encoder.encode('comp','D|A') == 0010101}
  assert {Encoder.encode('comp','D|M') == 1010101}
  puts "Encoder Passing"
end

module Parser
#unpacks instructions into parts
  def self.parse(line)
    if(line[0]== '@')
      parse_a_instruction(line)
    else
      parse_c_instruction(line)
    end
  end

  def self.parse_a_instruction(line)
    puts line
  end

  def self.parse_c_instruction(line)
    dest = 'null'
    jump = 'null'
    has_dest = line.index('=')
    has_jump = line.index(';')

    if has_dest
      dest = line[0...has_dest]
    end

    if has_jump
      jump = line[has_jump+1..-1]
    end

    { dest: dest,
      jump: jump, }
  end
end

module Encoder
#translates each parsed part into binary code
  def self.jump_encodings
    { 'null': 000,
      'JGT': 001,
      'JEQ': 010,
      'JGE': 011,
      'JLT': 100,
      'JNE': 101,
      'JLE': 110,
      'JMP': 111 }
  end

  def self.dest_encodings
    { 'null': 000,
      'M': 001,
      'D': 010,
      'MD': 011,
      'A': 100,
      'AM': 101,
      'AD': 110,
      'AMD': 111 }
  end

  def self.comp_encodings
    { '0':   0101010,
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
      'D|M': 1010101 }
  end

  def self.encode(type,symbol)
    case type
    when 'jump'
      self.jump_encodings[symbol.to_sym]
    when 'dest'
      self.dest_encodings[symbol.to_sym]
    when 'comp'
      self.comp_encodings[symbol.to_sym]
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
    @output = [];
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

test_encoder
puts Parser.parse('D=D+1;JGT')
