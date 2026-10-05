#!/bin/bash

PSQL=(psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c)
secret_number=$((RANDOM % 1000 + 1))

printf 'Enter your username: '
IFS= read -r username
username_sql=${username//\'/\'\'}

user_stats=$("${PSQL[@]}" "SELECT games_played || '|' || best_game FROM users WHERE username = '$username_sql';") || exit 1

if [[ -z $user_stats ]]; then
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
else
  IFS='|' read -r games_played best_game <<< "$user_stats"
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' \
    "$username" "$games_played" "$best_game"
fi

printf 'Guess the secret number between 1 and 1000: '

guess_count=0
won=0
while IFS= read -r guess; do
  guess_count=$((guess_count + 1))

  if [[ ! $guess =~ ^[0-9]+$ ]]; then
    printf 'That is not an integer, guess again: '
  elif ((10#$guess < secret_number)); then
    printf "It's higher than that, guess again: "
  elif ((10#$guess > secret_number)); then
    printf "It's lower than that, guess again: "
  else
    won=1
    break
  fi
done

((won)) || exit 1
"${PSQL[@]}" "INSERT INTO users (username, games_played, best_game)
VALUES ('$username_sql', 1, $guess_count)
ON CONFLICT (username) DO UPDATE
SET games_played = users.games_played + 1,
    best_game = LEAST(users.best_game, EXCLUDED.best_game);" || exit 1

printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' \
  "$guess_count" "$secret_number"
