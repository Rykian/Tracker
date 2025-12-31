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
end