require 'byebug'

module Parser
  @@file = []
  @@current_line = nil
  @@command_types = {
    'add': 'C_ARITHMETIC',
    'sub': 'C_ARITHMETIC',
    'neg': 'C_ARITHMETIC',
    'eq': 'C_ARITHMETIC',
    'gt': 'C_ARITHMETIC',
    'lt': 'C_ARITHMETIC',
    'and': 'C_ARITHMETIC',
    'or': 'C_ARITHMETIC',
    'not': 'C_ARITHMETIC',
    'push': 'C_PUSH ',
    'pop': 'C_POP ',
    'label': 'C_LABEL',
    'goto': 'C_GOTO ',
    'if': 'C_IF ',
    'function': 'C_FUNCTION ',
    'return': 'C_RETURN ',
    'call': 'C_CALL'
  }

  def self.file
    @@file
  end

  def self.current_line
    @@file[@@current_line]
  end

  def self.has_more_commands
    if @@current_line.nil?
      @@file[0]
    else
      @@file[@@current_line+1]
    end
  end

  def self.advance
    if @@current_line.nil?
      @@current_line = 0
    else
      @@current_line += 1
    end
  end

  def self.command_type
    @@command_types[current_line.split(' ')[0].to_sym]
  end

  def self.init
    File.open(ARGV[0], 'r').each_line do |line|
      @@file << line.gsub(/\/\/.*$/,'').strip
    end
    @@file = @@file.compact.reject{|line| line==""}
  end

  def self.parse
    while has_more_commands
      advance
      @@file[@@current_line] = {
        command_type: command_type,
        arg1: current_line.split(' ')[1],
        arg2: current_line.split(' ')[2],
      }
    end
  end
end

module Encoder
  @@out_file = ARGV[0][0..ARGV[0].rindex('.')] + 'asm'

  def self.increment_sp
    ["@SP","M=M+1;"]
  end

  def self.decrement_sp
    ["@SP","M=M-1;"]
  end

  def self.convert_instruction(parsed_instruction)
    case parsed_instruction[:type]
    when 'push'
      [
        "//#{parsed_instruction}",
        "#{self.segments(parsed_instruction)}",
        "@SP",
        "A=M",
        "M=D"
      ] + increment_sp
    when 'pop'
      decrement_sp + [
        "//#{parsed_instruction}",
        # Store Value to Pop in R5
        "@SP",
        "A=M",
        "D=M",
        "@R5",
        "M=D",
        # Calculate memory address to write to in R6
        "#{self.segments(parsed_instruction)}",
        "D=M",
        "@#{parsed_instruction[:value]}",
        "D=D+A",
        "@R6",
        "M=D",
        # Store Value in R5 at Memory Address in R6
        "@R5",
        "D=M",
        "@R6",
        "A=M",
        "M=D"
      ]
    end
  end

  def self.segments(instruction)
    case instruction[:address]
    when 'local'
      "@LCL"
    when 'argument'
      "@ARG"
    when 'this'
      "@THIS"
    when 'that'
      "@THAT"
    when 'pointer'
      "@THIS"
    when 'temp'
      "@R5"
    when 'constant'
      "@#{instruction[:value]}\nD=A;"
    when 'static'
      "@#{ARGV[0][0..ARGV[0].rindex('.')] + instruction[:value]}\nD=M"
    end
  end

  def self.add
    self.decrement_sp + %w(
      //Add
      @SP
      A=M;
      D=M;
      A=A-1;
      D=D+M;
      M=D;
    )
  end

  def self.sub
    self.decrement_sp + %w(
      //Sub
      @SP
      A=M;
      D=M;
      A=A-1;
      D=M-D;
      M=D;
    )
  end

  def self.neg
    self.decrement_sp + %w(
      //Neg
      @SP
      A=M;
      M=-M;
    ) + self.increment_sp
  end

  def self.and
    self.decrement_sp + %w(
      //And
      @SP
      A=M;
      D=M;
      A=A-1;
      D=M&D;
      M=D;
    )
  end

  def self.or
    self.decrement_sp + %w(
      //Or
      @SP
      A=M;
      D=M;
      A=A-1;
      D=M|D;
      M=D;
    )
  end

  def self.not
    self.decrement_sp + %w(
      //Not
      @SP
      A=M;
      M=!M;
    ) + self.increment_sp
  end

  def self.eq
  # Check equality by subtracting the 2 values?
  end

  def self.gt

  end

  def self.lt

  end
end

Parser.init
Parser.parse
puts Parser.file

# File.open(out_file,'w') do |assembly|
#   assembly.write(output.compact.reject{|line| line==''}.join("\n"))
# end
