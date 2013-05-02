require 'rubygems'
require 'streamio-ffmpeg'
require 'thor'

class Onesecond < Thor
	ONE_SECOND_APP_MODE_SUFFIX = 5

	method_option :one_second_everyday_mode, :type => :boolean, :default => true, :aliases => "e", :desc => "cuts the last #{ONE_SECOND_APP_MODE_SUFFIX} seconds from the input video"

	desc 'split', "Split the FILE_NAME video into 1 second chunks."
	method_option :start_date, :type => :string, :required => true, :aliases => "s", :desc => "the first day in the video. Format: 2013-01-01"
	method_option :cut_from_end, :type => :numeric, :default => -1, :aliases => "c", :desc => "cut N seconds from end. Overrides the one_second_everyday_mode parameter."
	def split(file_name)
		movie = load_movie(file_name)
		date = Date.parse(options[:start_date])
		i = 0

		dur = duration(movie)

		until i >= dur - 1 
			file = make_path(date)
			tm = {:sec => i % 60, :min => i / 60}
			start_time = "00:%02d:%02d" % [tm[:min], tm[:sec]]

			Dir::mkdir file[:folder] unless Dir::exists? file[:folder]

			options = {custom: "-ss #{start_time} -t 00:00:01"}

			File::unlink file[:path] if File::exists? file[:path]
			movie.transcode(file[:path], options)
			date+=1
			i += 1
		end
	end

	desc "merge", "Merges seconds to a movie"
	method_option :start_date, :type => :string, :required => true, :aliases => "s", :desc => "the first day. Format: 2013-01-01"
	method_option :end_date, :type => :string, :required => false, :aliases => "e", :desc => "last day. Format: 2013-01-01"
	method_option :output_file, :type => :string, :default => "one_second_everyday.mov" , :alias => "o"
	def merge()
		end_date = Date.parse(options[:end_date]) unless options[:end_date].nil? 
		end_date ||=  Date::today
		date = Date.parse(options[:start_date])
		File::unlink "concat" if File::exists? "concat"

		File.open("concat", "w") do |f|  
			while date <= end_date do
				file = make_path(date)
				f.puts "file '#{file[:path]}'" if File::exists? file[:path]
				date += 1
			end
		end

	 	`./ffmpeg -f concat -i concat -c copy #{options[:output_file]}`

		File::unlink "concat"
	end

#http://ffmpeg.org/trac/ffmpeg/wiki/How%20to%20concatenate%20(join,%20merge)%20media%20files


private 

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