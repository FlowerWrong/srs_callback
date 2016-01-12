class Api::V1::TranscodesController < ApplicationController
  def create
    bit_rate = params['bit_rate'].to_i
    input_rtmp = params['input_rtmp']
    origin_stream = params['origin_stream']

    transcodes = []

    # @see https://support.google.com/youtube/answer/2853702?hl=zh-Hans
    case bit_rate
    when 6000..10000 # 1080p@60fps -> 720p, 480p, 360p
      ['720p', '480p', '360p'].each do |transcode_stream|
        job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
        transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      end
    when 4000..6000 # 1080p -> 720p, 480p, 360p
      ['720p', '480p', '360p'].each do |transcode_stream|
        job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
        transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      end
    when 2500..4000 # 720p@60fps -> 480p, 360p
      ['480p', '360p'].each do |transcode_stream|
        job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
        transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      end
    when 1500..2500 # 720p -> 480p, 360p
      ['480p', '360p'].each do |transcode_stream|
        job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
        transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      end
    when 1000..1500 # 480p -> 360p
      ['360p'].each do |transcode_stream|
        job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
        transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      end
    when 600..1000 # 360p
      # ['360p'].each do |transcode_stream|
      #   job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
      #   transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      # end
    when 0..600 # 240p
      # ['360p'].each do |transcode_stream|
      #   job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "rtmp://192.168.10.160/live?token=#{Settings.token_list.split(' ').sample}/#{origin_stream}_#{transcode_stream}")
      #   transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
      # end
    end

    transcodes.each do |t|
      Transcode.create(
        live_client_id: live_client_id,
        input_rtmp: 'rtmp://192.168.10.160/live/demo',
        output_rtmp: "rtmp://192.168.10.160/live/#{origin_stream}_#{t[:transcode_stream]}",
        ip: pa['ip'],
        vhost: pa['vhost'],
        app: pa['app'],
        stream: "#{origin_stream}_#{transcode_stream}",
        status: 1,
        job_id: t[:job_id]
      )
    end

    render json: {code: 201}, status: 201
  end
end
