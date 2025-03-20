#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
CSV="./games.csv"
GAMES_TABLE="games"
TEAMS_TABLE="teams"

if [[ -a $CSV ]]
then
  # reset database
  echo $($PSQL "TRUNCATE $TEAMS_TABLE, $GAMES_TABLE")

  if [ $? -eq 0 ]
  then
    echo Truncate table \'$TEAMS_TABLE\' and \'$GAMES_TABLE\' succesfully!
  else
    echo Error truncating table.
    exit 1
  fi

  cat $CSV | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
  do
    # igore first row
    if [[ $YEAR == 'year' ]]
    then
      continue
    fi

    # insertion for teams
    echo $($PSQL "INSERT INTO $TEAMS_TABLE(name) VALUES('$WINNER') ON CONFLICT (name) DO NOTHING")
    echo $($PSQL "INSERT INTO $TEAMS_TABLE(name) VALUES('$OPPONENT') ON CONFLICT (name) DO NOTHING")

    # get id from teams table
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")

    if [[ -z $WINNER_ID || -z $OPPONENT_ID ]]
    then
      echo "Error: No se encontró el equipo en la base de datos."
      exit 1
    fi

    # insert games
    $PSQL "INSERT INTO $GAMES_TABLE(year, round, winner_id, opponent_id, winner_goals, OPPONENT_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)"
  done

  # display result
  echo "$($PSQL "SELECT * FROM games")"
  echo "$($PSQL "SELECT * FROM teams")"

else
  echo File not found: $CSV
fi
