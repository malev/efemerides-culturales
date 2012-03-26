$: << "."

require "sinatra"
require 'koala'
require 'logger'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'event'
require 'user'
require 'parser'
require 'mongoid'

enable :sessions

set :raise_errors, false
set :show_exceptions, false
set :logging, :true

configure do
  Log = Logger.new("log/efemerides.log")
  Log.level  = Logger::INFO

  config = YAML.load_file("config/mongoid.yml")
  host =          config['development']['host']
  port =          config['development']['port']
  database_name = config['development']['database']
  username =      config['development']['username']
  password =      config['development']['password']

  Mongoid.database = Mongo::Connection.new(host, port, :logger => Logger.new($stdout)).db(database_name)
  auth = Mongoid.database.authenticate(username, password)
  Mongoid.logger = Log
end

# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
FACEBOOK_SCOPE = 'user_likes,user_photos,user_photo_video_tags,user_birthday'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
  redirect '/guest' unless session[:access_token]

  @graph  = Koala::Facebook::API.new(session[:access_token])
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])
  @events = []

  @user = @graph.get_object("me")

  if @user['birthday']
    birth   = @user['birthday'].split("/")
    @events  = Event.search(birth[0], birth[1])
  end

  @friends = @graph.get_connections('me', 'friends')
  @photos  = @graph.get_connections('me', 'photos')
  @likes   = @graph.get_connections('me', 'likes')

  if User.where(:facebook_id => @user['id']).count == 0
    @storable_user = User.parse(@user)
    @storable_user.likes = @likes
    @storable_user.friends = @friends
    @storable_user.photos = @photos
    @storable_user.save
  end

  # for other data you can always run fql
  @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1")

  erb :index
end

get "/guest" do
  redirect '/' if session[:access_token]
  @graph  = Koala::Facebook::API.new(session[:access_token])
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  erb :guest
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

post "/guest" do
  redirect "/guest"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

get "/sign_out" do
  session[:access_token] = nil
  redirect '/'
end

get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
	session[:access_token] = authenticator.get_access_token(params[:code])
	redirect '/'
end
