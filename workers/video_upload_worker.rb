class VideoUploadWorker
  include Sidekiq::Worker
  SCHEDULED = 'scheduled'
  PROCESSING = 'processing'
  DONE = 'done'
  FAILED = 'failed'
  
  def perform(video_name, timing)
    if video_name
      video = Video.where(file_name: video_name).first

      options = { custom: ['-ss', timing.first.to_i, '-t', timing.last.to_i] }
      update_video_status(video, PROCESSING) if options

      movie = FFMPEG::Movie.new("/tmp/#{video_name}")
      update_video_status(video, SCHEDULED) if movie
      
      transcoded_video = movie.transcode("#{video.id}-#{video_name}", options)
      video.update(file_data: movie.path)

      update_video_status(video, DONE) if transcoded_video && video.file_data == movie.path
    end
  end

  private

  def update_video_status(video, progress_position)
    if [SCHEDULED, PROCESSING, DONE].include?(progress_position)
      video.update(status: progress_position)
    else
      video.update(status: FAILED)
      halt(400, { message:'Bad Request'}.to_json)
    end
  end
end
