module Oga
  module XML
    ##
    # Low level lexer that supports both XML and HTML (using an extra option).
    # To lex HTML input set the `:html` option to `true` when creating an
    # instance of the lexer:
    #
    #     lexer = Oga::XML::Lexer.new(:html => true)
    #
    # @!attribute [r] html
    #  @return [TrueClass|FalseClass]
    #
    # @!attribute [r] tokens
    #  @return [Array]
    #
    class Lexer
      attr_reader :html

      ##
      # Names of the HTML void elements that should be handled when HTML lexing
      # is enabled.
      #
      # @return [Set]
      #
      HTML_VOID_ELEMENTS = Set.new([
        'area',
        'base',
        'br',
        'col',
        'command',
        'embed',
        'hr',
        'img',
        'input',
        'keygen',
        'link',
        'meta',
        'param',
        'source',
        'track',
        'wbr'
      ])

      ##
      # @param [String] data The data to lex.
      #
      # @param [Hash] options
      #
      # @option options [Symbol] :html When set to `true` the lexer will treat
      # the input as HTML instead of SGML/XML. This makes it possible to lex
      # HTML void elements such as `<link href="">`.
      #
      def initialize(data, options = {})
        options.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?(key)
        end

        @data = data

        reset
      end

      ##
      # Resets the internal state of the lexer. Typically you don't need to
      # call this method yourself as its called by #lex after lexing a given
      # String.
      #
      def reset
        @line     = 1
        @elements = []
      end

      ##
      # Gathers all the tokens for the input and returns them as an Array.
      #
      # This method resets the internal state of the lexer after consuming the
      # input.
      #
      # @param [String] data The string to consume.
      # @return [Array]
      # @see #advance
      #
      def lex
        tokens = []

        advance do |token|
          tokens << token
        end

        reset

        return tokens
      end

      ##
      # Advances through the input and generates the corresponding tokens. Each
      # token is yielded to the supplied block.
      #
      # Each token is an Array in the following format:
      #
      #     [TYPE, VALUE]
      #
      # The type is a symbol, the value is either nil or a String.
      #
      # This method stores the supplied block in `@block` and resets it after
      # the lexer loop has finished.
      #
      # This method does *not* reset the internal state of the lexer.
      #
      #
      # @param [String] data The String to consume.
      # @return [Array]
      #
      def advance(&block)
        @block = block

        advance_native
      ensure
        @block = nil
      end

      ##
      # @return [TrueClass|FalseClass]
      #
      def html?
        return !!html
      end

      private

      ##
      # @param [Fixnum] amount The amount of lines to advance.
      #
      def advance_line(amount = 1)
        @line += amount
      end

      ##
      # Adds a token with the given type and value to the list.
      #
      # @param [Symbol] type The token type.
      # @param [String] value The token value.
      #
      def add_token(type, value = nil)
        token = [type, value, @line]

        @block.call(token)
      end

      ##
      # Returns the name of the element we're currently in.
      #
      # @return [String]
      #
      def current_element
        return @elements.last
      end

      def on_string(value)
        add_token(:T_STRING, value)
      end

      def on_start_doctype
        add_token(:T_DOCTYPE_START)
      end

      def on_doctype_type(value)
        add_token(:T_DOCTYPE_TYPE, value)
      end

      def on_doctype_name(value)
        add_token(:T_DOCTYPE_NAME, value)
      end

      def on_doctype_end
        add_token(:T_DOCTYPE_END)
      end

      def on_cdata_start
        add_token(:T_CDATA_START)
      end

      def on_cdata_end
        add_token(:T_CDATA_END)
      end

      def on_comment_start
        add_token(:T_COMMENT_START)
      end

      def on_comment_end
        add_token(:T_COMMENT_END)
      end

      def on_xml_decl_start
        add_token(:T_XML_DECL_START)
      end

      def on_xml_decl_end
        add_token(:T_XML_DECL_END)
      end

      def on_element_start(name)
        add_token(:T_ELEM_START)

        if name.include?(':')
          ns, name = name.split(':')

          add_token(:T_ELEM_NS, ns)
        end

        @elements << name if html?

        add_token(:T_ELEM_NAME, name)
      end

      def on_element_open_end
        if html? and HTML_VOID_ELEMENTS.include?(current_element)
          add_token(:T_ELEM_END)
          @elements.pop
        end
      end

      def on_element_end
        add_token(:T_ELEM_END)

        @elements.pop if html?
      end

      def on_text(value)
        unless value.empty?
          add_token(:T_TEXT, value)

          lines = value.count("\n")

          advance_line(lines) if lines > 0
        end
      end

      def on_attribute(value)
        add_token(:T_ATTR, value)
      end

      def on_newline
        @line += 1
      end
    end # Lexer
  end # XML
end # Oga