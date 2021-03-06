require_relative 'HPC'
require_relative 'scraping/stock_info_scraper'
require_relative 'scraping/dividends_scraper' # update the dividends.yml file 
require_relative 'extensions/extend_yaml'
require 'yaml'
require 'time'
require 'time_difference'


@research_File = File.open(File.expand_path('data/research.txt', File.dirname(__FILE__)),'a+')
@dividends =  YAML.load_file(File.expand_path('data/dividends.yml', File.dirname(__FILE__)))
@divs_to_eval_File_WR = File.open(File.expand_path('data/divs_to_eval_WR.yml', File.dirname(__FILE__)),'r+')
@divs_to_eval_File = File.open(File.expand_path('data/divs_to_eval.yml', File.dirname(__FILE__)),'w')


def self.get_upcoming_dividends
	@dividends.map do |dividend|
		ex_div_date = Time.parse(dividend[:ex_div_date])
		dividend if (ex_div_date.strftime('%x') ==  @EX_DIV_DATE.strftime('%x'))
	end.compact 
end

def self.calculations(dividend) # calcs #=> yield, hypo
	stock_info = StockInfo.get_info(dividend[:code])
	div_yield = dividend[:amount].to_f/stock_info[:last_price].to_f
	hpc = HPC.hpc(stock_info[:last_price].to_f, dividend[:amount].to_f, dividend[:franking].to_f)
	{stock_info: stock_info, div_yield: div_yield, hpc: hpc, buy_price: stock_info[:last_price]}
end

# def self.calculations(dividend) # calcs #=> yield, hypo
# 	stock_info = StockInfo.get_info(dividend[:code])
# 	div_yield = dividend[:amount].to_f/stock_info[:prev_close].to_f
# 	hpc = HPC.hpc(stock_info[:prev_close].to_f, dividend[:amount].to_f, dividend[:franking].to_f)
# 	{div_yield: div_yield, hpc: hpc, buy_price: stock_info[:prev_close]}
# end

def self.write_to_research_file #=> meant to write all the required information for today's dividends i.e. Tomorrow's ex-dividend dates
	@research_File.puts "==================================== #{@EX_DIV_DATE.strftime("%d/%m/%Y")} ===================================="
	get_upcoming_dividends.each do |dividend|
		calcs = calculations(dividend)
		@research_File.puts "(#{dividend[:code]}: #{calcs[:hpc].round(3)} #{dividend[:franking]} #{calcs[:div_yield].round(2)})"
		@divs_to_eval_File_WR.puts dividend.merge({hpc: calcs[:hpc].round(3), div_yield: calcs[:div_yield].round(2), buy_price: calcs[:buy_price]}).to_yaml
	end
end

def self.write_to_divs_to_eval_file
	divs_to_eval_yaml = YAML.load_stream(File.read File.expand_path('data/divs_to_eval_WR.yml', File.dirname(__FILE__)))
	divs_to_eval_yaml.each do |div|
		@divs_to_eval_File.puts StockInfo.get_info(div[:code]).merge(div).to_yaml # get latest info on stock 
	end
end

 @EX_DIV_DATE = Time.parse('14/03/2016')
# loop do 
# 	# TTW = 10 # (T)ime (T)o (W)ait 
# 	# if Time.now > (@EX_DIV_DATE - 21600)
		
# 		write_to_research_file 
# 		puts "\n============== Calculated HPC for ex-dividend @ #{@EX_DIV_DATE} ==============\n"
# 		TTW = TimeDifference.between(Time.now, @EX_DIV_DATE + 64820).in_seconds
# 		if Time.now > @EX_DIV_DATE + 64800
# 			write_to_divs_to_eval_file
# 			puts "\n============== Got stock prices for trading day ==============\n"
# 			@EX_DIV_DATE += 86400
# 			require_relative 'evaluate' # execute evaluate to see if stocks reached hypo today
# 			require_relative 'scraping/dividends_scraper' # update dividend list
# 		else
# 			puts "Waiting for markets to close and calculate closing prices. Time left: #{TimeDifference.between(Time.now, @EX_DIV_DATE + 64800).in_minutes} minutes"
# 		end
	
# 	# else
# 	# 	puts "Time left until execution #{TimeDifference.between(Time.now, @EX_DIV_DATE - 21600).in_minutes} minutes "
# 	# 	TTW = TimeDifference.between(Time.now, @EX_DIV_DATE - 21600).in_seconds
# 	# end
# 	puts "[#{Time.now}] Time until next execution #{TTW} seconds"
# 	sleep(TTW)
# end

 write_to_research_file
 #write_to_divs_to_eval_file
 
	
puts '============== Done writing to appropriate files =============='
