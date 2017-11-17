class SymbolTable
  # Keeps track of variables and their scoping
  attr_reader :current_table, :class_table, :current_subroutine, :current_subroutine_type
  attr_accessor :current_class

  def initialize
    @class_table = {}
    @subroutine_table = {}
    @current_subroutine = nil
    @current_subroutine_type = nil
    @current_table = @class_table
    @static_index = 0
    @field_index = 0
    @argument_index = 0
    @local_index = 0
  end

  def start_subroutine(name, type)
    @subroutine_table = {}
    @argument_index = 0
    @local_index = 0
    @current_table = @subroutine_table
    @current_subroutine = name
    @current_subroutine_type = type
  end

  def define(variable)
    case variable[:kind]
    when 'field'
      @class_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @field_index
      }
      @field_index += 1
    when 'static'
      @class_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @static_index
      }
      @static_index += 1
    when 'argument'
      @subroutine_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @argument_index
      }
      @argument_index += 1
    when 'local'
      @subroutine_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @local_index
      }
      @local_index += 1
    end
  end

  def var_count(token)
  end

  def kind_of(token)
    lookup(token)[:kind]
  end

  def type_of(token)
    lookup(token)[:type]
  end

  def index_of(token)
    lookup(token)[:num]
  end

  def lookup token
    @current_table[token[:value]] || @class_table[token[:value]]
  end
end
