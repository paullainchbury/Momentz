class Musictrack < ActiveRecord::Base
  belongs_to :event
  attr_accessible :src, :title, :type
end
