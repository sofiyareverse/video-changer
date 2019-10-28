class VideoUploadWorker
  include Sidekiq::Worker
  SCHEDULED = 'scheduled'
  PROCESSING = 'processing'
  DONE = 'done'
  FAILED = 'failed'
  
  def perform(video_name, timing)
    if video_name
      video = Video.where(file_name: video_name).first

      movie = FFMPEG::Movie.new("/tmp/#{video_name}")
      update_video_status(video, SCHEDULED) if movie

      options = { custom: ['-ss', timing.first.to_i, '-t', timing.last.to_i] }
      update_video_status(video, PROCESSING) if options
      
      transcoded_video = movie.transcode("#{video.id}-#{video_name}", options)
      video.update(file_data: movie)
      update_video_status(video, DONE) if transcoded_video && video.file_data == movie
    end
  end

  private

  def update_video_status(video, progress_position)
    case progress_position
    when SCHEDULED
      video.update(status: SCHEDULED)
    when PROCESSING
      video.update(status: PROCESSING)
    when DONE
      video.update(status: DONE)
    else
      video.update(status: FAILED)
      halt(404, { message:'failed to transcode video'}.to_json)
    end
  end
end
