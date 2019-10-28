class VideoUploadWorker
  include Sidekiq::Worker
  SCHEDULED = 'scheduled'
  PROCESSING = 'processing'
  DONE = 'done'
  FAILED = 'failed'
  
  def perform(video_name, timing)
    video = Video.find_by(file_name: video_name)
    success = change_video(video, timing)

    update_video_status(video, FAILED) unless success
  end

  private

  def change_video(video, timing)
    movie = new_movie(video)
    options = generate_cut_options(movie, timing)
    update_video_status(video, PROCESSING)

    movie.transcode("#{video.id}-#{video.file_name}", options)
    video.update(file_data: movie.path)
    update_video_status(video, DONE)
  end

  def new_movie(video)
    update_video_status(video, SCHEDULED)
    FFMPEG::Movie.new("/tmp/#{video.file_name}")
  end

  def generate_cut_options(movie, timing)
    all_timing = (0..movie.duration)
    if all_timing.include?(timing.first.to_i) &&
      all_timing.include?(timing.last.to_i)
      { custom: ['-ss', timing.first.to_i, '-t', timing.last.to_i] }
    end
  end

  def update_video_status(video, progress_position)
    video.update(status: progress_position)
  end
end
