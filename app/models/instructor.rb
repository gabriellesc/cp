require 'net/http'
class Instructor < ActiveResource::Base
  self.site = "http://#{ENV['TAPP']}:3000/"
  def json
    JSON.parse(self.to_json, symbolize_names: true)
  end
end
