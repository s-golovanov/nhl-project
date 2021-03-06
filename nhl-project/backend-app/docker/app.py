#!/usr/bin/python3
import mysql.connector, os
from flask import Flask, render_template

db_host = os.environ['DB_HOST']
db_name = os.environ['DB_NAME']
db_user = os.environ['DB_USER']
db_password = os.environ['DB_PASSWORD']

app = Flask(__name__)

@app.route("/")
def index():

            mydb = mysql.connector.connect(host=db_host, port="3306", user=db_user, password=db_password, database=db_name)
            mycursor = mydb.cursor(buffered=True)
            mycursor.execute("SELECT * FROM nhl")
            data = mycursor.fetchall()

            return render_template('index.html',
                               tabledata=data,
                               title="NHL",
                               head="""
    
███████╗███╗   ██╗████████╗███████╗██████╗ ██████╗ ██████╗ ██╗███████╗███████╗     ██████╗███████╗███╗   ██╗████████╗███████╗██████╗ 
██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝    ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
█████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝██████╔╝██████╔╝██║███████╗█████╗      ██║     █████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝
██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔═══╝ ██╔══██╗██║╚════██║██╔══╝      ██║     ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
███████╗██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║██║███████║███████╗    ╚██████╗███████╗██║ ╚████║   ██║   ███████╗██║  ██║
╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝     ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                                                                                                     
                            ███████╗████████╗    ██╗      ██████╗ ██╗   ██╗██╗███████╗                       
                            ██╔════╝╚══██╔══╝    ██║     ██╔═══██╗██║   ██║██║██╔════╝                       
                            ███████╗   ██║       ██║     ██║   ██║██║   ██║██║███████╗                       
                            ╚════██║   ██║       ██║     ██║   ██║██║   ██║██║╚════██║                       
                            ███████║   ██║██╗    ███████╗╚██████╔╝╚██████╔╝██║███████║                       
                            ╚══════╝   ╚═╝╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚══════╝                      
                                                                                                        


                                                                   """
                                )

if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=False)
