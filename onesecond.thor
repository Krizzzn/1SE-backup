require 'rubygems'
require 'streamio-ffmpeg'
require 'thor'

class Onesecond < Thor
	ONE_SECOND_APP_MODE_SUFFIX = 5

	method_option :one_second_everyday_mode, :type => :boolean, :default => true, :aliases => "e", :desc => "cuts the last #{ONE_SECOND_APP_MODE_SUFFIX} seconds from the input video before splitting it into chunks."

	desc 'split FILE_NAME', "Split the FILE_NAME video into 1 second chunks."
	method_option :start_date, :type => :string, :required => true, :aliases => "s", :desc => "the first day in the video. Format: 2013-01-01"
	method_option :cut_from_end, :type => :numeric, :default => -1, :aliases => "c", :desc => "cut N seconds from end before the split. Overrides the one_second_everyday_mode parameter."
	def split(file_name)
		movie = load_movie(file_name)
		if movie.nil?
			say "movie #{file_name} not found or invalid."
			return
		end

		start_date = Date.parse(options[:start_date], movie)

		split_movie start_date
	end

	desc "auto_split FILE_NAME", "Splits the seconds from FILE_NAME. Reads the last date of previous splits."
	method_option :cut_from_end, :type => :numeric, :default => -1, :aliases => "c", :desc => "cut N seconds from end. Overrides the one_second_everyday_mode parameter."
	def auto_split(file_name)
		movies = find_all_movies 
		movie = load_movie(file_name)
		
		if movies.length == 0
			say "no movies found - can't automerge"
			return
		elsif movie.nil?
			say "movie #{file_name} not found or invalid."
			return
		end

		last_movie_date = Date.parse (/\d{4}-\d{2}-\d{2}/.match movies.last).to_s
		last_movie_date += 1
		split_movie last_movie_date, movie
	end

	desc "merge", "Merges seconds to a movie. Use chunks from :start_date until :end_date."
	method_option :start_date, :type => :string, :required => true, :aliases => "s", :desc => "the first day. Format: 2013-01-01"
	method_option :end_date, :type => :string, :required => false, :aliases => "e", :desc => "last day. Format: 2013-01-01"
	method_option :output_file, :type => :string, :default => "one_second_everyday.mov" , :alias => "o", :desc => "file name of the merged video."
	def merge()
		end_date = Date.parse(options[:end_date]) unless options[:end_date].nil? 
		end_date ||=  Date::today
		date = Date.parse(options[:start_date])
		File::unlink "concat" if File::exists? "concat"

		movies_for_merge = []
		while date <= end_date do
			file = make_path(date)
			date += 1
			movies_for_merge << file[:path] if File::exists? file[:path]
		end

		merge_files movies_for_merge
	end

	desc "merge_all", "Merges all available second chunks into one movie."
	method_option :output_file, :type => :string, :default => "one_second_everyday.mov" , :alias => "o", :desc => "file name of the merged video."
	method_option :max_months, :type => :numeric, :default => 12, :alias => "m", :desc => "Months from the latest chunk for the merge."
	def merge_all
		movies = find_all_movies 

		months = options[:max_months]
		months = 12 if months < 1

		last_movie_date = Date.parse (/\d{4}-\d{2}-\d{2}/.match movies.last).to_s
		last_movie_date = (last_movie_date << months)

		movies_for_merge = movies.select {|item| 
			date = Date.parse (/\d{4}-\d{2}-\d{2}/.match item).to_s 
			last_movie_date < date
		}

		merge_files movies_for_merge
	end

	desc "add_new_movie FILE_NAME", "Split FILE_NAME (leave empty to auto-discover the file with the latest creation date) and merge the latest movies."
	method_option :output_file, :type => :string, :default => "one_second_everyday.mov" , :alias => "o", :desc => "file name of the merged video."
	method_option :max_months, :type => :numeric, :default => 12, :alias => "m", :desc => "Months from the latest chunk for the merge."
	def add_new_movie(file_name = nil)
		file_name = Dir["*.mov"].to_a.sort_by{|file_name| File::mtime file_name }.last if file_name.nil?
		if file_name.nil?
			say "file_name was not auto discovered. Place a .mov file into the root folder."
		end
		invoke :auto_split, [filename]
		invoke :merge_all
	end

private 

def find_all_movies
	Dir["20*"]
		.select { |a| File.basename(a) =~ /\d{4}-\d{2}\ / }
		.map { |item| Dir.foreach(item)
						 .to_a
						 .select{|file| file =~ /.*\.mov/ }
						 .map{|file| item + "/" + file} }
		.flatten
		.sort
end

def split_movie(start_date, movie)
	i = 0
	dur = duration(movie)

	until i >= dur 
		file = make_path(start_date)
		tm = {:sec => i % 60, :min => i / 60}
		start_time = "00:%02d:%02d" % [tm[:min], tm[:sec]]

		Dir::mkdir file[:folder] unless Dir::exists? file[:folder]

		options = {custom: "-ss #{start_time} -t 00:00:01 -c copy"}

		File::unlink file[:path] if File::exists? file[:path]
		movie.transcode(file[:path], options)
		start_date +=1
		i += 1
	end
end

def merge_files(files)
	if (files.length == 0)
		say "no files to merge!"
		return
	end
	say "merging #{files.length} seconds\n"
	File.open("concat", "w") do |f| 
		files.each {|path| f.puts "file '#{path}'" }
	end

	File::unlink options[:output_file] if File::exists? options[:output_file]
	`./ffmpeg -f concat -i concat -c copy #{options[:output_file]}`

	File::unlink "concat"
end

def make_path(date)
	fldr = date.strftime "%Y-%m %B"
	out_file_name = "#{fldr}/#{date.to_s}.mov"
	{:folder => fldr, :path => out_file_name}
end

def duration(movie)
	cut = options[:cut_from_end]

	if cut < 0
		cut = 0 
		cut = ONE_SECOND_APP_MODE_SUFFIX if options[:one_second_everyday_mode]
	end

	(movie.duration - cut).ceil
end

def load_movie(file_name)
	return nil unless File::exists? file_name
	file = File.dirname(__FILE__) + "/" + file_name
	FFMPEG.ffmpeg_binary = File.dirname(__FILE__) + "/ffmpeg"
	movie = FFMPEG::Movie.new(file)

	return nil unless movie.valid?
	movie
end
end