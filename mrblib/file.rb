class TCC
  class File
    attr_reader :type, :name
    def initialize ty, name
      @type = ty
      @name = name
    end
  end

  def open name
    @current_filename = name
    @current_file = if name == '-'
                      STDIN
                    else
                      File.open name
                    end

    if (@verbose == 2 && name != '-') || @verbose == 3
      print "#{name == '-' ? "nf" : "->"} #{name}"
    end

    return @current_file
  end

  def open_bf name, str
    @current_filename = name
    @current_file = StringIO.new str
  end

  def compile ty
    is_asm = ty == :asm || ty == :asmpp

    elf_begin_file

    preprocess_start is_asm

    if @output_type == :preprocess
      preprocess
    elsif is_asm
      assemble
    else
      gen_compile
    end

    preprocess_end

    elf_end_file
  end

  def compile_string str
    open_bf "<string>"
    compile @filetype
  end
end
