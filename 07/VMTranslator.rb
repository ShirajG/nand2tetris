require 'byebug'

module Parser
  def self.parse(line)
    tokenize_line(
    split_line(
      strip_comments(line)))
  end

  def self.strip_comments(line)
    line.gsub(/\/\/.*$/,'').strip
  end

  def self.split_line(line)
    line.split(' ')
  end

  def self.tokenize_line(tokens)
    if tokens.empty?
      return nil
    elsif tokens[1] && tokens[2]
      parse_instruction(tokens)
    else
      self.send(tokens[0].to_sym)
    end
  end

  def self.parse_instruction(tokens)
    convert_instruction({
      type: tokens[0],
      address: tokens[1],
      value: tokens[2]
    })
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

  end

  def self.neg

  end

  def self.eq

  end

  def self.gt

  end

  def self.lt

  end

  def self.and

  end

  def self.or

  end

  def self.not

  end

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
      [
        "//#{parsed_instruction}",
        "@SP",
        "A=M",
        "D=M",
        "@R5",
        "M=D",
        "@#{self.segments[parsed_instruction[:address].upcase.to_sym]}",
        "D=#{parsed_instruction[:value]}",
        "D=D+M",
        "@R6",
        "M=D",
        "@R5",
        "D=M",
        "@R6",
        "M=D"
      ] + decrement_sp
    end
  end

  def self.segments(instruction)
    case instruction[:address]
    when 'local'
    when 'argument'
    when 'this'
    when 'that'
    when 'pointer'
    when 'temp'
    when 'constant'
      "@#{instruction[:value]}\nD=A;"
    when 'static'
    end
  end
end

module Encoder

end

output = []

File.open(ARGV[0],'r') do |source|
  source.each_line do |line|
    output << Parser.parse(line)
  end
end

puts output.compact.reject{|line| line==""}
out_file = ARGV[0][0..ARGV[0].rindex('.')] + 'asm'
File.open(out_file,'w') do |assembly|
  assembly.write(output.compact.reject{|line| line==''}.join("\n"))
end

