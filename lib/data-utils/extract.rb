
class Extract

  ##
  # Given a pattern with named captures, match a string against the pattern
  # and return an Array containing the matches.
  #
  # @note The returned Array is always the same length as the number of
  #    +matchvars+ provided.
  #
  # @param str [String]
  # @param pat [Regexp]
  # @param matchvars [Array<Symbol>]
  # @return [Array<String>]
  #
  # @example Extract the numerator+denominator from the text "Currently 5/7 people polled"
  #    fraction = Extract.list text, %r|Currently\s+(?<top>[\d.]+)\s*/\s*(?<bot>[\d.]+)|i, :top, :bot
  ##
  def self.list(str, pat, *matchvars)
    rc = []

    # get the possibilities from the pattern
    namemap = pat.named_captures

    pat.match(str) do |m|
      matchvars.map { |sym| sym.to_s }.each do |var|
        if namemap.key? var
          pos = namemap[var]
          rc << (pos.length == 1 ? (m.values_at *pos).shift : m.values_at(*pos))
        end
      end
    end

    rc
  end

  ##
  # @example Extract the string following the text "quality_"
  #     quality = Extract.string text, /quality_(?<quality>\w+)/i, :quality
  ##
  def self.string(str, pat, matchvar)
    (self.list str, pat, matchvar).first || ''
  end

  ##
  # @example Extract the number in "343 views" as an integer
  #     views = Extract.integer text, /(?<views>\d+)\s+views/i, :views
  ##
  def self.integer(str, pat, matchvar)
    ((self.list str, pat, matchvar).first || 0).to_i
  end

  ##
  # Given a pattern with named captures, match a string against the pattern
  # and return a Hash containing the matches.
  #
  # @param str [String]
  # @param pat [Regexp]
  # @param matchvars [Array<Symbol>]
  # @return [Hash<Symbol,String>]
  ##
  def self.as_hash(str, pat, *matchvars)
    rc = {}

    # get the possibilities from the pattern
    namemap = pat.named_captures

    pat.match(str) do |m|
      matchvars.each { |var| rc[var] = m.values_at(namemap[var]) if namemap.key? var }
    end

    rc
  end

end