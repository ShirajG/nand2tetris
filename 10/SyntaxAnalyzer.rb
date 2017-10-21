class JackTokenizer
  @@symbols = %w({ } ( ) [ ] . , ; + - * / & | < > = ~)
  @@token_types = {
    keyword: "KEYWORD", symbol: "SYMBOL", identifier: "IDENTIFIER",
    int: "INT_CONST", str: "STRING_CONST" }

  @@keywords = {
    class: "CLASS", method: "METHOD", function: "FUNCTION",
    constructor: "CONSTRUCTOR", int: "INT", boolean: "BOOLEAN",
    char: "CHAR", void: "VOID", var: "VAR",
    static: "STATIC", field: "FIELD", let: "LET",
    do: "DO", if: "IF", else: "ELSE", while: "WHILE",
    return: "RETURN", true: "TRUE", false: "FALSE", null: "NULL",
    this: "THIS" }

  def self.get_xml(type, content)
    "<#{type}> #{content} </#{type}>"
  end

  def initialize(file)
    @tokens = []
    @file = File.read(file)
      .gsub(/\/\/.+$/,"") # remove // comments
      .gsub(/\/\*[\S|\s]*\*\//,"") # remove /* comments */
      .strip

    within_quote = false
    current_string = ""
    @file.each_char do |char|
      if within_quote
        current_string += char;
      else
        if ["\r", "\n", " "].include? char
          tokenize!(current_string) unless current_string == ""
          current_string = ""
        else
          current_string += char
        end
      end

      if char == '"'
        within_quote = !within_quote
      end
    end
    puts @tokens
  end

  def tokenize!(token_str)
    token = nil;
    if @@symbols.include?(token_str)
      token = {
        type: @@token_types[:symbol],
        value: token_str
      }
    elsif %w(class constructor function method field static var int char boolean void true false null this let do if else while return).include?(token_str)
      token = {
        type: @@token_types[:keyword],
        value: token_str
      }
    elsif /\".+\"$/.match? token_str
      token = {
        type: @@token_types[:str],
        value: token_str
      }
    else
      if contains_symbols(token_str)
        # Split on the first found instance of a known symbol.
        # Process the string up to the first known symbol,
        # call tokenize on the rest
        if (token_str[-1] == ';')

          tokenize!(token_str[0..-2])
          tokenize!(token_str[-1])
        end
        # puts token_str
      else
        if is_number?(token_str)
          token = {
            type: @@token_types[:int],
            value: token_str
          }
        else
          token = {
            type: @@token_types[:identifier],
            value: token_str
          }
        end
      end
    end

    @tokens << token unless token.nil?
  end

  def contains_symbols(token_str)
    !(token_str.split('') & @@symbols).empty?
  end

  def is_number?(obj)
    obj.to_f.to_s == obj.to_s || obj.to_i.to_s == obj.to_s
  end
end

class CompilationEngine
  def initialize(file)
  end

  def compile_class

  end

  def compile_class_var_dec

  end

  def compile_subroutine

  end

  def compile_parameter_list

  end

  def compile_var_dec
  end

  def compile_statements

  end

  def compile_do

  end

  def compile_let

  end

  def compile_while

  end

  def compile_return

  end

  def compile_if

  end

  def compile_expression

  end

  def compile_term

  end

  def compile_expression_list

  end
end

class JackAnalyzer
  def initialize
    # Check if ARGV[0] is file or dir
    # For each file, first pass it to a new
    # tokenizer, then pass that tokenizer to
    # a new Compilation Engine instance that
    # will write the final output xml.
    if File.file?(ARGV[0])
      CompilationEngine.new(JackTokenizer.new(ARGV[0]))
    end

    if File.directory?(ARGV[0])
      files = Dir[ARGV[0] + "/*.jack"]
      files.each do |file|
        CompilationEngine.new(JackTokenizer.new(file))
      end
    end
  end
end

JackAnalyzer.new()














