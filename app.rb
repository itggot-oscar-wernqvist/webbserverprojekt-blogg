require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions

get('/') do
    slim(:index)
end

get('/login') do
    slim(:login)
end

get('/register') do
    slim(:register)
end

post('/register_attempt') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", params["username"], BCrypt::Password.create(params["password"]))
    session[:logged_in] = true
    session[:username] = params["username"]
    redirect('/')
end