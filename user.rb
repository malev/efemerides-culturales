class User

  include Mongoid::Document

  field :facebook_id, type: String
  field :name, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :link, type: String
  field :username, type: String
  field :birthday, type: String
  field :gender, type: String
  field :timezone, type: String
  field :verified, type: String
  field :updated_time, type: DateTime
  field :friends, type: Array
  field :likes, type: Array
  field :photos, type: Array

  def self.parse(user)
    self.new({
      :facebook_id  => user["id"],
      :name         => user["name"],
      :first_name   => user["first_name"],
      :middle_name  => user["middle_name"],
      :last_name    => user["last_name"],
      :link         => user["link"],
      :username     => user["username"],
      :birthday     => user["birthday"],
      :gender       => user["gender"],
      :timezone     => user["timezone"],
      :verified     => user["verified"],
      :updated_time => user["updated_time"]
    })
  end
end
