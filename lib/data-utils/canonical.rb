##
## data-utils/canonical.rb
##

require 'unidecoder'

module Canonical
  UNIDECODE = {
      '’' => "'",
      'å' => 'a',  'â' => 'a',
      'é' => 'e',  'è' => 'e',
      'ö' => 'oe', 'ô' => 'o',
      'ñ' => 'n',
      'ü' => 'ue',
  }.freeze

  AS_ASCII = {
      0x00C6 => 'AE',		# CAPITAL AE DIPHTHONG
      0x00E6 => 'ae',		# SMALL ae DIPHTHONG
      0x00ED => 'i',		# LATIN SMALL LETTER I WITH ACUTE
      0x00F6 => 'oe',		# LATIN SMALL LETTER O WITH UMLAUT
      0x00FC => 'ue',		# LATIN SMALL LETTER U WITH UMLAUT
      0x02BC => "'",
      0x2002 => ' ',		# EN SPACE
      0x2003 => ' ',		# EM SPACE
      0x2008 => ' ',		# PUNCTUATION SPACE
      0x2009 => ' ',		# THIN SPACE
      0x2013 => '--',   # NDASH
      0x2014 => '--',   # MDASH
      0x2015 => '--',   # HORIZONTAL BAR
      0x2018 => "'",    # LEFT SINGLE QUOTE
      0x2019 => "'",    # RIGHT SINGLE QUOTE
      0x201B => "'",    # REVERSED SINGLE QUOTE
      0x201C => '"',    # LEFT DOUBLE QUOTE
      0x201D => '"',    # RIGHT DOUBLE QUOTE
      0x201F => '"',    # REVERSED DOUBLE QUOTE
      0x2026 => '...',  # HORIZONTAL ELLIPSIS
      0x2032 => "'",		# PRIME (minutes, feet)
      0x2033 => '"',		# DOUBLE PRIME (seconds, inches)
  }.freeze
end

class String
  ##
  # Convert a +String+ with international characters to canonical chars.
  #
  # @note We provide +as_ascii+ because the Unicoder module already provides
  #    +to_ascii+ as a String mixin.  So what are we providing beyond Unicoder?
  #
  #        'Björk'.to_ascii => 'Bj?rk'
  #        'Björk'.as_ascii => 'Bjoerk'
  #
  # @note as_ascii MAY ADD characters to the resulting string!  For example,
  #    +'Björk'.as_ascii+ becomes +'Bjoerk'+.
  #
  # @note Character case is **preserved**.
  #
  # @return [String]
  #
  # @example Convert text string to ASCII
  #    ascii = 'Michael Bublé & Nelly Furtado'.to_ascii
  ##
  def as_ascii()
    return self if self.empty?
    begin
      rc = Unidecoder.decode(self, Canonical::UNIDECODE)
    rescue
    end
      if rc.nil?
        # Unidecoder.decode() failed and threw an exception so now it's
        # OUR job to transcode this garbage!
        rc = ''
        self.unpack('U*').each do |cp|
          if cp < 127
            rc += [cp].pack('U')
          elsif Canonical::AS_ASCII.key? cp
            rc += Canonical::AS_ASCII[cp]
          else
            raise "invalid codepoint: '#{cp}'"
          end
        end
      end
      rc
  end

  ##
  # Reduce a +String+ to "safe", consistent characters.
  #
  # @note +as_ascii+ may ADD characters to the resulting string!
  #
  # @note To preserve word boundaries in the result, each "unsafe" character is
  # converted to a single space.  Then all adjacent whitespace is collapsed.
  #
  # Given a +String+:
  #
  #    1. Use as_ascii to convert international characters.
  #    2. Convert all characters which are NOT +[a-zA-Z0-9]+ to a space.
  #    3. Collapse all adjacent space chars to a single space.
  #    4. Strip leading/trailing whitespace.
  #
  # @return [String]
  #
  # @example Reduce string
  #    newstring = 'Rise (feat. Michelle Shellers)'.reduce
  ##
  def reduce()
    return self if self.empty?
    newstr = self.as_ascii
    newstr.gsub! /[^a-zA-Z0-9_]/, ' '
    newstr.gsub! /\s+/, ' '
    newstr.strip!
    newstr
  end

  ##
  # Reduce a +String+ to "safe", consistent characters, including
  # transcoding whitespaces to underscores.
  #
  # @note Character case becomes lowercase **always**.
  #
  # @return [String]
  #
  # @example Reduce a filename
  #    filename = 'Rise (feat. "Michelle Shellers")'.reduce_ws
  ##
  def reduce_ws()
    return self if self.empty?
    newstr = self.as_ascii
    newstr.gsub! /[^a-zA-Z0-9_]/, '_'
    newstr.gsub! /_+/, '_'
    newstr.sub! /^_+/, ''
    newstr.sub! /_+$/, ''
    newstr
  end

  ##
  # Return the canonical form of this String.
  #
  # Canonical form:
  # 1. self.lowercase
  # 2. self.reduce
  ##
  def canonical()
    return self if self.empty?
    self.reduce.downcase
  end

end

class Symbol
  ##
  # Reduce a +Symbol+ to "safe", consistent characters, including transcoding
  # whitespaces to underscores.
  #
  # @note Unlike String.reduce_ws, Symbol.reduce **always** converts the
  #    result to lowercase!
  #
  # @return [Symbol]
  #
  # @example Reduce symbol
  #    newsymbol = :'@foo'.reduce
  ##
  def reduce
    self.to_s.downcase.reduce_ws.to_sym
  end

end
