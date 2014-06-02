require 'sinatra'
require 'mongo'
require 'rest_client'

#set to port 3000 if not running shotgun
set :bind, '0.0.0.0' 
set :port, 3000 

mongo 	= Mongo::MongoClient.new
db 		= mongo['rescipe']
saved_rescipes	= db['saved_rescipes']

def yummly_search_api
  $yummly_search_api ||= 'http://api.yummly.com/v1/api/recipes?_app_id=71efecf4&_app_key=466b1c65886c56ff6b81a9d77dbf6fa6'
end

def yummly_get_api
  $yummly_get_api ||= 'http://api.yummly.com/v1/api/recipe/[recipe-id]?_app_id=71efecf4&_app_key=466b1c65886c56ff6b81a9d77dbf6fa6'
end

get '/' do
  erb :home
end

#
# Enhancements :
# record in mongodb should have many elements from Hungry API
# when "manual" link is added, parse to see if it is a yumly link
#   if it is, then parse & grab the ID, then use API to pull back extra elements
#

post '/add' do
  #can this be changed to ajax?
  recipe_url = params[:url]
  yum_id = params[:id]
  if !recipe_url.nil? || !yum_id.nil?
    if recipe_url.nil? || recipe_url.empty?
      recipe_url = 'http://www.yummly.com/recipe/' + yum_id
    end
  
    #before inserting, search for dupes
  
  	saved_rescipes.insert({
  		recipe_name: params[:recipe_name],
  		url: recipe_url,
  		yummly_id: yum_id
  		})
    @flash_message = 'Your Recipe has been saved'
  else
    @flash_message = 'Unable to save recipe'
  end
  
  erb :home
end

get '/search' do
  searcher = '&q=' + URI.encode(params[:q])

  resp = RestClient.get(yummly_search_api + searcher)

  doc = JSON.parse(resp)
  @recipes = doc['matches']
  @result_count = doc['totalMatchCount']
  @searched_for = params[:q]
  #puts @recipes
  erb :search
end

post '/modal_view' do
  puts 'modal view called'
  yum_id = params[:yum_id]
  
  # just for testing, if no 'yum_id' is passed, simulate one:
  yum_id = '_Home-Schooled_-BBQ-Chicken-Wings-511069' if yum_id.nil? || yum_id.empty?

  get_uri = yummly_get_api 
  get_uri.sub!('[recipe-id]', yum_id)

  resp = RestClient.get(get_uri)
  doc = JSON.parse(resp)
  
  @ingredients = doc['ingredientLines']

  erb :modal_recipe, :layout => false
end
