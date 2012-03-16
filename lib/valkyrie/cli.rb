require "valkyrie/database"
require "valkyrie/progress_bar"

class Valkyrie::CLI

  def self.start(*args)
    url1 = args.shift
    url2 = args.shift

    unless url1 && url2
      puts "valkyrie FROM TO"
      exit 1
    end

    db1 = Valkyrie::Database.new(url1)
    db2 = Valkyrie::Database.new(url2)

    progress = nil

    db1.transfer_to(db2) do |type, data|
      case type
        when :tables      then puts "Transferring #{data} tables:"
        when :table       then progress = Valkyrie::ProgressBar.new(data.first, data.last, $stdout)
        when :row         then progress.inc(data)
        when :end         then progress.finish
        when :constraints then puts "Transferring tables constraints:"
        when :table_name  then puts "#{data}:"
        when :index       then puts "\t      index: #{data}"
        when :fk          then puts "\tforeign key: #{data}"
      end
    end
  rescue Interrupt
    puts
    puts "ERROR: Transfer aborted by user"
  end

end
