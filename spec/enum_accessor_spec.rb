# encoding: UTF-8

require 'spec_helper'
ActiveRecord::Base.connection.create_table :users, force: true do |t|
  t.column :gender, :integer, default: 0
end

describe EnumAccessor do

  let (:create_user_class) do
    class User < ActiveRecord::Base
      enum_accessor :gender, [:female, :male]
    end
  end

  after do
    User.delete_all
  end

  describe 'with an invalid offset' do
    before do
      EnumAccessor.configuration.start_index = 2
      create_user_class
      @user = User.new
    end

    describe "#configure" do
      it 'resets the index offset to 0 if the request is greater than 1' do
        expect(@user.genders.invert.keys.first).to eq(0)
      end
    end
  end

  describe 'with index offset' do
    before do
      EnumAccessor.configuration.start_index = 1
      create_user_class
      @user = User.new
    end

    describe "#configure" do
      it 'offsets the array index by one' do
        expect(@user.genders.invert.keys.first).to eq(1)
      end
    end
  end

  describe 'without index offset' do

    before do
      EnumAccessor.configuration.start_index = 0
      create_user_class
      @user = User.new
    end

    describe "#configure" do
      it 'starts the array with an index of 0' do
        expect(@user.genders.invert.keys.first).to eq(0)
      end
    end
    it 'adds checker' do
      expect(@user.gender_female?).to eq(true)
      expect(@user.gender_male?).to eq(false)
    end

    it 'adds getter' do
      expect(@user.gender).to eq('female')
    end

    it 'adds setter' do
      @user.gender = :male
      expect(@user.gender_male?).to eq(true)

      @user.gender = nil
      expect(@user.gender.nil?).to eq(true)
    end

    it 'adds raw value getter' do
      expect(@user.gender_raw).to eq(0)
    end

    it 'adds humanized methods' do
      I18n.locale = :ja
      expect(User.human_attribute_name(:gender)).to eq('性別')
      expect(User.human_genders).to eq({ 'female' => '女', 'male' => '男' })
      expect(User.human_genders[:female]).to eq('女')
      expect(@user.human_gender).to eq('女')

      I18n.locale = :en
      expect(User.human_attribute_name(:gender)).to eq('Gender')
      expect(User.human_genders).to eq({ 'female' => 'Female', 'male' => 'Male' })
      expect(User.human_genders[:female]).to eq('Female')
      expect(@user.human_gender).to eq('Female')
    end

    it 'adds class methods' do
      expect(User.genders).to eq({ 'female' => 0, 'male' => 1 })
      expect(User.genders[:female]).to eq(0)
    end

    it 'supports manual coding' do
      class UserManualCoding < ActiveRecord::Base
        self.table_name = :users
        enum_accessor :gender, female: 100, male: 200
      end

      user = UserManualCoding.new
      user.gender = :male
      expect(user.gender_male?).to eq(true)
      expect(user.gender_raw).to eq(200)
    end

    it 'adds validation' do
      class UserNoValidate < ActiveRecord::Base
        self.table_name = :users
        enum_accessor :gender, [:female, :male], validates: false
      end

      class UserValidateAllowNil < ActiveRecord::Base
        self.table_name = :users
        enum_accessor :gender, [:female, :male], validates: { allow_nil: true }
      end

      user = User.new
      user.gender = 'male'
      expect(user.valid?).to be_truthy
      user.gender = nil
      expect(user.valid?).to be_falsey
      user.gender = 'bogus' # Becomes nil
      expect(user.valid?).to be_falsey

      user = UserNoValidate.new
      user.gender = 'male'
      expect(user.valid?).to be_truthy
      user.gender = nil
      expect(user.valid?).to be_truthy
      user.gender = 'bogus' # Becomes nil
      expect(user.valid?).to be_truthy

      user = UserValidateAllowNil.new
      user.gender = 'male'
      expect(user.valid?).to be_truthy
      user.gender = nil
      expect(user.valid?).to be_truthy
      user.gender = 'bogus' # Becomes nil
      expect(user.valid?).to be_truthy
    end

    it 'supports find_or_create_by' do
      # `find_or_create_by` uses where-based raw value for find,
      # then passes the raw value to the setter method for create.
      expect {
        User.find_or_create_by(gender: User.genders[:female])
      }.to change{ User.count }.by(1)
    end

    it 'supports scope' do
      User.create!(gender: :female)
      expect(User.where_gender(:female).count).to eq(1)
      expect(User.where_gender(:male, :female).count).to eq(1)
      expect(User.where_gender(:male).count).to eq(0)
    end

  end
end
