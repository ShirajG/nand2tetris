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
      parse_operation(tokens[0])
    end
  end

  def self.parse_instruction(tokens)
    {
      type: tokens[0],
      address: tokens[1],
      value: tokens[2]
    }
  end

  def self.parse_operation(token)
    operations[token.to_sym]
  end

  def self.operations
    {
      'add': 'ADD ASM CODE'
    }
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

puts output.compact.reject{|line| line==''}
# out_file = ARGV[0][0..ARGV[0].rindex('.')] + 'asm'
