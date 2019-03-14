require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions

get('/') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT posts.post_id, posts.title, posts.content, posts.timestamp, posts.user_id, users.username FROM posts INNER JOIN users ON users.user_id = posts.user_id").reverse
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
        db = SQLite3::Database.new("db/blog.db")
        db.results_as_hash = true
        result = db.execute("SELECT posts.post_id, posts.title FROM posts WHERE posts.user_id = ?", session[:user_id])
        slim(:admin, locals:{
            posts: result
        })
    else
        redirect('/login')
    end
end

get('/user/:id') do
    db = SQLite3::Database.new("db/blog.db")
    db.results_as_hash = true
    result = db.execute("SELECT posts.post_id, posts.title, posts.content, posts.timestamp, posts.user_id, users.username FROM posts INNER JOIN users ON users.user_id = posts.user_id WHERE users.user_id = ?", params["id"])
    slim(:user, locals:{
        posts: result
    })
end

post('/create_post') do
    db = SQLite3::Database.new("db/blog.db")
    time = Time.now.asctime
    db.execute("INSERT INTO posts (title, content, user_id, timestamp) VALUES (?,?,?,?)", params["title"], params["content"], session[:user_id], time)
    redirect('/')
end

post('/delete_post') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("DELETE FROM posts WHERE post_id = ?", params["post_id"])
    redirect('/')
end

get('/edit_post/:id') do
    db = SQLite3::Database.new("db/blog.db")
    post_creator = db.execute("SELECT posts.user_id FROM posts WHERE posts.post_id = ?", params["id"])
    if session[:user_id] == post_creator
        slim(:edit_post)
    else
        redirect('/login')
    end
end

post('/edit_post_attempt') do
    db = SQLite3::Database.new("db/blog.db")
    db.execute("UPDATE posts SET title = ?, content = ? WHERE post_id = ?", params["title"], params["content"], params["post_id"])
    redirect('/')
end