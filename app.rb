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

  recipe_url = params[:url]
  yum_id = params[:yum_id]
  recipe_title = params[:recipe_name]
  
  if !recipe_url.nil? || !yum_id.nil?
    if recipe_url.nil? || recipe_url.empty?
      recipe_url = 'http://www.yummly.com/recipe/' + yum_id
    end
    puts "Recipe URL : #{recipe_url}"
    
    recipe = get_yummly_recipe yum_id
    puts '*_*_*_*_*_*_*_*_*_*_*_*_*_*_*'
    puts recipe
    puts '-=-=-=-=-=-=-==-=-=-=-=-=-=-='
    
    if recipe_title.nil?
      recipe_title = recipe['name']
    end
    
    puts "Recipe Name : #{recipe_title}"
    #TODO before inserting, search for dupes
  
  	saved_rescipes.insert({
  		recipe_name: recipe_title,
  		url: recipe_url,
  		yummly_id: yum_id
  		})
    @flash_message = 'Your Recipe has been saved'
  else
    @flash_message = 'Unable to save recipe'
  end
  
  #erb :home
end

post '/add_manual' do

  recipe_url = params[:url]
  yum_id = params[:yum_id]
  recipe_title = params[:recipe_name]
  
  if !recipe_url.nil? || !yum_id.nil?
    if recipe_url.nil? || recipe_url.empty?
      recipe_url = 'http://www.yummly.com/recipe/' + yum_id
    end
    puts "Recipe URL : #{recipe_url}"
    if !yum_id.nil?
      recipe = get_yummly_recipe yum_id
      puts '*_*_*_*_*_*_*_*_*_*_*_*_*_*_*'
      puts recipe
      puts '-=-=-=-=-=-=-==-=-=-=-=-=-=-='
      if recipe_title.nil?
        recipe_title = recipe['name']
      end
    end
    
    puts "Recipe Name : #{recipe_title}"
    #TODO before inserting, search for dupes
  
  	saved_rescipes.insert({
  		recipe_name: recipe_title,
  		url: recipe_url,
  		yummly_id: yum_id
  		})
    @flash_message = 'Your Recipe has been saved'
  else
    @flash_message = 'Unable to save recipe'
  end
  
  erb :home
end

post '/dumb' do
  "Dumb Dumb"
end

post '/remove_saved_recipe' do
  
  content_type :json
  id = bson_object_id(params[:id])
  to_remove = saved_rescipes.find_one(id)
  if to_remove
    saved_rescipes.remove(:_id => id)
    @flash_message = 'Successfully Removed' 
  else
    @flash_message = 'Error'
  end
  
  puts @flash_message
  
  "Happy Joy"
  
  #erb :home
  
end

get '/saved' do
  
  @recipes = saved_rescipes.find().to_a
  @result_count = @recipes.count

  erb :saved
  
end

get '/search' do
  searcher = '&q=' + URI.encode(params[:q])

  resp = RestClient.get(yummly_search_api + searcher)

  doc = JSON.parse(resp)
  @recipes = doc['matches']
  @result_count = doc['totalMatchCount']
  @searched_for = params[:q]
  
  erb :search
end

post '/modal_view' do

  yum_id = params[:yum_id]
  
  # just for testing, if no 'yum_id' is passed, simulate one:
  yum_id = '_Home-Schooled_-BBQ-Chicken-Wings-511069' if yum_id.nil? || yum_id.empty?
  
  doc = get_yummly_recipe(yum_id)
  
  @ingredients = doc['ingredientLines']

  erb :modal_recipe, :layout => false
end

def get_yummly_recipe yummly_id 
  
  get_uri = yummly_get_api 
  get_uri = get_uri.sub('[recipe-id]', yummly_id)

  resp = RestClient.get(get_uri)
  JSON.parse(resp)
  
end

helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def bson_object_id val
    BSON::ObjectId.from_string(val)
  end

  def document_by_id id
    id = bson_object_id(id) if String === id
    settings.mongo_db['test'].
      find_one(:_id => id).to_json
  end
end