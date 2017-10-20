
class JackTokenizer
  @@token_types = [
    "KEYWORD", "SYMBOL", "IDENTIFIER",
    "INT_CONST", "STRING_CONST" ]

  @@keywords = [
    "CLASS", "METHOD", "FUNCTION", "CONSTRUCTOR",
    "INT", "BOOLEAN", "CHAR", "VOID", "VAR",
    "STATIC", "FIELD", "LET", "DO", "IF", "ELSE",
    "WHILE", "RETURN", "TRUE", "FALSE", "NULL",
    "THIS" ]

  def self.get_xml(type, content)
    "<#{type}> #{content} </#{type}>"
  end

  def initialize(file)
    @tokens = ""
    @file = File.read(file)
      .gsub(/\/\/.+$/,"") # remove // comments
      .gsub(/\/\*[\S|\s]*\*\//,"") # remove /* comments */
      .strip
      .split("\n")
      .map{|l| l.strip}
      .reject{|l| l==""}
      .join(" ")
  end

  def token_type
  end

  def key_word
  end

  def symbol
  end

  def identifier
  end

  def int_val
  end

  def string_val
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














