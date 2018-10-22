require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

not_found do
  session[:error] = "The page you requested does not exists."
  redirect "/"
end

get "/" do
  erb :home
end

get "/signin" do
  erb :signin
end

def check_if_user_signedin
  unless session[:username]
    session[:error] = "You must be signed in to access that page."
    redirect "/"
  end
end

get "/signup" do
  erb :signup
end

get "/contacts" do
  check_if_user_signedin
  @contacts = session[:contacts]
  erb :contacts
end

get "/contacts/add" do
  erb :add
end

get "/contacts/:id" do
  id = params[:id].to_i
  check_if_user_signedin
  if id.to_s.match(/[0-9]{1,}/) && session[:contacts][id]
    @contact = session[:contacts][id]

    erb :contact
  else
    session[:error] = "The page you requested does not exists."
    redirect "/"
  end
end

get "/contacts/:id/edit" do
  check_if_user_signedin
  id = params[:id].to_i
  @contact = session[:contacts][id]

  erb :edit
end

def credentials_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yaml", __FILE__)
  else
    File.expand_path("../users.yaml", __FILE__)
  end
end

def load_credentials
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_credentials
  if credentials.key?(username)
    bcrypt_password = credentials[username]["password"]
    BCrypt::Password.new(bcrypt_password) == password
  else
    false
  end
end

post "/users/signin" do
  username = params[:username]
  password = params[:password]
  if valid_credentials?(username, password)
    session[:success] = "You are logged in as #{username}."
    credentials = load_credentials
    session[:contacts] = credentials[username]["contacts"]
    session[:username] = username
    redirect "/"
  else
    session[:error] = "You entered the wrong username and/or password"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  check_if_user_signedin
  session.delete(:username)
  session.delete(:contacts)
  session[:success] = "You are signed out."
  redirect "/"
end

post "/signup" do
  username = params[:username]
  password = params[:password]
  credentials = load_credentials
  if credentials.key?(username)
    session[:error] = "username already exists. Please choose another user name."
    status 422
    erb :signup
  else
    bcrypt_password = BCrypt::Password.create(password)
    credentials[username] = { "password" => bcrypt_password, "contacts" => {} }
    File.open(credentials_path, "w") { |file| file.write(credentials.to_yaml) }  

    credentials = load_credentials
    session[:contacts] = credentials[username]["contacts"]
    session[:success] = "You are signed up."
    session[:username] = username
    redirect "/"
  end
end

def empty_inputs?
  params.any? { |_, info| info.empty? }
end

def invalid_house_number?
  !params[:housenumber].match(/^[0-9]{1,}$/)
end

def invalid_street?
  !params[:street].match(/^[A-Za-z]{1,}\s?([a-zA-Z]{1,})+$/)
end

def invalid_postalcode?
  !params[:postalcode].match(/^[1-9]{1}[0-9]{3}\s?[a-zA-Z]{2}$/)
end

def invalid_city?
  !params[:city].match(/^[A-Za-z]+$/)
end

def invalid_phonenumber?
  !params[:phonenumber].match(/^(\+316|06)[0-9]{8}$/)
end

def invalid_email?
  !params[:email].match(/^[a-zA-Z0-9\.\-\_]{1,}@[a-zA-Z0-9]{1,}\.[a-z]{1,}$/)
end

def check_for_errors
  if empty_inputs?
    "One or more input fiels are emtpy. All fields are mandatory to fill in."
  elsif invalid_house_number?
    "House number must only contain digits."
  elsif invalid_street?
    "Street name can only contain letters and spaces."
  elsif invalid_postalcode?
    "Postal code must contain 4 digits and 2 letters."
  elsif invalid_city?
    "City must contain only letters."
  elsif invalid_phonenumber?
    "Phone number must start with +31 or 06 and must consist of 10 digits."
  elsif invalid_email?
    "Invalid input for email."
  end
end

def next_contact_id(contacts)
  max = contacts.keys.max || 0
  max + 1
end

def create_new_contact
  { name: params[:name], street: params[:street], housenumber: params[:housenumber],
    postalcode: params[:postalcode], city: params[:city],
    phonenumber: params[:phonenumber], email: params[:email] }
end

post "/contacts/create" do 
  check_if_user_signedin
  error = check_for_errors
  if error
    session[:error] = error
    status 422
    erb :add
  else
    contacts = session[:contacts]
    id = next_contact_id(contacts)
    new_contact = create_new_contact
    credentials = load_credentials
    credentials[session[:username]]["contacts"][id] = new_contact
    
    File.open(credentials_path, "w") { |file| file.write(credentials.to_yaml) }

    credentials = load_credentials
    session[:contacts] = credentials[session[:username]]["contacts"]
    session[:success] = "#{new_contact[:name]} has been added to your contact list."
    redirect "/contacts"
  end
end

def update_contact(contact)
  contact[:name] = params[:name]
  contact[:street] = params[:street]
  contact[:housenumber] = params[:housenumber]
  contact[:postalcode] = params[:postalcode]
  contact[:city] = params[:city]
  contact[:phonenumber] = params[:phonenumber]
  contact[:email] = params[:email]
end

post "/contacts/:id/update" do
  check_if_user_signedin
  error = check_for_errors
  if error
    status 422
    session[:error] = error
    erb :edit
  else
    id = params[:id].to_i
    contact = session[:contacts][id]
    update_contact(contact)

    credentials = load_credentials
    credentials[session[:username]]["contacts"][id] = contact
    File.open(credentials_path, "w") { |file| file.write(credentials.to_yaml) }

    credentials = load_credentials
    session[:contacts] = credentials[session[:username]]["contacts"]
    session[:success] = "info for #{contact[:name]} has been changed."
    redirect "/contacts/#{id}"
  end
end

post "/contacts/:id/delete" do
  check_if_user_signedin
  id = params[:id].to_i
  credentials = load_credentials
  credentials[session[:username]]["contacts"].delete(id)
  File.open(credentials_path, "w") { |file| file.write(credentials.to_yaml) }

  credentials = load_credentials
  session[:contacts] = credentials[session[:username]]["contacts"]
  session[:success] = "Contact has been deleted from the contact list."
  redirect "/contacts"
end
