# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
FactoryGirl.define do
  factory :version do
    whodunnit ""
    item                { fail "Please specify :item for the version" }
    event "create"
    created_at          { FactoryGirl.generate(:time) }
  end

  factory :comment do
    user
    commentable         { fail "Please specify :commentable for the comment" }
    title               { FactoryGirl.generate(:title) }
    private false
    comment             { Faker::Lorem.paragraph }
    state "Expanded"
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
  end

  factory :email do
    imap_message_id     { "%08x" % rand(0xFFFFFFFF) }
    user
    mediator            { fail "Please specify :mediator for the email" }
    sent_from           { Faker::Internet.email }
    sent_to             { Faker::Internet.email }
    cc                  { Faker::Internet.email }
    bcc nil
    subject             { Faker::Lorem.sentence }
    body                { Faker::Lorem.paragraph[0, 255] }
    header nil
    sent_at             { FactoryGirl.generate(:time) }
    received_at         { FactoryGirl.generate(:time) }
    deleted_at nil
    state "Expanded"
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
  end

  factory :address do
    addressable         { fail "Please specify :addressable for the address" }
    street1             { Faker::Address.street_address }
    street2             { Faker::Address.street_address }
    city                { Faker::Address.city }
    state               { Faker::AddressUS.state_abbr }
    zipcode             { Faker::AddressUS.zip_code }
    country             { Faker::AddressUK.country }
    full_address        { FactoryGirl.generate(:address) }
    address_type        { %w(Business Billing Shipping).sample }
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
    deleted_at nil
  end

  factory :avatar do
    user
    entity              { fail "Please specify :entity for the avatar" }
    image               { File.new(Rails.root.join('spec', 'fixtures', 'rails.png')) }
    updated_at          { FactoryGirl.generate(:time) }
    created_at          { FactoryGirl.generate(:time) }
  end
end
