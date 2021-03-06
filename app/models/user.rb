class User < ActiveRecord::Base
  has_many :status_updates
  has_many :events_users
  has_many :events, through: :events_users
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable 
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook, :instagram]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :uid, :provider, :facebook_token, :image, :instagram_token

  def self.find_for_facebook_oauth(auth)
  where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.image = auth.info.image # assuming the user model has an image
    end
  end

  def email_required?
    false
  end

  def self.find_for_instagram_oauth(auth)
  where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.password = Devise.friendly_token[0,20]
      user.email = ""
      user.name = auth.info.name
      # Need to do something for name here as Instagram only has a nickname
      user.image = auth.info.image # assuming the user model has an image
    end
  end

  def facebook_details
    @facebook_details ||= Koala::Facebook::API.new(facebook_token)
  end

  def statuses()
    self.facebook_details.get_connections("me","statuses")
    # if starttime != "" && endtime != ""
    #   raw_statuses.each do |raw_status|
    #   end
    # end
    # if starttime != "" && endtime != ""
    #   #return statuses within date range
    #   return "nothing"
    # else
    #   return @statuses
    # end
  end

  def fb_albums(who = "me")
    albums_fb = self.facebook_details.get_connections("#{who}","albums", :fields => "id, name, count, cover_photo")
    @albums = []
    albums_fb.each do |album|
      cover_photo = album['cover_photo']
      album = { :id => album['id'], :name => album['name'], :count => album['count'], :cover => cover_photo}
      @albums.push(album)
    end
    @albums
  end

  def post_to_wall(comment)
    self.facebook_details.put_wall_post(comment)
  end

  def fb_all_photos
    self.facebook_details.get_connections("me","photos")
  end

  def fb_get_photo(photo_id)
    result = self.facebook_details.get_object("#{photo_id}")
    @picture = result['images'][0]['source'].to_s
  end

  def fb_photos_by_album(album_id)
    self.facebook_details.get_connections("#{album_id}", "photos", :limit => "200",)
  end

  def get_profile_pic(user_id=self.uid)
    self.facebook_details.get_picture("#{user_id}", :type => "large")
  end

  def get_fb_friends
    self.facebook_details.get_connections("me", "friends")
  end

end
