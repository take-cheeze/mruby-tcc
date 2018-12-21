class TCC
  class Preprocessor
    def initialize
      @macros = {}

      # Preprocessor
      @include_stack = []
      @include_stack_index = 0

      @ifdef_stack = []
      @ifdef_stack_index = 0
    end

    class Macro
      attr_reader :name, :type, :tokens

      def initialize(name, ty, str)
        @name = name
        @type = ty

        parse_define str
      end
    end

    def define name, str = nil
      str = '1' if str.nil?
      @macros[name] = Macro.new(name, ty, str)
    end

    def undef name
      @macros.delete name
    end

    def preprocess
      @parse_flags = {
        preprocess: true,
        linefeed: true,
        spaces: true,
        accept_strays: true,
      }

      if (@dflag & 1) != 0
        debug_builtins
        @dflag &= ~1
      end

      token_seen = :linefeed
      white = ''

      line file, 0

      loop do
        tok = next_token
        break if tok == :eof

        unless @include_stack.empty?
          line @include_stack.last, @include_stack.size
        end

        if (@dflag & 7) != 0
          debug_defines
          next if (@dflag & 4) != 0
        end

        if space? tok
          white << tok
        elsif tok == :linefeed
          white.clear
          next if token_seen == :linefeed
          @line_ref += 1
        elsif token_seen == :linefeed
          line file, 0
        elsif white.empty? && need_space(token_seen, tok)
          white << ' '
        end

        @ppfp.write white
        white.clear

        p = tok_str(tok, tokc)
        @ppfp.write p

        token_seen = check_he0xE tok, p
      end
    end

    def space? tok
      tok.is_a?(String) && /[ \t\v\f\r]/.match?(tok)
    end

    def line
      raise 'TODO'
    end

    def next_token
      raise 'TODO'
    end
  end
end
