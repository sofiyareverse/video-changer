Welcome to video changer project! Here is a little instruction to test it.

1) Install ruby 2.5.1; install MongoDB and create new db for user.

2) Clone project and configurate invironment: 
  1. In terminal:
    git clone git@github.com:sofiyareverse/video-changer.git
    
    cd ~/video-changer
    
    apt-get install redis / yum install redis / emerge -av redis
    
    bundle install
  
  2. Open mongoid.config and add new db name to this field 'database: '.

3) Run redis, sidekiq to perform background tasks and run the server:

  service redis start / /etc/init.d/redis start
  
  bundle exec rackup
  
  bundle exec sidekiq -r ./server.rb
  
  bundle exec ruby server.rb
