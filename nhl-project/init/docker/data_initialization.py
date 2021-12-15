#!/usr/bin/python3
import requests, datetime, mysql.connector, os
from datetime import date, timedelta

db_host = os.environ['DB_HOST']
db_name = os.environ['DB_NAME']
db_user = os.environ['DB_USER']
db_password = os.environ['DB_PASSWORD']

last_day_of_prev_month = date.today().replace(day=1) - timedelta(days=1)
start_day_of_prev_month = date.today().replace(day=1) - timedelta(days=last_day_of_prev_month.day)

main_url = requests.get('https://statsapi.web.nhl.com/api/v1/schedule?startDate=' + str(start_day_of_prev_month) + '&endDate=' + str(last_day_of_prev_month))
sched_data = main_url.json()

if main_url.status_code == 200:
    print(main_url, 'Cool, NHL API is available')

    try:
        mydb = mysql.connector.connect(host=db_host, port="3306", user=db_user, password=db_password, database=db_name)
        mycursor = mydb.cursor(buffered=True)
        mycursor.execute("DROP TABLE IF EXISTS nhl")
        mycursor.execute("CREATE TABLE nhl (id INT AUTO_INCREMENT PRIMARY KEY, gametime VARCHAR(100), hometeam VARCHAR(100), homegoals VARCHAR(100), awayteam VARCHAR(100), awaygoals VARCHAR(100), top1 VARCHAR(100), top1toi VARCHAR(100), top2 VARCHAR(100), top2toi VARCHAR(100), top3 VARCHAR(100), top3toi VARCHAR(100))")

        for date in sched_data['dates']:

            for game in date['games']:

                if game['venue'].get('name') == "Enterprise Center" and game['status'].get('detailedState') == "Final":

                    game_url = requests.get('https://statsapi.web.nhl.com' + game['link'])
                    game_data = game_url.json()

                    dict_stat = {}

                    for player in game_data['liveData']['boxscore']['teams']['home']['players']:

                        try:
                            m, s = game_data['liveData']['boxscore']['teams']['home']['players'][player]['stats']['skaterStats']['timeOnIce'].split(':')
                            dict_stat[game_data['liveData']['boxscore']['teams']['home']['players'][player]['person']['id']] = int(datetime.timedelta(minutes=int(m), seconds=int(s)).total_seconds())

                        except:
                            try:
                                m, s = game_data['liveData']['boxscore']['teams']['home']['players'][player]['stats']['goalieStats']['timeOnIce'].split(':')
                                dict_stat[game_data['liveData']['boxscore']['teams']['home']['players'][player]['person']['id']] = int(datetime.timedelta(minutes=int(m), seconds=int(s)).total_seconds())
                            except:
                                dict_stat[game_data['liveData']['boxscore']['teams']['home']['players'][player]['person']['id']] = 0

                    for player in game_data['liveData']['boxscore']['teams']['away']['players']:

                        try:
                            m, s = game_data['liveData']['boxscore']['teams']['away']['players'][player]['stats']['skaterStats']['timeOnIce'].split(':')
                            dict_stat[game_data['liveData']['boxscore']['teams']['away']['players'][player]['person']['id']] = int(datetime.timedelta(minutes=int(m), seconds=int(s)).total_seconds())

                        except:
                            try:
                                m, s = game_data['liveData']['boxscore']['teams']['away']['players'][player]['stats']['goalieStats']['timeOnIce'].split(':')
                                dict_stat[game_data['liveData']['boxscore']['teams']['away']['players'][player]['person']['id']] = int(datetime.timedelta(minutes=int(m), seconds=int(s)).total_seconds())
                            except:
                                dict_stat[game_data['liveData']['boxscore']['teams']['away']['players'][player]['person']['id']] = 0

                    top_players = sorted(dict_stat, key=dict_stat.get, reverse=True)[:3]

                    print(game_data['gameData']['datetime']['dateTime'])
                    print(game_data['liveData']['linescore']['teams']['home']['team']['name'])
                    print(game_data['liveData']['linescore']['teams']['home']['goals'])
                    print(game_data['liveData']['linescore']['teams']['away']['team']['name'])
                    print(game_data['liveData']['linescore']['teams']['away']['goals'])
                    print(game_data['gameData']['players']['ID' + str(top_players[0])]['fullName'])
                    print(str(datetime.timedelta(seconds=dict_stat[top_players[0]])))
                    print(game_data['gameData']['players']['ID' + str(top_players[1])]['fullName'])
                    print(str(datetime.timedelta(seconds=dict_stat[top_players[1]])))
                    print(game_data['gameData']['players']['ID' + str(top_players[2])]['fullName'])
                    print(str(datetime.timedelta(seconds=dict_stat[top_players[2]])))


                    insert = "INSERT INTO nhl (gametime, hometeam, homegoals, awayteam, awaygoals, top1, top1toi, top2, top2toi, top3, top3toi ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
                    val = (
                        game_data['gameData']['datetime']['dateTime'],
                        game_data['liveData']['linescore']['teams']['home']['team']['name'],
                        game_data['liveData']['linescore']['teams']['home']['goals'],
                        game_data['liveData']['linescore']['teams']['away']['team']['name'],
                        game_data['liveData']['linescore']['teams']['away']['goals'],
                        game_data['gameData']['players']['ID' + str(top_players[0])]['fullName'],
                        str(datetime.timedelta(seconds=dict_stat[top_players[0]])),
                        game_data['gameData']['players']['ID' + str(top_players[1])]['fullName'],
                        str(datetime.timedelta(seconds=dict_stat[top_players[1]])),
                        game_data['gameData']['players']['ID' + str(top_players[2])]['fullName'],
                        str(datetime.timedelta(seconds=dict_stat[top_players[2]])),
                    )
                    mycursor.execute(insert, val)
                    mydb.commit()

        mycursor.execute("SELECT * FROM nhl")
        result = mycursor.fetchall()
        print(result)
        mydb.close()

    except:
        print('Can not write to DB, check parameters of the app and DB availability')

else:
    print('NHL API is not available, check connection')
