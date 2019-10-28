require 'sinatra'
require 'mongoid'
require 'streamio-ffmpeg'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

require_relative './workers/video_upload_worker.rb'

Mongoid.load! "mongoid.config"

class Video
  include Mongoid::Document

  field :file_name,   type: String
  field :file_format, type: String
  field :file_data,   type: String
  field :status,      type: String, default: :pending
end

post '/upload' do
  halt(400, { message:'Bad Request'}.to_json) if params.dig(:file, :type) != 'video/mp4'

  filename = params[:file][:filename]
  file = params[:file][:tempfile]
  Video.create(file_format: File.extname(file.path), file_name: filename)

  VideoUploadWorker.perform_async(filename, [params[:time_start], params[:time_end]])
end

get "/status" do
  halt(400, { message:'Bad Request'}.to_json) if params[:name].nil?
  video = Video.where(file_name: params[:name]).first  

  halt(404, { message:'Failed to find video'}.to_json) unless video

  @video_status = video.status
end

get "/watch" do
  halt(400, { message:'Bad Request'}.to_json) if params[:name].nil?
  video = Video.where(file_name: params[:name]).first

  halt(404, { message:'Failed to find video'}.to_json) unless video

  @video = video.file_data
end
  