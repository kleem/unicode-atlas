coffee -c data data
coffee -c server server

coffee -c client/vis client/vis
sass --force --update client/vis:client/vis --style expanded
sass --force --update client/fonts:client/fonts --style expanded
coffee -c client/static/gencat client/static/gencat
sass --force --update client/static/gencat:client/static/gencat --style expanded
coffee -c client/static/gencat1 client/static/gencat1
sass --force --update client/static/gencat1:client/static/gencat1 --style expanded

coffee -c common server
coffee -c common client