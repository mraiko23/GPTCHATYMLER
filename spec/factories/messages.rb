FactoryBot.define do
  factory :message do

    association :chat
    role { "MyString" }
    content { "MyText" }
    attachments { nil }

  end
end
