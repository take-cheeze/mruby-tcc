class TCC
  def initialize
    @verbose = 0
    @nostdinc = false
    @nostdlib = false
    @nocommon = true
    @static_link = false
    @rdynamic = false
    @symbolic = false
    @filetype = [] # %i[none @c @asm]

    @tcc_lib_path = :string
    @soname = :string
    @rpath = :string
    @enable_new_dtags = false

    @output_type = %i[memory exe dll obj preprocess]
    @output_format = %i[elf binary coff]

    @char_is_unsigned = false
    @leading_underscore = true
    @ms_extensions = true

    # warnings
    @warn_write_strings = false
    @warn_unsupported = false
    @warn_error = false
    @warn_none = false
    @warn_implicit_function_declaration = true
    @warn_gcc_compat = false

    @do_debug = false
    @do_bounds_check = false

    @float_abi = %i[softfp hard]
    @run_test = false

    @text_addr = :addr
    @has_text_addr = false

    @section_align = :int

    @init_symbol = :string
    @fini_symbol = :string

    @seg_size = 32
    @nosse = false

    @loaded_dlls = []
    @include_paths = []
    @sys_include_paths = []
    @library_paths = []
    @crt_paths = []
    @cmd_include_files = []

    @error_func = :proc
    @error_set_jmp_enabled = false
    @errors = []

    @pp_file = nil
    @pflag = %i[gcc none std p10]
    @dflag = ''

    @target_deps = []

    @cached_includes = {}

    @pack_stack = []
    @pack_stack_index = 0
    @pragma_libs = []

    @inline_funcs = []

    @sections = []

    @got = nil
    @plt = nil

    @dynsymtab_section = nil
    @dynsym = nil
    @symtab = nil
    @sym_attrs = []

    @runtime_main = ''
    @runtime_mem = []

    @files = []
    @libraries = []
    @outfile = ''
    @option_r = false
    @do_bench = false
    @gen_deps = false
    @deps_out_file = ''
    @option_pthread = false

    @argv = []

    @pp = TCC::Preprocessor.new
    %i[LINE FILE DATE TIME COUNTER].each do |v|
      @pp.define_macro :"__#{v}__", :obj, %w[1]
    end
    @pp.define_macro :__TINYC__, :obj, %w[101]
    @pp.define_macro :__STDC__, :obj, %w[1]
    @pp.define_macro :__STDC_VERSION__, :obj, %w[199901L]
    @pp.define_macro :__STDC_HOSTED__, :obj, %w[1]
  end

  def target=(arch, os)
    @arch = arch.to_sym
    case @arch
    when :i386
      @pp.define_macro :__i386__, :obj, %w[1]
      @pp.define_macro :__i386, :obj, %w[1]
      @pp.define_macro :i386, :obj, %w[1]
    when :x86_64
      @pp.define_macro :__x86_64__, :obj, %w[1]
    when :arm
      %i[__ARM_ARCH_4__ __arm_elf__ __arm_elf__ __arm_elf arm_elf __arm__ __arm arm __APCS_32__ __ARMEL__].each do |v|
        @pp.define_macro v, :obj, %w[1]
      end
      @pp.define_macro :__ARM_EABI__, :obj, %w[1] if @arm_eabi
      @pp.define_macro :__ARM_PCS_VFP, :obj, %w[1] if @arm_hard_float
    when :arm64
      @pp.define_macro :__aarch64__, :obj, %w[1]
    when :c67
      @pp.define_macro :__C67__, :obj, %w[1]
    end

    @os = os.to_sym
    case @os
    when :windows
      @pp.define_macro :_WIN32, :obj, %w[1]
      @pp.define_macro :_WIN64, :obj, %w[1] if @arch == :x86_64
    when :linux
      @pp.define_macro :__linux__, :obj, %w[1]
      @pp.define_macro :__linux, :obj, %w[1]
    when :freebsd
      @pp.define_macro :__FreeBSD__, :obj, %w[__FreeBSD__]
      @pp.define_macro :__NO_TLS, :obj, %w[1]
    when :freebsd_kernel
      @pp.define_macro :__FreeBSD_kernel__, :obj, %w[1]
    when :netbsd
      @pp.define_macro :__NetBSD__, :obj, %w[__NetBSD__]
    when :openbsd
      @pp.define_macro :__OpenBSD__, :obj, %w[__OpenBSD__]
    end

    if @os != :windows
      @pp.define_macro :__unix__, :obj, %w[1]
      @pp.define_macro :__unix, :obj, %w[1]
      @pp.define_macro :unix, :obj, %w[1]
    end

    if @ptr_size == 4
      @pp.define_macro :__SIZE_TYPE__, :obj, %w[unsigned int]
      @pp.define_macro :__PTRDIFF_TYPE__, :obj, %w[int]
      @pp.define_macro :__ILP32__, :obj, %w[1]
    elsif @long_size == 4
      @pp.define_macro :__SIZE_TYPE__, :obj, %w[unsigned long long]
      @pp.define_macro :__PTRDIFF_TYPE__, :obj, %w[long long]
      @pp.define_macro :__LLP64__, :obj, %w[1]
    end

    if @os == :windows
      @pp.define_macro :__WCHAR_TYPE__, :obj, %w[unsigned short]
      @pp.define_macro :__WINT_TYPE__, :obj, %w[unsigned short]
    else
      @pp.define_macro :__WCHAR_TYPE__, :obj, %w[int]
      if %i[freebsd freebsd_kernel netbsd openbsd].include? @os
        @pp.define_macro :__WINT_TYPE__, :obj, %w[int]
        if @os == :freebsd
          @pp.define_macro :__GNUC__, :obj, %w[2]
          @pp.define_macro :__GNUC_MINOR__, :obj, %w[7]
          @pp.define_macro :__bultin_alloca, :obj, %w[alloca]
        end
      else
        @pp.define_macro :__WINT_TYPE__, :obj, %w[unsigned int]
      end
    end
  end

  def warning msg
    print msg + "\n"
  end

  def help
    p "TODO"
  end

  def help2
    p "TODO"
  end

  def set_output_type ty
    @output_type = ty

    @output_format = :elf if output_type == :obj
    @pp.define :__CHAR_UNSIGNED__
    @sys_include_paths << SYS_INCLUDE_PATHS unless @nostdinc

    if @do_bounds_check
      elf_bounds_new
      @pp.define :__BOUNDS_CHECKING_ON
    end

    elf_stab_new if @do_debug

    @library_paths << LIBPATHS

    add_systemdir if @os == :windows && @output_type != :obj

    if (@output_type == :exe || @output_type == :dll) && !@nostdlib
      add_crt 'crt1.o' if @output_type != :dll
      add_crt 'crti.o'
    end
  end

  # return exit code
  def self.main argv
    opt = parse_args

    case opt
    when :help
      help
      return 1
    when :help2
      help2
      return 1
    when :m32, :m64
      tool_cross argv, opt
    when :verbose
      print version
    when :ar
      tool_ar argv
    when :v
      return 0
    when :print_dirs
      set_environment
      set_output_type :memory
      print_search_dirs
      return 0
    end

    error "no input files" if @files.empty?

    if @output_type == :preprocess
      if @outfile && @outfile != '-'
        @ppfp = File.open @outfile, 'w'
      end
    elsif @output_type == :obj && !@option_r
      error "cannot specify libraries with -c" unless @libraries.empty?
      # error "cannot specify output file with -c many files" if @outfile
    elsif @option_pthread
      set_options '-lpthread'
    end

    @start_time = Time.now if @do_bench

    set_environment

    @output_type = :exe if @output_type.nil?

    @files.each do |f|
      @filetype = f.type
      if f.type == :lib
        add_library f.name
      else
        print "-> #{f.name}\n" if @verbose == 1
        add_file f.name
      end
    end

    if @output_type == :memory
      run argv
    else
      @outfile = default_outfile @files.first.name if @outfile.nil?

      output_file @outfile

      gen_makedeps @outfile, @deps_outfile if @gen_deps
    end

    print_stats Time.now - start_time if @do_bench

    0
  end
end
