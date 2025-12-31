require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'password authentication' do
    let(:user) { create(:user, password: 'password123') }

    it 'authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'returns false with incorrect password' do
      expect(user.authenticate('wrong-password')).to be_falsey
    end
  end

  describe 'password_digest' do
    it 'is created when password is set' do
      user = build(:user, password: 'password123')
      expect(user.password_digest).to be_present
    end
  end

  describe 'unique email constraint' do
    it 'prevents duplicate emails' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      
      expect(duplicate_user).to_not be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { should have_many(:torrents).dependent(:destroy) }
  end

  describe '#ratio' do
    let(:user) { create(:user) }

    context 'when both uploaded and downloaded are zero' do
      it 'returns nil' do
        expect(user.ratio).to be_nil
      end
    end

    context 'when uploaded is zero and downloaded is positive' do
      before { user.update(downloaded: 1000) }

      it 'returns 0.0' do
        expect(user.ratio).to eq(0.0)
      end
    end

    context 'when uploaded is positive and downloaded is zero' do
      before { user.update(uploaded: 1000) }

      it 'returns infinity' do
        expect(user.ratio).to eq(Float::INFINITY)
      end
    end

    context 'when both are positive' do
      before do
        user.update(uploaded: 5000, downloaded: 2000)
      end

      it 'calculates ratio correctly' do
        expect(user.ratio).to eq(2.5)
      end
    end
  end

  describe '#update_stats!' do
    let(:user) { create(:user, uploaded: 1000, downloaded: 500) }

    it 'increments uploaded and downloaded' do
      user.update_stats!(500, 250)
      
      expect(user.reload.uploaded).to eq(1500)
      expect(user.reload.downloaded).to eq(750)
    end

    it 'handles zero deltas' do
      user.update_stats!(0, 0)
      
      expect(user.reload.uploaded).to eq(1000)
      expect(user.reload.downloaded).to eq(500)
    end
  end
end