require 'sinatra'
require 'mongoid'
require 'streamio-ffmpeg'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'pry'

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
  filename = params[:file][:filename]
  file = params[:file][:tempfile]

  File.open("/tmp/#{filename}", 'wb') do |f|
    f.write(file.read)
  end

  video = Video.create(file_format: File.extname(file.path), file_name: filename)
  VideoUploadWorker.perform_async(video.file_name, [params[:time_start], params[:time_end]])
  @video = video
end

get "/status" do
  video = Video.where(params[:name]).first

  halt(404, { message:'failed to find video'}.to_json) unless video

  @video_status = video.status
end

get "/watch" do
  video = Video.where(params[:name]).first

  halt(404, { message:'failed to find video'}.to_json) unless video

  @video = video
end
  