class VideoUploadWorker
  include Sidekiq::Worker
  SCHEDULED = 'scheduled'
  PROCESSING = 'processing'
  DONE = 'done'
  FAILED = 'failed'
  
  def perform(video_name, timing)
    video = Video.find_by(file_name: video_name)

    cut_video(video, timing)
  end

  private

  def cut_video(video, timing)
    movie = FFMPEG::Movie.new("/tmp/#{video.file_name}")
    update_video_status(video, SCHEDULED) if movie

    if generate_cut_options(movie, timing)
      options = generate_cut_options(movie, timing)
      update_video_status(video, PROCESSING)
      transcoded_video = movie.transcode("#{video.id}-#{video.file_name}", options)
      video.update(file_data: movie.path)
      update_video_status(video, DONE) if transcoded_video && video.file_data == movie.path
    else
      update_video_status(video, FAILED)
    end
  end

  def generate_cut_options(movie, timing)
    if ((0..movie.duration) && [timing.first.to_i, timing.last.to_i]).present?
      { custom: ['-ss', timing.first.to_i, '-t', timing.last.to_i] }
    else
      nil
    end
  end

  def update_video_status(video, progress_position)
    video.update(status: progress_position)
  end
end
