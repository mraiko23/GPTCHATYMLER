FactoryBot.define do
  factory :chat do

    association :user
    title { "MyString" }

  end
end
