class TCC
  OPTS = {
    h: [],
    :'?' => [],
    :'-help' => [],
    hh: [],
    v: %i[has_arg nosep],
    I: %i[has_arg],
    D: %i[has_arg],
    U: %i[has_arg],
    P: %i[has_arg nosep],
    L: %i[has_arg],
    B: %i[has_arg],
    l: %i[has_arg],
    bench: [],
    bt: %i[has_arg],
    b: [],
    g: %i[has_arg nosep],
    c: [],
    dumpversion: [],
    d: %[has_arg nosep],
    static: [],
    std: %i[has_arg nosep],
    shared: [],
    soname: %i[has_arg],
    o: %i[has_arg],
    :'-param' => %i[has_arg],
    pedantic: [],
    pthread: [],
    run: %i[has_arg nosep],
    rdynamic: [],
    r: [],
    s: [],
    traditional: [],
    Wl: %i[has_arg nosep],
    Wp: %i[has_arg nosep],
    W: %i[has_arg nosep],
    O: %i[has_arg nosep],
    :'mfloat-abi' => %i[has_arg],
    m: %i[has_arg nosep],
    f: %i[has_arg nosep],
    isystem: %i[has_arg],
    include: %i[has_arg],
    nostdinc: [],
    nostdlib: [],
    :'print-search-dirs' => [],
    w: [],
    pipe: [],
    E: [],
    MD: [],
    MF: %i[has_arg],
    x: %i[has_arg],
    ar: [],
    impdef: [],
  }.freeze

  def list_file fn
    Shellwords.shellsplit File.read(fn)
  end

  def parse_args argv, ind = 1
    args = argv[ind, argv.size - ind]

    tool = false
    run = false

    until args.empty?
      r = args.shift
      if r.size > 1 && r[0] == '@'
        args.unshift(**list_file(r[1, r.size - 1]))
      elsif tool && r == '-v'
        @verbose += 1
      elsif r[0] != '-' || r.size == 1
        if r[0] != '@'
          @files << TCC::File.new(@filetype, r)
        end

        if run
          # ignore
        end
      else
        opt = nil
        opt_arg = nil
        OPTS.each do |k, opt_info|
          if r.start_with? "-#{k}"
            opt = k
            if opt_info.include? :has_arg
              opt_arg = if r.size == k.size + 1 && !opt_info.include?(:nosep)
                          args.shift
                        else
                          r[k.size + 1, r.size - k.size - 1]
                        end
              error "argument to '#{r}' is missing" if opt_arg.nil?
            else
              next if r.size != k.size + 1
            end
          end
        end

        error "invalid option -- '#{r}'" if opt.nil?

        case opt.to_sym
        when :h, :'?', '-help'; return :help
        when :hh; return :help2
        when :I; @include_paths << opt_arg
        when :D; parse_option_D opt_arg
        when :U; @pp.undef opt_arg
        when :L; @library_paths << opt_arg
        when :B; @tcc_lib_path = opt_arg
        when :l; @files << TCC::File.new(%i[lib] + @filetype, opt_arg)
        when :pthread;
          parse_option_D '_REENTRANT'
          @option_pthread = true
        when :bench; @do_bench = true
        when :bt; self.num_callers = opt_arg.to_i
        when :b;
          @do_bounds_check = true
          @do_debug = true
        when :g; @do_debug = true
        when :c; self.output_type opt, :obj
        when :d
          case opt_arg
          when 'D'; @dflag = 3
          when 'M'; @dflag = 7
          when 't'; @dflag = 16
          else @dflag = opt_arg.to_i
          end
        when :static; @static_link = true
        when :std; warning "-#{opt}=#{opt_arg}: ignoring"
        when :shared; self.output_type opt, :dll
        when :soname; @soname = opt_arg
        when :o
          warning "multiple -o option, previous: #{@outfile}" if @outfile
          @outfile = opt_arg
        when :r
          @option_r = true
          self.output_type opt, :obj
        when :isystem; @sys_include_paths << opt_arg
        when :include; @cmd_include_files << opt_arg
        when :nostdinc; @nostdinc = true
        when :nostdlib; @nostdlib = true
        when :run; self.output_type opt, :memory
        when :v; @verbose = 1
        when :f; set_flag :f, opt_arg
        when :'mfloat-abi'
          case opt_arg
          when 'softfp'
            @float_abi = :softfp
            @pp.undef :__ARM_PCS_VFP
          when 'hard'; @float_abi = :hard
          else error "unsupported float abi '#{opt_arg}'"
          end
        when :m
          set_flag :m, opt_arg
        when :W
          set_flag :W, opt_arg
        when :w; @warn_none = true
        when :rdynamic; @rdynamic = true
        when :Wl
          set_linker opt_arg
        when :Wp; args.unshift opt_arg
        when :E; output_type opt, :preprocess
        when :P; @pflag = opt_arg.to_i + 1
        when :MD; @gen_deps = true
        when :MF; @deps_outfile = opt_arg
        when :dump_version;
          print "#{TCC_VERSION}\n"
          exit 0
        when :x
          hsh = {
            'c' => :c,
            'a' => :asmpp,
            'b' => :bin,
            'n' => :none
          }
          res = hsh[opt_arg]
          warning "unsupported language '#{opt_arg}'" if res.nil?
          @filetype << res
        when :O; @last_o = opt_arg.to_i
        when :'print-search-dirs'; @tool = :print_dirs
        when :impdef; @tool = :impdef
        when :ar; @tool = :ar
        when :traditional, :pedantic, :pipe, :s;
          warning "ignoring: #{opt}"
        else
          warning "unsupported option: #{opt}"
        end
      end

      @pp.define_macro :__OPTIMIZE__ if @last_o
      return @tool if @tool
      return :print_dirs if @verbose == 2
      return :v if @verbose
      :help
    end

    def output_type opt, ty
      warning "-#{opt}: overriding compiler action" if @output_type
      @output_type = ty
    end
  end
end
