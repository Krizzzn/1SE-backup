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
		fldr = date.strftime "%Y-%m %B"

		until i >= dur - 1 
			tm = {:sec => i % 60, :min => i / 60}
			start_time = "00:%02d:%02d" % [tm[:min], tm[:sec]]
			out_file_name = "#{fldr}/#{date.to_s}.mov"
			Dir::mkdir fldr unless Dir::exists? fldr

			options = {custom: "-ss #{start_time} -t 00:00:01"}

			File::unlink out_file_name if File::exists? out_file_name
			movie.transcode(out_file_name, options)
			date+=1
			i += 1
		end
	end

#http://ffmpeg.org/trac/ffmpeg/wiki/How%20to%20concatenate%20(join,%20merge)%20media%20files


private 

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