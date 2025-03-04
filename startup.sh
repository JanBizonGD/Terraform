#!/bin/bash
echo "<html><body><h1>Server: $(hostname)</h1></body></html>" > /var/www/html/index.html
sudo service apache2 start
