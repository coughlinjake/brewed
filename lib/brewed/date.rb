# encoding: utf-8

require 'time'
require 'date'

class Time
  def to_date()     ::Date.new(year, month, day);                   rescue NameError; nil; end
  def to_datetime() DateTime.new(year, month, day, hour, min, sec); rescue NameError; nil; end
end

module Brewed
  module Date
    DOW_M_D   = '%a, %b %d'.freeze
    Y_M_D     = '%Y-%m-%d'.freeze
    H12_M_PM  = '%l:%M %P'.freeze
    H24_M     = '%H:%M'.freeze
    DOW_DT    = '%a, %b %d %l:%M %P'.freeze
    DSLASHT   = '%Y/%m/%d %H:%M'.freeze
    DT_TM     = '%Y-%m-%d %H:%M'.freeze
    Y_MON_D_TM = '%Y.%b.%d  %I:%M %P'.freeze
    DT_B_TM_B  = '%Y-%m-%d [%H:%M]'.freeze
    MD_TIME    = '%b.%d %l:%M.%S %P'.freeze
    TIME_MD    = '%l:%M.%S %P, %b %d'.freeze
    EMPTY      = ''.freeze

    ##
    # Returns today's abbreviated day of the week as a lowercased Symbol.
    #
    # @param dt   see DateUtils.to_datetime
    # @return     [Symbol]
    #
    # @example Determine today's day of the week
    #    dow = DateUtils.dow
    # @example Determine yesterday's day of the week
    #    dow = DateUtils.dow (Date.today - 1)
    ##
    def self.dow(dt = nil)
      ::Date::ABBR_DAYNAMES[ to_datetime(dt).wday ].downcase.to_sym
    end

    ##
    # Return the current time as Epoch time.
    #
    # @return [FixedNum]
    ##
    def self.epoch_now()
      Time.now.to_i
    end

    ##
    # Convert the provided epoch time to a Time object.
    #
    # @param epoch  [FixedNum]
    # @return       [DateTime]
    ##
    def self.epoch_time(epoch)
      Time.at(epoch)
    end

    ##
    # Convert from any datetime representation to Epoch time.
    #
    # @param dt   see DateUtils.to_datetime
    # @return     [FixedNum]
    ##
    def self.to_epoch(dt)
      dt = DateTime.parse(dt) if dt.is_a? String
      case dt
        when NilClass   then Time.now.to_i
        when Integer    then dt
        when Time       then dt.to_i
        when DateTime   then Time.local(dt.year,dt.month,dt.day,dt.hour,dt.min,dt.sec).to_i
        when ::Date     then Time.local(dt.year,dt.month,dt.day,0,0,0).to_i
        else
          raise ArgumentError, "unknown input datetime format: #{dt.class.to_s} (#{dt.to_s})"
      end
    end

    ##
    # Convert from any datetime representation to a DateTime object.
    #
    # to_datetime(nil) === DateTime.now
    #
    # @param dt [nil, String, Integer, Time, Date, DateTime]
    # @return   [DateTime]
    ##
    def self.to_datetime(dt)
      dt = Time.at(dt) if dt.is_a? Integer
      case dt
        when DateTime then  dt
        when ::Date   then  DateTime.new(dt.year, dt.month, dt.day, 0, 0, 0)
        when NilClass then  DateTime.now
        when Time     then  DateTime.new(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec)
        when String   then  DateTime.parse(dt)
        else
          if dt.is_a? ::Date
            dt = DateTime.new(dt.year, dt.month, dt.day, 0, 0, 0)
          else
            raise ArgumentError, "unknown input datetime format: #{dt.class.to_s} (#{dt.to_s})"
          end
      end
    end

    ##
    # Convert any datetime representation to a Date object.
    #
    ##
    def self.to_date(dt)
      dt = Time.at(dt) if dt.is_a? Integer
      case dt
        when DateTime   then dt.to_date
        when ::Date     then dt
        when NilClass   then ::Date.today
        when Time       then ::Date.new(dt.year, dt.month, dt.day)
        when String     then ::Date.parse(dt)
        else
          raise ArgumentError, "unknown input datetime format: #{dt.class.to_s} (#{dt.to_s})"
      end
    end

    ##
    # Return the Sunday of the week containing the specified time.
    #
    # If the provided time is anything but a Date, returns DateTime.
    # If the provided time is a Date, returns a Date.
    #
    # @param t  [nil, String, Integer, Time, Date, DateTime]
    # @return   [Date, DateTime]
    ##
    def self.sunday(t)
      dt  = to_datetime t
      sun = dt - dt.cwday
      (t.is_a? ::Date) ? sun.to_date : sun
    end

    ##
    # Return the Monday (start of week) of the week containing specified time.
    #
    # If the provided time is anything but a Date, returns DateTime.
    # If the provided time is a Date, returns a Date.
    #
    # @param t  [nil, String, Integer, Time, Date, DateTime]
    # @return   [Date, DateTime]
    ##
    def self.monday(t)
      dt  = to_datetime t
      mon = dt - (dt.cwday - 1)
      (t.is_a? ::Date) ? mon.to_date : mon
    end

    ##
    # Return the calendar week for the provided datetime.
    #
    # ISO-8601 defines the week as starting on Monday, and the first week of
    # the year is the week with the first Thursday.
    #
    # Ruby considers Monday to be the first day of the week and
    # Sunday to be the last day of the week.  That is
    ##
    # def self.cweek(dt)
    #   dt = to_datetime dt
    #   dt.sunday? ? (dt.cweek + 1) : dt.cweek
    # end

    ##
    # Combine a Date with a time of day to produce a DateTime.
    #
    # @param dt   [Date]
    # @param tm   [String]
    # @return     [DateTime]
    #
    # @example Return 2014-02-14 20:00 as a DateTime
    #    dt = DateUtils.date_tod Date.parse('2014-02-14'), '20:00'
    ##
    def self.date_tod(dt, tm)
      DateTime.parse "#{fmt_date(dt)} #{tm}"
    end

    ##
    # Return the current datetime as YYYY-MM-DD HH:mm.
    ##
    def self.now_str()               _format_dt DateTime.now, DT_TM   end
    def self.today_str()             _format_dt DateTime.now, Y_M_D   end

    ##
    # Convert a UTC datetime to local time.
    #
    # @note THIS METHOD ONLY ACCEPTS AND RETURNS TIME OBJECTS!
    #
    # @param dt   [Time]
    # @return     [Time]
    ##
    def self.from_utc(dt)
      case dt
        when Time   then  dt.localtime
        else
          raise ArgumentError, "converting #{dt.class.to_s} from UTC not implemented"
      end
    end

    ##
    # Format the provided DateTime object for display in page.
    #
    # @param dt [DateTime]
    # @return [String]
    ##
    def self.fmt_dow_date(dt)         _format_dt dt, DOW_M_D    end
    def self.fmt_date(dt)             _format_dt dt, Y_M_D      end

    def self.fmt_dt(dt)               _format_dt dt, DT_TM      end
    def self.fmt_d_bt(dt)             _format_dt dt, DT_B_TM_B  end

    def self.fmt_y_mon_d_tm(dt)       _format_dt dt, Y_MON_D_TM end

    ##
    # Format the provided DateTime object for display in page.
    #
    # @param dt [DateTime]
    # @return [String]
    ##
    def self.fmt_time(dt)             _format_dt dt, H12_M_PM   end
    def self.fmt_time24(dt)           _format_dt dt, H24_M      end

    ##
    # Format the provided DateTime object with a DOW.
    #
    # @param dt [DateTime]
    # @return [String]
    ##
    def self.fmt_dow_dt(dt)           _format_dt dt, DOW_DT     end

    ##
    # Format the provided DateTime object suitable for the HTML datetime picker element.
    #
    # @param dt [DateTime]
    # @return [String]
    ##
    def self.fmt_dt_picker(dt)        _format_dt dt, DSLASHT    end
    def self.fmt_dt_compact(dt)       _format_dt dt, DT_TM      end
    def self.fmt_dt_compact_brac(dt)  _format_dt dt, DT_B_TM_B  end

    def self.fmt_dt_tm(dt)            _format_dt dt, MD_TIME    end
    def self.fmt_tm_dt(dt)            _format_dt dt, TIME_MD    end

    private

    def self._format_dt(dt, format)
      to_datetime(dt).strftime(format)
    end

  end
end
