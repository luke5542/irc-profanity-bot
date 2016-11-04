IRC Profanity Bot
===

This bot is designed to be used either inside or outside a Docker environment. Customization is done via the `ircbot.sdl` config file, and example of which is as follows:

```SDL
irc {
    host "irc.rizon.net"
    channels "#susa" "#channel2"
    
    //Optional - default is 6667
    port 6667
    //Optional - default is "ProfanityBot"
    nickname "ProfanityBot"
    //Optional - default is empty
    password "hodor"
}

mariadb {
    host "127.0.0.1"
    user "ircbot"
    password "somemagicalpassword"
}
```

The bot relies on a SQL database connection to store the profanity data, with MariaDB being the recommended software and what is used in the `docker-compose` script.