class AssertionError < RuntimeError
end

def assert &block
    raise AssertionError unless yield
end

def test_encoder
  jump_inputs = [
    'null',
    'JGT',
    'JEQ',
    'JGE',
    'JLT',
    'JNE',
    'JLE',
    'JMP'
  ]

  jump_expected_outputs = [
    000,
    001,
    010,
    011,
    100,
    101,
    110,
    111
  ]

  dest_inputs = [
    'null',
    'M',
    'D',
    'MD',
    'A',
    'AM',
    'AD',
    'AMD'
  ]

  dest_expected_outputs = [
    000,
    001,
    010,
    011,
    100,
    101,
    110,
    111
  ]

  comp_inputs = [
    '0',
    '1',
    '-1',
    'D',
    'A',
    'M',
    '!D',
    '!A',
    '!M',
    '-D',
    '-A',
    '-M',
    'D+1',
    'A+1',
    'M+1',
    'D-1',
    'A-1',
    'M-1',
    'D+A',
    'D+M',
    'D-A',
    'D-M',
    'A-D',
    'M-D',
    'D&A',
    'D&M',
    'D|A',
    'D|M'
  ]

  comp_expected_outputs = [
    0101010,
    0111111,
    0111010,
    0001100,
    0110000,
    1110000,
    0001101,
    0110001,
    1110001,
    0001111,
    0110011,
    1110011,
    0011111,
    0110111,
    1110111,
    0001110,
    0110010,
    1110010,
    0000010,
    1000010,
    0010011,
    1010011,
    0000111,
    1000111,
    0000000,
    1000000,
    0010101,
    1010101
  ]

  ['jump','dest','comp'].each do |type|
    eval("#{type}_inputs").each_with_index do |el, i|
      assert do
        Encoder.encode(type,el) == eval("#{type}_expected_outputs")[i]
      end
    end
  end

  puts "Encoder Passing"
end

def test_parser
  inputs = [
    'M',
    'A;JMP',
    'AM=0',
    'MD=-1;JEQ'
  ]

  expected_outputs = [
    {comp:'M',jump:'null',dest:'null'},
    {comp:'A',jump:'JMP',dest:'null'},
    {comp:'0',jump:'null',dest:'AM'},
    {comp:'-1',jump:'JEQ',dest:'MD'},
  ]

  inputs.each_with_index do |el, i|
    assert do
      Parser.parse(el) == expected_outputs[i]
    end
  end

  puts 'Parser Passing'
end

def test_symbol_table
  table = SymbolTable.new
  inputs = [
    'R0', 'R1', 'R2', 'R3', 'R4',
    'R5', 'R6', 'R7', 'R8', 'R9',
    'R10', 'R11', 'R12', 'R13', 'R14',
    'R15', 'SP', 'LCL', 'ARG', 'THIS',
    'THAT', 'SCREEN', 'KBD'
  ]
  expected_outputs = [
    0, 1, 2, 3, 4, 5, 6,
    7, 8, 9, 10, 11, 12,
    13, 14, 15, 0, 1, 2,
    3, 4, 16384, 24576
  ]

  inputs.each_with_index do |el, i|
    assert{ table.get(inputs[i]) == expected_outputs[i] }
  end
  puts 'Symbol Table Passing'
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

  def self.parse_a_instruction(linue)
    # Should resolve symbols and variables
    puts line
  end

  def self.parse_c_instruction(line)
    dest = 'null'
    jump = 'null'
    has_dest = line.index('=')
    has_jump = line.index(';')
    comp_start = 0
    comp_end = -1

    if has_dest
      dest = line[0...has_dest]
      comp_start=has_dest + 1
    end

    if has_jump
      jump = line[has_jump+1..-1]
      comp_end = has_jump - 1
    end

    {
      comp: line[comp_start..comp_end],
      dest: dest,
      jump: jump,
    }
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
  attr_reader :table
  def initialize
    @table = {
      'SP': 0,
      'LCL': 1,
      'ARG': 2,
      'THIS': 3,
      'THAT': 4,
      'SCREEN': 16384,
      'KBD': 24576,
      'R0': 0,
      'R1': 1,
      'R2': 2,
      'R3': 3,
      'R4': 4,
      'R5': 5,
      'R6': 6,
      'R7': 7,
      'R8': 8,
      'R9': 9,
      'R10': 10,
      'R11': 11,
      'R12': 12,
      'R13': 13,
      'R14': 14,
      'R15': 15
    }
  end

  def add(arg)
    @table[arg[symbol]] = arg[value]
  end

  def get(symbol)
    @table[symbol.to_sym]
  end
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
test_parser
test_symbol_table
