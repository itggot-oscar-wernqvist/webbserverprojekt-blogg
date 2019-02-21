require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions

get('/') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT posts.post_id, posts.title, posts.content, posts.timestamp, users.username FROM posts INNER JOIN users ON users.user_id = posts.user_id")
    p result
    slim(:index, locals:{
        posts: result
    })
end

get('/login') do
    slim(:login)
end

post('/login_attempt') do
    db = SQLite3::Database.new("db/blog.db")
    password_hash = db.execute("SELECT users.password_hash FROM users WHERE users.username = ?", params["username"])
    user_id = db.execute("SELECT users.user_id FROM users WHERE users.username = ?", params["username"]) 
    p password_hash
    p params["password"]
    if password_hash.length > 0 && BCrypt::Password.new(password_hash[0][0]).==(params["password"])
        session[:logged_in] = true
        session[:username] = params["username"]
        session[:user_id] = user_id
        redirect('/admin')
    else
        session[:logged_in] = false
        redirect('/login')
    end    
end


get('/logout') do
    session.clear
    redirect('/')
end

get('/register') do
    slim(:register)
end

post('/register_attempt') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", params["username"], BCrypt::Password.create(params["password"]))
    redirect('/login')
end

get('/admin') do
    if session[:logged_in] == true
        slim(:admin)
    else
        redirect('/login')
    end
end

post('/create_post') do
    db = SQLite3::Database.new("db/blog.db")
    time = Time.now.asctime
    p time
    db.execute("INSERT INTO posts (title, content, user_id, timestamp) VALUES (?,?,?,?)", params["title"], params["content"], session[:user_id], time)
    redirect('/')
end