require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "pry-nav"


# admin_name: admin, admin_password: 2wsx

configure do
  enable :sessions
  set :session_secret, "1qaz"
end


def clear_errors
  @errors = {}
end


def check_login
  unless session[:user_name]
    redirect "/login"
  end
end

def delete_contact(id)
  session[:members].delete_if { |member| member[:id] == id}
end

def next_element_id(arr)
  max = arr.map do |item|
    item[:id]
  end.max || 0
  max + 1
end

def valid(name, phone, email)
  @errors["name"] = "name length must > 1"  unless name.strip.length > 1
  @errors["phone"] = "phone 's format error" if phone.strip.match(/\d+/).to_s.length != 11 
  @errors["email"] = "email 's format error" if email.strip.length < 7
end

before do
  # check_login
  clear_errors
  session[:members] ||= []
  session[:contact_categories] ||= [] 
end

get "/" do
  redirect "/contacts"
end

get "/login" do
  erb :login
end

post "/login" do
  if params[:name] == "admin" && params[:pwd] == "2wsx"
    session[:user_name] = params[:name]
    session[:message] = "login success"
    redirect "/contacts"
  else
    session[:message] = "login failed , please retry"
    redirect "/login"
  end
end

get "/contacts" do
  @categories = session[:contact_categories]

  if params[:category]
    @contact_list = session[:members].select do |member|
      member[:category] == params[:category]
    end
  else
    @contact_list = session[:members]
  end

 erb :index
end

get "/contacts/new" do
  check_login
  erb :new
end

get "/contacts/:id/add_category" do
  id = params[:id].to_i
  @categories = session[:contact_categories]

  if params[:category] && @categories.include?(params[:category])
    @contact = session[:members].select{|member| member[:id] == id}.first
    @contact[:category] = params[:category]
    session[:message] = "add success"
    redirect "/contacts"
  else
    erb :show
  end
end

get "/contacts/:id" do
  @categories= session[:contact_categories]
  id = params[:id].to_i
  @contact = session[:members].select{|member| member[:id] == id}.first
  erb :show
end

post "/contacts" do 
  check_login
  valid(params[:name], params[:phone], params[:email])
  if @errors.empty?
    id = next_element_id(session[:members])
    name = params[:name]
    phone = params[:phone]
    email = params[:email]
    session[:members] << {id: id, name: name, phone: phone, email: email, category: ""}
    session[:message] = "created success"
    redirect "/contacts"
  else
    erb :new
  end
end

post "/contacts/:id/delete" do
  check_login
  id = params[:id].to_i
  delete_contact(id)
  redirect "/contacts"
end

get "/categories/new" do
  erb :cat_new
end

post "/categories" do
  check_login
  # validate
  @category_name = params[:name].strip
  if @category_name != "" && !session[:contact_categories].include?(@category_name)
    session[:contact_categories] << @category_name
    session[:message] = "created success"
  end

  if params[:url] != ""
    redirect params[:url]
  else
    redirect "/contacts"
  end
end

post "/categories/delete" do
  check_login
  category_name = params[:name].strip
  session[:contact_categories].delete(category_name)
  session[:members].each do |member|
    member[:category] = "" if member[:category] == category_name
  end
  session[:message] = "deleted success"
  redirect "/contacts"
end
