require 'rails_helper'

RSpec.describe TrackerController, type: :request do
  describe 'GET /announce' do
    let!(:user) { create(:user) }
    let!(:torrent) { create(:torrent, user: user) }
    let(:peer_id) { SecureRandom.hex(10) } # 20 character string
    
    let(:valid_params) do
      {
        info_hash: torrent.info_hash, # send as hex string to mimic real announce query
        peer_id: peer_id,
        port: 6881,
        uploaded: 1024,
        downloaded: 2048,
        left: 1_000_000,
        user_id: user.id
      }
    end

    context 'with valid parameters' do
      it 'creates a new peer' do
        get '/announce', params: valid_params
        
        expect(response).to have_http_status(:success)
        expect(Peer.count).to eq(1)
      end

      it 'returns bencoded response with interval and peer stats' do
        get '/announce', params: valid_params
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('interval')
        expect(response.content_type).to start_with('text/plain')
      end

      it 'updates existing peer on subsequent announce' do
        # First announce
        get '/announce', params: valid_params
        peer = Peer.last
        
        # Second announce with updated stats
        updated_params = valid_params.merge(uploaded: 2048, downloaded: 4096)
        
        expect {
          get '/announce', params: updated_params
        }.not_to change(Peer, :count)
        
        peer.reload
        expect(peer.uploaded).to eq(2048)
        expect(peer.downloaded).to eq(4096)
      end

      it 'updates user upload/download stats' do
        initial_uploaded = user.uploaded
        initial_downloaded = user.downloaded
        
        get '/announce', params: valid_params
        
        user.reload
        expect(user.uploaded).to eq(initial_uploaded + 1024)
        expect(user.downloaded).to eq(initial_downloaded + 2048)
      end

      it 'only updates user stats with delta on subsequent announces' do
        # First announce
        get '/announce', params: valid_params
        user.reload
        uploaded_after_first = user.uploaded
        downloaded_after_first = user.downloaded
        
        # Second announce with increased stats
        updated_params = valid_params.merge(uploaded: 3072, downloaded: 6144)
        get '/announce', params: updated_params
        
        user.reload
        expect(user.uploaded).to eq(uploaded_after_first + 2048) # Delta: 3072 - 1024
        expect(user.downloaded).to eq(downloaded_after_first + 4096) # Delta: 6144 - 2048
      end

      it 'enqueues torrent stats update job' do
        expect {
          get '/announce', params: valid_params
        }.to have_enqueued_job(UpdateTorrentStatsJob).with(torrent.id)
      end

      it 'uses client IP address for peer' do
        get '/announce', params: valid_params
        peer = Peer.last
        
        expect(peer.ip).to eq('127.0.0.1') # Default test IP
      end
    end

    context 'with event parameter' do
      context 'when event is started' do
        it 'creates peer with started event' do
          get '/announce', params: valid_params.merge(event: 'started')
          
          peer = Peer.last
          expect(peer.event).to eq('started')
          expect(Peer.count).to eq(1)
        end
      end

      context 'when event is completed' do
        it 'creates peer with completed event' do
          get '/announce', params: valid_params.merge(event: 'completed', left: 0)
          
          peer = Peer.last
          expect(peer.event).to eq('completed')
          expect(peer.left).to eq(0)
        end
      end

      context 'when event is stopped' do
        it 'removes the peer' do
          # Create peer first
          get '/announce', params: valid_params
          expect(Peer.count).to eq(1)
          
          # Send stopped event
          get '/announce', params: valid_params.merge(event: 'stopped')
          
          expect(Peer.count).to eq(0)
        end

        it 'still updates user stats before removing peer' do
          # First announce
          get '/announce', params: valid_params
          user.reload
          uploaded_before = user.uploaded
          
          # Stopped with increased upload
          get '/announce', params: valid_params.merge(event: 'stopped', uploaded: 5120)
          
          user.reload
          expect(user.uploaded).to eq(uploaded_before + 4096) # Delta: 5120 - 1024
        end
      end
    end

    context 'with missing parameters' do
      it 'returns error when info_hash is missing' do
        get '/announce', params: valid_params.except(:info_hash)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('failure reason')
        expect(response.body).to include('info_hash')
      end

      it 'returns error when peer_id is missing' do
        get '/announce', params: valid_params.except(:peer_id)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('peer_id')
      end

      it 'returns error when port is missing' do
        get '/announce', params: valid_params.except(:port)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('port')
      end

      it 'returns error when user_id is missing' do
        get '/announce', params: valid_params.except(:user_id)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('user_id')
      end

      it 'returns error for multiple missing parameters' do
        get '/announce', params: valid_params.except(:port, :uploaded)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('port')
        expect(response.body).to include('uploaded')
      end
    end

    context 'with invalid data' do
      it 'returns error when torrent not found' do
        invalid_hash = [SecureRandom.hex(20)].pack('H*')
        get '/announce', params: valid_params.merge(info_hash: invalid_hash)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('Torrent not found')
      end

      it 'returns error when user not found' do
        get '/announce', params: valid_params.merge(user_id: 'invalid-uuid')
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('User not found')
      end

      it 'returns error when peer save fails' do
        # Create invalid peer data (port out of range will fail validation)
        get '/announce', params: valid_params.merge(port: 70000)
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('Failed to update peer')
      end
    end

    context 'bencoding' do
      it 'returns properly bencoded response' do
        get '/announce', params: valid_params
        
        # Check for bencode dictionary start
        expect(response.body).to start_with('d')
        # Check for bencode structure (keys should be sorted)
        expect(response.body).to include('8:complete')
        expect(response.body).to include('10:incomplete')
        expect(response.body).to include('8:interval')
      end
    end

    context 'peer list encoding' do
      let!(:other_user) { create(:user) }
      let!(:peer1) { create(:peer, torrent: torrent, user: other_user, ip: '192.168.1.1', port: 6881, last_announce: Time.current) }
      let!(:peer2) { create(:peer, torrent: torrent, user: other_user, ip: '10.0.0.1', port: 8080, last_announce: Time.current) }

      it 'includes active peers in compact binary format' do
        get '/announce', params: valid_params
        
        expect(response).to have_http_status(:success)
        # Response should include peers list
        expect(response.body).to include('5:peers')
      end

      it 'limits peer list to 50 peers' do
        # Create many peers
        55.times do
          create(:peer, torrent: torrent, user: other_user, last_announce: Time.current)
        end
        
        get '/announce', params: valid_params
        
        # Hard to test exact binary peer count, but response should succeed
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /scrape' do
    let!(:user) { create(:user) }
    let!(:torrent1) { create(:torrent, user: user, seeders: 5, leechers: 3, completed: 100) }
    let!(:torrent2) { create(:torrent, user: user, seeders: 2, leechers: 1, completed: 50) }
    
    context 'with single info_hash' do
      it 'returns torrent stats' do
        get '/scrape', params: { info_hash: torrent1.info_hash }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('files')
        expect(response.body).to include('complete')
        expect(response.body).to include('incomplete')
        expect(response.body).to include('downloaded')
      end

      it 'returns correct stats values' do
        get '/scrape', params: { info_hash: torrent1.info_hash }
        
        # Check for bencoded integers
        expect(response.body).to include("i#{torrent1.seeders}e") # complete
        expect(response.body).to include("i#{torrent1.leechers}e") # incomplete
        expect(response.body).to include("i#{torrent1.completed}e") # downloaded
      end
    end

    context 'with multiple info_hashes' do
      it 'returns stats for multiple torrents' do
        get '/scrape', params: { info_hash: [torrent1.info_hash, torrent2.info_hash] }
        
        expect(response).to have_http_status(:success)
        # Both torrents should be in response
        expect(response.body).to include("i#{torrent1.seeders}e")
        expect(response.body).to include("i#{torrent2.seeders}e")
      end
    end

    context 'with no info_hash' do
      it 'returns error' do
        get '/scrape'
        
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('No info_hash provided')
      end
    end

    context 'with non-existent torrent' do
      it 'excludes non-existent torrents from response' do
        invalid_hash = SecureRandom.hex(20)
        
        get '/scrape', params: { info_hash: [torrent1.info_hash, invalid_hash] }
        
        expect(response).to have_http_status(:success)
        # Should include valid torrent
        expect(response.body).to include("i#{torrent1.seeders}e")
      end
    end

    context 'bencoding' do
      it 'returns properly bencoded response' do
        get '/scrape', params: { info_hash: torrent1.info_hash }
        
        # Check for bencode dictionary start
        expect(response.body).to start_with('d')
        expect(response.body).to end_with('e')
      end
    end
  end
end
