require 'date'

class TimeUtils
    DATE_DIGITS = '%Y%m%d'.freeze
    TIME_DIGITS = '%H%M%S'.freeze
    DATETIME_DIGITS = (DATE_DIGITS + ' ' + TIME_DIGITS).freeze
    DATETIME_ID     = (DATE_DIGITS + '_' + TIME_DIGITS).freeze
    
    TIME_STAMP = '%Y-%m-%d.%H:%M:%S'.freeze
    
    ##
    # Current DateTime as formatted string.
    ##
    def self.now_str(format = DATETIME_ID)  DateTime.now.strftime(format)   end  
    def self.time_stamp()                   now_str TIME_STAMP              end
end
