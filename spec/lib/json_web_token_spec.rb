require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 123 } }

  describe '.encode' do
    it 'generates a JWT token' do
      token = JsonWebToken.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'includes expiration time' do
      token = JsonWebToken.encode(payload)
      decoded = JWT.decode(token, JsonWebToken::SECRET_KEY)[0]
      
      expect(decoded['exp']).to be_present
      expect(decoded['exp']).to be > Time.current.to_i
    end
  end

  describe '.decode' do
    context 'with valid token' do
      let(:token) { JsonWebToken.encode(payload) }

      it 'decodes the token and returns payload' do
        decoded = JsonWebToken.decode(token)
        
        expect(decoded[:user_id]).to eq(123)
        expect(decoded[:exp]).to be_present
      end
    end

    context 'with invalid token' do
      it 'returns nil for malformed token' do
        result = JsonWebToken.decode('invalid-token')
        expect(result).to be_nil
      end

      it 'returns nil for empty token' do
        result = JsonWebToken.decode('')
        expect(result).to be_nil
      end
    end

    context 'with expired token' do
      let(:expired_token) { JsonWebToken.encode(payload, 1.hour.ago) }

      it 'returns nil' do
        result = JsonWebToken.decode(expired_token)
        expect(result).to be_nil
      end
    end
  end
end