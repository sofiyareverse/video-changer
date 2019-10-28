require File.expand_path 'spec_helper.rb', __dir__
require 'pry'

describe 'Video Changer' do
  before(:all) do
    Video.create(
      file_format: 'video/mp4',
      file_name: 'filename.mp4',
      file_data: '/tmp/filename.mp4'
    )

    @file = Rack::Test::UploadedFile.new('./spec/files/filename.mp4', 'video/mp4')
  end

  it 'should show error when bad params' do
    get '/watch'

    expect(last_response.status).to eq(400)
  end

  it 'should show error when bad params' do
    get '/status'

    expect(last_response.status).to eq(400)
  end

  it 'should show error when bad params' do
    post '/upload'

    expect(last_response.status).to eq(400)
  end

  it 'should show error when object is not found' do
    get '/watch', { name: "unexisting_video_name" }

    expect(last_response.status).to eq(404)
  end

  it 'should show error when object is not found' do
    get '/status', { name: "unexisting_video_name" }

    expect(last_response.status).to eq(404)
  end

  it 'should show video progress' do
    get '/status', { name: "filename.mp4" }

    expect(last_response.status).to eq(200)
  end

  it 'should show video url' do
    get '/watch', { name: "filename.mp4" }

    expect(last_response.status).to eq(200)
  end

  it 'should transcode video' do
    post '/upload', { file: @file, time_start: 15, time_end: 30 }

    expect(last_response.status).to eq(200)
  end  
end
