module Parser
# Converts strings from a VM file into parsed commands
  @@file = []
  @@parsed_file = []
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
    'push': 'C_PUSH',
    'pop': 'C_POP',
    'label': 'C_LABEL',
    'goto': 'C_GOTO ',
    'if-goto': 'C_IF',
    'function': 'C_FUNCTION',
    'return': 'C_RETURN',
    'call': 'C_CALL'
  }

  def self.init(filename)
    File.open(filename, 'r').each_line do |line|
      @@file << line.gsub(/\/\/.*$/,'').strip
    end
    @@file = @@file.compact.reject{|line| line==""}
  end

  def self.file
    @@files
  end

  def self.parsed_file
    @@parsed_file
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
    c_type = @@command_types[current_line.split(' ')[0].to_sym]
    if c_type == 'C_ARITHMETIC'
      return current_line.split(' ')[0]
    end
    c_type
  end

  def self.parse
    while has_more_commands
      advance
      @@parsed_file[@@current_line] = {
        command_type: command_type,
        arg1: current_line.split(' ')[1],
        arg2: current_line.split(' ')[2],
      }
    end
  end
end

module Encoder
# Converts parsed VM commands into Hack Assembly Code
  @@out_file = nil
  @@current_file_name = nil
  @@label_id = 0

  def self.file
    @@out_file
  end

  def self.set_out_file_name(filename)
    filename[0..filename.rindex('.')] + 'asm'
  end

  def self.encode(parsed_file)
    @@current_file_name = parsed_file[:name][(parsed_file[:name].rindex('/')+1)...parsed_file[:name].rindex('.')]
    @@out_file = File.open(set_out_file_name(parsed_file[:name]), 'w')
    @@out_file << "// " + @@current_file_name + ".asm\n"
    parsed_file[:file].each do |parsed_line|
      case parsed_line[:command_type]
      when 'C_PUSH'
        write_push_pop(
          parsed_line[:command_type],
          parsed_line[:arg1],
          parsed_line[:arg2]
        )
      when 'C_POP'
        write_push_pop(
          parsed_line[:command_type],
          parsed_line[:arg1],
          parsed_line[:arg2]
        )
      when 'C_IF'
        write_if(parsed_line[:arg1])
      when 'C_LABEL'
        write_label(parsed_line[:arg1])
      else
        write_arithmetic(parsed_line[:command_type])
      end
    end
    @@out_file.close
  end

  def self.write_arithmetic(command)
    @@out_file << self.send(command).join("\n") << "\n"
  end

  def self.write_push_pop(command, segment, index)
    case command
    when 'C_PUSH'
      case segment
      when 'constant'
        @@out_file << push_const(segment, index).join("\n") << "\n"
      when 'static'
        @@out_file << push_static(segment, index).join("\n") << "\n"
      else
        @@out_file << push_code(segment, index).join("\n") << "\n"
      end
    else
      case segment
      when 'static'
        @@out_file << pop_static(segment, index).join("\n") << "\n"
      else
        @@out_file << pop_code(segment, index).join("\n") << "\n"
      end
    end
  end

  def self.increment_label
    @@label_id+=1
  end

  def self.increment_sp
    ["@SP","M=M+1"]
  end

  def self.decrement_sp
    ["@SP","M=M-1"]
  end

  def self.push_code(segment, index)
      [
        "// push #{segment} #{index}",
        "#{self.segment_address(segment, index)}",
# =>    D contains the address of the value to push
        "A=D",
        "D=M",
# =>    D contains the value to push
        "@SP",
        "A=M",
        "M=D"
      ] + increment_sp
  end

  def self.push_const(segment, index)
      [
        "// push #{segment} #{index}",
        "#{self.segment_address(segment, index)}",
        "@SP",
        "A=M",
        "M=D"
      ] + increment_sp
  end

  def self.push_static(segment, index)
      [
        "// push #{segment} #{index}",
        "@#{ARGV[0][ARGV[0].rindex('/')+1 .. ARGV[0].rindex('.')] + index}",
        "D=M",
# =>    D contains the value to push
        "@SP",
        "A=M",
        "M=D"
      ] + increment_sp
  end

  def self.pop_code(segment, index)
      [ "// pop #{segment} #{index}" ] +
      decrement_sp + [
        # Store Value to Pop in R13
        "@SP",
        "A=M",
        "D=M",
        "@R13",
        "M=D",
        # Store memory address to write to in R14
        "#{segment_address(segment,index)}",
        "@R14",
        "M=D",
        # Store Value in R5 at Memory Address in R6
        "@R13",
        "D=M",
        "@R14",
        "A=M",
        "M=D"
      ]
  end

  def self.pop_static(segment, index)
      [ "// pop #{segment} #{index}" ] +
      decrement_sp + [
        # Store Value to Pop in R13
        "@SP",
        "A=M",
        "D=M",
        "@R13",
        "M=D",
        # Store memory address to write to in R14
        "@#{ARGV[0][ARGV[0].rindex('/')+1 .. ARGV[0].rindex('.')] + index}\nD=A",
        "@R14",
        "M=D",
        # Store Value in R5 at Memory Address in R6
        "@R13",
        "D=M",
        "@R14",
        "A=M",
        "M=D"
      ]
  end

  def self.segment_address(segment, index)
    case segment
    when 'local'
      "@LCL\nD=M\n@#{index}\nD=D+A"
    when 'argument'
      "@ARG\nD=M\n@#{index}\nD=D+A"
    when 'this'
      "@THIS\nD=M\n@#{index}\nD=D+A"
    when 'that'
      "@THAT\nD=M\n@#{index}\nD=D+A"
    when 'pointer'
      "@3\nD=A\n@#{index}\nD=D+A"
    when 'temp'
      "@5\nD=A\n@#{index}\nD=D+A"
    when 'constant'
      "@#{index}\nD=A;"
    when 'static'
      "@#{ARGV[0][ARGV[0].rindex('/')+1 .. ARGV[0].rindex('.')] + index}\nD=M"
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
    label_id = increment_label

    ['// eq'] + decrement_sp + [
      'A=M',
      'D=M',
      '@R13',
      'M=D',
      # Store Y in R13
      '@SP',
      'A=M-1',
      'D=M',
      '@R13',
      'D=D-M',
      # D contains X - Y
      "@EqTrueJump#{label_id}",
      'D;JEQ',
      "@EqFalseJump#{label_id}",
      '0;JMP',
      "(EqTrueJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=-1",
        "@EqEndJump#{label_id}",
        "0;JMP",
      "(EqFalseJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=0",
        "@EqEndJump#{label_id}",
        "0;JMP",
      "(EqEndJump#{label_id})"
    ]
  end

  def self.gt
    label_id = increment_label
    ['// gt'] + decrement_sp + [
      'A=M',
      'D=M',
      '@R13',
      'M=D',
      # Store Y in R13
      '@SP',
      'A=M-1',
      'D=M',
      '@R13',
      'D=D-M',
      # D contains X - Y
      "@GtTrueJump#{label_id}",
      'D;JGT',
      "@GtFalseJump#{label_id}",
      '0;JMP',
      "(GtTrueJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=-1",
        "@GtEndJump#{label_id}",
        "0;JMP",
      "(GtFalseJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=0",
        "@GtEndJump#{label_id}",
        "0;JMP",
      "(GtEndJump#{label_id})"
    ]
  end

  def self.lt
    label_id = increment_label
    ['// lt'] + decrement_sp + [
      'A=M',
      'D=M',
      '@R13',
      'M=D',
      # Store Y in R13
      '@SP',
      'A=M-1',
      'D=M',
      '@R13',
      'D=D-M',
      # D contains X - Y
      "@GtTrueJump#{label_id}",
      'D;JLT',
      "@GtFalseJump#{label_id}",
      '0;JMP',
      "(GtTrueJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=-1",
        "@GtEndJump#{label_id}",
        "0;JMP",
      "(GtFalseJump#{label_id})",
        "@SP",
        "A=M-1",
        "M=0",
        "@GtEndJump#{label_id}",
        "0;JMP",
      "(GtEndJump#{label_id})"
    ]
  end

  def self.write_init(*args)

  end

  def self.write_label(label)
    # Label the current location in the code. Should be scoped to the function.
    # Cannot use a digit as its first letter
    @@out_file << "// Label\n"
    @@out_file << "(#{label})\n"
  end

  def self.write_goto(*args)
    # Unconditional Jump to label

  end

  def self.write_if(target_label)
    # Conditional jump to label
    # Pops the stack and compares it to 0
    # If popped val != 0, jump to label
    # else continue to next line
    @@out_file << "// If-goto #{target_label}\n"
    @@out_file << "WHATT\n"
  end

  def self.write_call(*args)

  end

  def self.write_return(*args)

  end

  def self.write_function(*args)

  end
end

parsed_files = []

if File.file?(ARGV[0])
  Parser.init(ARGV[0])
  Parser.parse
  parsed_files << {
    file: Parser.parsed_file,
    name: ARGV[0]
  }
end

parsed_files.each do |parsed_file|
  Encoder.encode(parsed_file)
end



