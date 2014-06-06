require 'psych'

module Brewed

  class AppError < StandardError
    def fatal?()        true    end
    def restartable?()  false   end
    def retryable?()    false   end

    ##
    # Constructs and returns a new AppError exception object.
    #
    # @param msg [Array<Object>]
    #    list of String and other Object
    #
    # @return [AppError]
    #
    # @example Pass DataMapper model when it failed to save
    #    raise TVError.new("save show failed:", self) unless self.saved?
    ##
    def initialize(*msg)
      text = ''
      msg.each do |m|
        case m
        when String
          text += m
        else
          # an object to be dumped as YAML into the log
          text += "\n[= #{m.class.to_s} =]\n\n"
          text += Psych.dump(m).gsub(/^/, "\t | ")
          text +="\n\n"
        end
      end
      super text
    end
  end

  ##
  # Fatal errors terminate the application and are done forever.
  ##
  class FatalError < AppError
    def fatal?()        true    end
  end

  ##
  # Restartable errors terminate the application but the application can
  # be reset and restarted (after a delay).
  #
  # An example of a restartable error would be trying to download a file
  # which will be available soon but is not yet available, and accessing
  # the file requires successful navigation through an authorization
  # system which flushes authorization after very short intervals.  To
  # download the file, the entire process must be repeated.
  ##
  class RestartableError < AppError
    def fatal?()        false   end
    def restartable?()  true    end
  end

  ##
  # Retryable errors occur within a very local context in which a temporary
  # glitch causes a failure without fully destroying the current context.
  # The application may/should pause momentary, but it will retry the immediate
  # operations.
  ##
  class RetryableError < RestartableError
    def retryable?()    true    end
  end

end
