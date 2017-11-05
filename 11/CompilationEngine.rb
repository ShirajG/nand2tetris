class CompilationEngine
  # Converts the token list into a syntax tree
  @@ops = %w(+ - * / & | < > =)
  @@unaryOps = %w(- ~)

  attr_reader :tokens, :analyzed_file

  def initialize(tokenizer)
    @while_count = 0
    @if_count = 0
    @tokens = tokenizer.tokens
    @filename = tokenizer.filename
    @token_idx = 0
    @symbol_table = SymbolTable.new()
    @code_writer = VMWriter.new(File.open(@filename + '.vmx', 'w'))
    # @xml = File.open(@filename + '.xml', 'w')
    @analyzed_file = compile_class
  end

  def node
    { type: nil, value:[] }
  end

  def current_token
    @tokens[@token_idx]
  end

  def next_token
    @tokens[@token_idx + 1]
  end

  def advance(node)
    if current_token[:type] == 'identifier'
      lookup = lookup(current_token)
      if lookup
        current_token[:type] = lookup[:type]
        current_token[:kind] = lookup[:kind]
        current_token[:index] = lookup[:num]
      elsif current_token[:value][0].upcase == current_token[:value][0]
        current_token[:type] = 'class'
      else
        current_token[:type] = 'subroutine'
      end
    end
    node[:value] << current_token
    @token_idx += 1
  end

  def lookup(token)
    @symbol_table.lookup(token)
  end

  def compile_class
    # 'class' className '{' classVarDec* subroutineDec* '}'
    class_node = node
    class_node[:type] = 'class'

    advance class_node
    @symbol_table.current_class = current_token[:value]
    @code_writer.set_class(current_token)
    advance class_node
    advance class_node

    while ["static", "field"].include? current_token[:value]
      class_node[:value] << compile_class_var_dec
    end

    while ["constructor", "function","method"].include? current_token[:value]
      class_node[:value] << compile_subroutine
    end

    class_node[:value] << current_token
    @code_writer.close
    return class_node
  end

  def compile_class_var_dec
    # ('static' | 'field') type varName (',' varName)* ';'
    class_var_dec_node = node
    class_var_dec_node[:type] = 'classVarDec'

    class_var = {}

    class_var[:kind] = current_token[:value]
    advance class_var_dec_node

    class_var[:type] = current_token[:value]
    advance class_var_dec_node

    class_var[:name] = current_token[:value]
    @symbol_table.define(class_var)
    current_token[:type] = class_var[:type]
    current_token[:kind] = class_var[:kind]
    current_token[:declaration?] = true
    current_token[:index] = @symbol_table.index_of(current_token)
    advance class_var_dec_node

    while current_token[:value] == ','
      advance class_var_dec_node
      class_var[:name] = current_token[:value]
      @symbol_table.define(class_var)
      current_token[:type] = class_var[:type]
      current_token[:kind] = class_var[:kind]
      current_token[:declaration?] = true
      current_token[:index] = @symbol_table.index_of(current_token)
      advance class_var_dec_node
    end

    advance class_var_dec_node
    return class_var_dec_node
  end

  def compile_subroutine
    # ('constructor'|'function'|'method') ('void'|type) subroutineName '(' parameterList ')' subroutineBody
    @while_count = 0
    @if_count = 0

    subroutine_node = node
    subroutine_node[:type] = 'subroutineDec'

    subroutine_type = current_token[:value]
    advance subroutine_node
    advance subroutine_node
    subroutine_name = current_token[:value]
    @symbol_table.start_subroutine(subroutine_name, subroutine_type)
    advance subroutine_node
    advance subroutine_node

    subroutine_node[:value] << compile_parameter_list

    advance subroutine_node
    subroutine_node[:value] << compile_subroutine_body

    return subroutine_node
  end

  def compile_subroutine_body
    # '{' varDec* statements '}'
    subroutine_body_node = node
    subroutine_body_node[:type] = "subroutineBody"

    advance subroutine_body_node

    var_count = 0
    while %w(var).include? current_token[:value]
      subroutine_body_node[:value] << compile_var_dec
      subroutine_body_node[:value].last[:value].each do |x|
        if x[:declaration?]
          var_count += 1
        end
      end
    end

    @code_writer.write_function(
      @symbol_table.current_subroutine,
      var_count)

    if @symbol_table.current_subroutine_type == 'constructor'
      field_count = 0
      # static_count = 0
      @symbol_table.class_table.each do |k,v|
        if v[:kind] == 'field'
          field_count += 1
        # elsif v[:kind] == 'static'
          # static_count += 1
        end
      end
      @code_writer.write_push('constant', field_count)
      @code_writer.write_call('Memory.alloc',1)
      # set 'this' pointer to the address of new object
      @code_writer.write_pop('pointer', 0)
    elsif @symbol_table.current_subroutine_type == 'method'
      # Push the implicit first arg
      @code_writer.write_push('argument',0)
      # switch current context to 'this'
      @code_writer.write_pop('pointer',0)
    elsif @symbol_table.current_subroutine_type == 'function'

    end

    subroutine_body_node[:value] << compile_statements

    advance subroutine_body_node
    return subroutine_body_node
  end

  def compile_parameter_list
    # ((type varName)(',' type varName)*)?
    parameter_list_node = node
    parameter_list_node[:type] = 'parameterList'

    if %w(identifier keyword).include? current_token[:type]
      argument = {}
      argument[:kind] = 'argument'
      argument[:type] = current_token[:value]
      advance parameter_list_node
      argument[:name] = current_token[:value]
      current_token[:kind] = 'argument'
      current_token[:type] = argument[:type]
      current_token[:declaration?] = true
      @symbol_table.define(argument)
      current_token[:index] = @symbol_table.index_of(current_token)

      advance parameter_list_node


      while current_token[:value] == ","
        advance parameter_list_node
        argument[:type] = current_token[:value]
        advance parameter_list_node
        argument[:name] = current_token[:value]
        @symbol_table.define(argument)
        advance parameter_list_node
      end
    end
    return parameter_list_node
  end

  def compile_var_dec
    # 'var' type varName (',' varName)* ';'
    var_dec_node = node
    var_dec_node[:type] = 'varDec'

    variable = {}

    variable[:kind] = 'local'
    advance var_dec_node
    variable[:type] = current_token[:value]
    advance var_dec_node
    variable[:name] = current_token[:value]
    current_token[:declaration?] = true
    @symbol_table.define(variable)
    advance var_dec_node

    while current_token[:value] == ','
      advance var_dec_node
      variable[:name] = current_token[:value]
      current_token[:declaration?] = true
      @symbol_table.define(variable)
      advance var_dec_node
    end

    advance var_dec_node
    return var_dec_node
  end

  def compile_statements
    # statement*
    statements_node = node
    statements_node[:type] = 'statements'
    while %w(while let if do return).include? current_token[:value]
      case current_token[:value]
      when 'while'
        statements_node[:value] << compile_while
      when 'let'
        statements_node[:value] << compile_let
      when 'if'
        statements_node[:value] << compile_if
      when 'do'
        statements_node[:value] << compile_do
      when 'return'
        statements_node[:value] << compile_return
      end
    end

    return statements_node
  end

  def compile_let
    # 'let' varName ('[' expression ']')? '=' expression ';'
    is_array = false
    let_node = node
    let_node[:type] = 'letStatement'
    2.times do
      advance let_node
    end

    destination = let_node[:value].last

    if current_token[:value] == '['
      is_array = true
      advance let_node
      let_node[:value] << compile_expression
      @code_writer.write_push(destination[:kind], destination[:index])
      @code_writer.write_arithmetic('add')
      advance let_node
    end

    advance let_node

    let_node[:value] << compile_expression
    advance let_node

    case destination[:kind]
    when 'field'
      @code_writer.write_pop('this', destination[:index])
    else
      if is_array
        @code_writer.write_pop('temp', 0)
        @code_writer.write_pop('pointer', 1)
        @code_writer.write_push('temp', 0)
        @code_writer.write_pop('that', 0)
      else
        puts destination
        @code_writer.write_pop(
          destination[:kind],
          destination[:index])
      end
    end

    return let_node
  end

  def compile_if
    # 'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
    if_count = @if_count
    @if_count += 1

    if_node = node
    if_node[:type] = 'ifStatement'

    2.times do
      advance if_node
    end

    if_node[:value] << compile_expression
    @code_writer.write_if("IF_TRUE#{if_count}")
    @code_writer.write_goto("IF_FALSE#{if_count}")

    2.times do
      advance if_node
    end

    @code_writer.write_label("IF_TRUE#{if_count}")
    if_node[:value] << compile_statements
    advance if_node

    if current_token[:value] == 'else'
      @code_writer.write_goto("IF_END#{if_count}")
    end

    @code_writer.write_label("IF_FALSE#{if_count}")
    if current_token[:value] == 'else'
      2.times do
        advance if_node
      end

      if_node[:value] << compile_statements
      advance if_node
      @code_writer.write_label("IF_END#{if_count}")
    end

    return if_node
  end

  def compile_while
    # 'while' '(' expression ')' '{' statements '}'
    # Store while count in local scope, since statement
    # may contain more while loops, and we need to tag
    # those uniquely as well
    while_count = @while_count
    @while_count = @while_count + 1

    while_node = node
    while_node[:type] = 'whileStatement'

    2.times do
      advance while_node
    end

    @code_writer.write_label("WHILE_EXP#{while_count}")
    while_node[:value] << compile_expression
    @code_writer.write_arithmetic('not')

    2.times do
      advance while_node
    end

    @code_writer.write_if("WHILE_END#{while_count}")
    while_node[:value] << compile_statements
    @code_writer.write_goto("WHILE_EXP#{while_count}")
    @code_writer.write_label("WHILE_END#{while_count}")

    advance while_node
    return while_node
  end

  def compile_do
    # 'do' subroutineCall ';'
    do_node = node
    do_node[:type] = 'doStatement'
    advance do_node

    if next_token[:value] == '.'
    #(className | varName) '.' subroutineName '(' expressionList ')'
      if lookup(current_token)
        type = lookup(current_token)[:type]
        kind = lookup(current_token)[:kind]
      end
      name = current_token[:value]
      advance do_node
      name += current_token[:value]
      advance do_node
      name += current_token[:value]
      advance do_node
      advance do_node

      do_node[:value] << compile_expression_list
      exp_count = 0
      do_node[:value].last[:value].each do |exp|
        if exp[:type] == 'expression'
          exp_count += 1
        end
      end

      # We need to handle calls to instance methods
      # the same as calls to Class methods
      # Gotta look up the Class the instance belongs to
      # and pass the current instance as first arg
      if type
        if kind == 'local'
          @code_writer.write_push('local', 0)
        else
          @code_writer.write_push('this', 0)
        end
        name = name.gsub(/.+\./, "#{type}.")
        @code_writer.write_call(name, exp_count + 1)
      else
        @code_writer.write_call(name, exp_count)
      end
      advance do_node
    else
    # subroutineName '(' expressionList ')'
      name = current_token[:value]
      advance do_node
      advance do_node

      do_node[:value] << compile_expression_list

      exp_count = 0
      do_node[:value].last[:value].each do |exp|
        if exp[:type] == 'expression'
          exp_count += 1
        end
      end

      name = [@symbol_table.current_class,name].join('.')
      @code_writer.write_push('pointer',0)
      @code_writer.write_call(name, exp_count + 1)
      advance do_node
    end

    advance do_node
    # Do statement, pop return val to garbage
    @code_writer.write_pop('temp', 0)

    return do_node
  end

  def compile_return
    # 'return' expression? ';'
    return_node = node
    return_node[:type] = 'returnStatement'

    advance return_node

    if(current_token[:value] != ';')
      return_node[:value] << compile_expression
    else
      @code_writer.write_push('constant', 0)
    end

    advance return_node
    @code_writer.write_return
    return return_node
  end

  def compile_expression
    # term (op term)*
    expression_node = node
    expression_node[:type] = 'expression'

    expression_node[:value] << compile_term

    while @@ops.include? current_token[:value]
      operation = current_token[:value]

      advance expression_node
      expression_node[:value] << compile_term

      case operation
      when '+'
        @code_writer.write_arithmetic('add')
      when '-'
        @code_writer.write_arithmetic('sub')
      when '*'
        @code_writer.write_call('Math.multiply', 2)
      when '/'
        @code_writer.write_call('Math.divide', 2)
      when '<'
        @code_writer.write_arithmetic('lt')
      when '>'
        @code_writer.write_arithmetic('gt')
      when '='
        @code_writer.write_arithmetic('eq')
      when '&'
        @code_writer.write_arithmetic('and')
      end
    end

    return expression_node
  end

  def compile_term
    # integerConstant | stringConstant | keywordConstant | '(' expression ')' | unaryOp term | varName | varName '[' expression  ']' | subroutineCall
    term_node = node
    term_node[:type] = 'term'
    if current_token[:type] == 'integerConstant'
      @code_writer.write_push('constant', current_token[:value])
      advance term_node
    elsif current_token[:type] == 'stringConstant'
      string_constant = current_token[:value]
      @code_writer.write_push('constant', string_constant.length)
      @code_writer.write_call('String.new', 1)
      string_constant.each_byte do |c|
        @code_writer.write_push('constant', c)
        @code_writer.write_call('String.appendChar',2)
      end
      advance term_node
    elsif current_token[:type] == 'keyword'
      case current_token[:value]
      when 'true'
        @code_writer.write_push('constant', 0)
        @code_writer.write_arithmetic('not')
      when 'false'
        @code_writer.write_push('constant', 0)
      when 'this'
        @code_writer.write_push('pointer', 0)
      end
      advance term_node
    elsif current_token[:value] == '('
      advance term_node
      term_node[:value] << compile_expression
      advance term_node
    elsif @@unaryOps.include? current_token[:value]
      unary = current_token[:value]
      advance term_node
      term_node[:value] << compile_term
      case unary
      when '-'
        @code_writer.write_arithmetic('neg')
      when '~'
        @code_writer.write_arithmetic('not')
      end
    elsif ['.', '('].include? next_token[:value]
    # Handle subroutine calls
      if next_token[:value] == '.'
      #(className | varName) '.' subroutineName '(' expressionList ')'
        name = current_token[:value]
        advance term_node
        name += current_token[:value]
        advance term_node
        name += current_token[:value]
        advance term_node
        advance term_node

        term_node[:value] << compile_expression_list
        exp_count = 0
        term_node[:value].last[:value].each do |exp|
          if exp[:type] == 'expression'
            exp_count += 1
          end
        end

        @code_writer.write_call(name, exp_count)
        advance term_node
      else
      # subroutineName '(' expressionList ')'
        name = current_token[:value]
        advance term_node
        advance term_node
        term_node[:value] << compile_expression_list
        exp_count = 0
        term_node[:value].last[:value].each do |exp|
          if exp[:type] == 'expression'
            exp_count += 1
          end
        end
        @code_writer.write_call(name, exp_count)
        advance term_node
      end
    elsif next_token[:value] == '['
      array_info = lookup current_token
      2.times do
        advance term_node
      end
      term_node[:value] << compile_expression
      @code_writer.write_push(array_info[:kind],array_info[:num])
      @code_writer.write_arithmetic('add')
      @code_writer.write_pop('pointer', 1)
      @code_writer.write_push('that', 0)
      advance term_node
    else
      # handle identifiers
      token_info = lookup current_token
      if token_info && token_info[:kind] == 'field'
        @code_writer.write_push('this', token_info[:num])
      else
        @code_writer.write_push(
          lookup(current_token)[:kind],
          lookup(current_token)[:num]
        )
      end
      advance term_node
    end

    return term_node
  end

  def compile_expression_list
    # (expression (',' expression)*)?
    expression_list_node = node
    expression_list_node[:type] = 'expressionList'

    if is_term?(current_token)
      expression_list_node[:value] << compile_expression
      while current_token[:value] == ','
        advance expression_list_node

        expression_list_node[:value] << compile_expression
      end
    end

    return expression_list_node
  end

  def is_term?(token)
    (%w(identifier integerConstant stringConstant keyword).include? token[:type]) || (token[:value] == '(') || (@@unaryOps.include? token[:value])
  end

  def print_node(node, nesting=2)
    child_indent = ""
    root_indent = ""

    nesting.times do
      child_indent += ' '
    end

    (nesting - 2).times do
      root_indent += ' '
    end

    @xml << "#{root_indent}<#{node[:type]}>\n"
    # puts "#{root_indent}<#{node[:type]}>"

    node[:value].each do |val|
      if val[:value].is_a? String
        @xml << "#{child_indent}<#{val[:type]}> #{val[:value]} </#{val[:type]}>\n"
        # puts "#{child_indent}<#{val[:type]} #{val[:kind]} #{val[:index]} #{val[:declaration?] ? 'declaration' : '';}> #{val[:value]} </#{val[:type]}>"
      else
        print_node(val, nesting + 2)
      end
    end

    @xml <<  "#{root_indent}</#{node[:type]}>\n"
    # puts "#{root_indent}</#{node[:type]}>"
  end
end
