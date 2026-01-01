class TrackerController < ApplicationController
  # GET /announce?info_hash=...&peer_id=...&port=...&uploaded=...&downloaded=...&left=...&event=...&user_id=...
  def announce
    required_params = [:info_hash, :peer_id, :port, :uploaded, :downloaded, :left, :user_id]
    missing_params = required_params.select { |param| params[param].blank? }
    
    if missing_params.any?
      return render_error("Missing required parameters: #{missing_params.join(', ')}")
    end

    raw_info_hash = params[:info_hash]

    info_hash = if raw_info_hash.is_a?(String) && raw_info_hash.match?(/\A[0-9a-fA-F]{40}\z/)
      raw_info_hash.downcase
    else
      begin
        raw_info_hash.to_s.unpack1('H*')
      rescue ArgumentError
        return render_error('Invalid info_hash')
      end
    end
    torrent = Torrent.find_by(info_hash: info_hash)
    
    unless torrent
      return render_error('Torrent not found')
    end

    user = User.find_by(id: params[:user_id])
    unless user
      return render_error('User not found')
    end

    peer = torrent.peers.find_or_initialize_by(
      peer_id: params[:peer_id],
      ip: request.remote_ip,
      port: params[:port].to_i,
      user: user
    )

    # Calculate deltas for user stats
    uploaded_delta = params[:uploaded].to_i - (peer.uploaded || 0)
    downloaded_delta = params[:downloaded].to_i - (peer.downloaded || 0)

    peer.assign_attributes(
      uploaded: params[:uploaded].to_i,
      downloaded: params[:downloaded].to_i,
      left: params[:left].to_i,
      event: params[:event],
      last_announce: Time.current
    )

    # Update user stats with deltas before any other action
    if uploaded_delta > 0 || downloaded_delta > 0
      user.update_stats!(uploaded_delta, downloaded_delta)
    end

    if params[:event] == 'stopped'
      peer.destroy
      # Update torrent stats after peer removal
      UpdateTorrentStatsJob.perform_later(torrent.id)
    elsif peer.save
      # Update torrent stats asynchronously
      UpdateTorrentStatsJob.perform_later(torrent.id)
    else
      return render_error('Failed to update peer')
    end

    # Return peer list
    peers = torrent.peers.active.limit(50).pluck(:ip, :port)
    
    response = {
      interval: 1800, # 30 minutes
      complete: torrent.seeders,
      incomplete: torrent.leechers,
      peers: encode_peers(peers)
    }

    render plain: bencode(response), content_type: 'text/plain'
  end

  # GET /scrape?info_hash=...&info_hash=...
  def scrape
    info_hashes = [params[:info_hash]].flatten.compact
    
    if info_hashes.empty?
      return render_error('No info_hash provided')
    end

    files = {}
    info_hashes.each do |raw_hash|
      # Handle both hex-encoded and binary info_hash
      info_hash = if raw_hash.is_a?(String) && raw_hash.match?(/\A[0-9a-fA-F]{40}\z/)
        raw_hash.downcase
      else
        begin
          raw_hash.to_s.unpack1('H*')
        rescue ArgumentError
          next # Skip invalid hashes
        end
      end
      
      torrent = Torrent.find_by(info_hash: info_hash)
      
      if torrent
        files[raw_hash] = {
          complete: torrent.seeders,
          incomplete: torrent.leechers,
          downloaded: torrent.completed
        }
      end
    end

    response = { files: files }
    render plain: bencode(response), content_type: 'text/plain'
  end

  private

  def render_error(message)
    render plain: bencode({ 'failure reason' => message }), content_type: 'text/plain', status: :bad_request
  end

  def encode_peers(peers)
    # Compact binary format: 6 bytes per peer (4 for IP, 2 for port)
    peers.map do |ip, port|
      ip.split('.').map(&:to_i).pack('C*') + [port].pack('n')
    end.join
  end

  def bencode(obj)
    case obj
    when Integer
      "i#{obj}e"
    when String
      "#{obj.bytesize}:#{obj}"
    when Array
      "l#{obj.map { |item| bencode(item) }.join}e"
    when Hash
      "d#{obj.sort.map { |k, v| bencode(k.to_s) + bencode(v) }.join}e"
    else
      ''
    end
  end
end
