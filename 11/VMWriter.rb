class VMWriter
  # Converts the syntax tree into actual VM code
  def initialize(file)
    @outfile = file
    @classname
  end

  def write_push(segment, index)
    @outfile << "push #{segment} #{index}\n"
  end

  def write_pop(segment, index)
    @outfile << "pop #{segment} #{index}\n"
  end

  def write_arithmetic(command)
    @outfile << "#{command}\n"
  end

  def write_label(label)

  end

  def write_goto(label)

  end

  def write_if(label)

  end

  def write_call(name, arg_count)
    @outfile << "call #{name} #{arg_count}\n"
  end

  def write_function(name, locals_count)
    @outfile << "function #{@class}.#{name} #{locals_count}\n"
  end

  def write_return
    @outfile << "return\n"
  end

  def set_class(token)
    @class = token[:value]
  end

  def close
    @outfile.close
  end
end
