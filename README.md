## swably

Follow the instructions to run the code in development workstation:

	1. Install Mysql and create a MyISAM schema named Swably
	2. Install ImageMagick
	3. Install Ruby 1.9.x and Rails 3.x
	4. Clone the project to a local folder, such as /var/www/swably
	5. Run command "bundle" to install libararies
	6. Run command "rake db:schema:load" to create the data structure
	7. create 4 folders: /public/apks, /public/pictures, /public/feeds, /public/downloads
	8. Run command "rails server" to launch the site
	9. Open localhost:3000 in browser to test

Follow the instructions to deploy on server (e.g. CentOS 6.x) :

	1. Follow the above instructions 1-8 on the server to make sure the code works locally on server
	2. Install Apache 2.x
	3. Install Phusion Passenger and make it work with Apache
	4. Modify httpd.conf, add the following configuration:
	
		<VirtualHost *:80>
      			ServerName zh.swably.com
      			# !!! Be sure to point DocumentRoot to 'public'!
      			DocumentRoot /var/www/swably/public
      			<Directory /var/www/swably/public>
         			# This relaxes Apache security settings.
         			AllowOverride all
         			# MultiViews must be turned off.
         			Options -MultiViews
      			</Directory>
   		</VirtualHost>

		<Files *.apk>
  			ForceType application/octet-stream
  			Header set Content-disposition "attachment"
		</Files>

