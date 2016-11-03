import std.stdio;
import std.c.process;

import sdlang;

struct IRCConfig
{
    string host;
    string[] channels;
    int port;
    string nickname;
    string password;
}
immutable IRCConfig ircConfig;


struct MariaDBConfig
{
    string host;
    string username;
    string password;
}
immutable MariaDBConfig dbConfig;

shared static this()
{
    //Read in the config file and store a read-only version of the object.
    Tag root;
    try
    {
        root = parseSource("./ircbot.sdl");
    }
    catch(ParseException e)
    {
        // Sample error:
        // myFile.sdl(6:17): Error: Invalid integer suffix.
        stderr.writeln(e.msg);
        exit(1);
    }
    
    IRCConfig ircCfg;
    Tag ircTag = root.getTag("irc");
    if(ircTag !is null)
    {
        //Attempt to grab the host
        try
            ircCfg.host = ircTag.expectTagValue!string("host");
        catch(ValueNotFoundException e)
        {
            stderr.writeln(ircTag.location, ": Error - 'irc' requires a string tag value of 'host'");
            exit(1);
        }
    
        //Attempt to grab the channels
        Tag channelsTag = ircTag.getTag("channels");
        if(channelsTag != null)
        {
            string[] channelStrings = channelsTag.values
                                    .filter!((Value v) => v.type == typeid(string))
                                    .map!((Value v) => v.get!string);
            if(channelStrings.length == 0)
            {
                stderr.writeln(mdbTag.location, ": Error - The 'channels' tag must have string values.");
                exit(1);
            }
            else
            {
                ircCfg.channels = channelStrings;
            }
        }
        else
        {
            stderr.writeln(mdbTag.location, ": Error - Must have 'channels' tag with string values.");
            exit(1);
        }
        
        //Now grab the optionals...
        ircCfg.port = ircTag.getTagValue!int("port", 6667);
        ircCfg.port = ircTag.getTagValue!string("nickname", "ProfanityBot");
        ircCfg.port = ircTag.getTagValue!string("password", "");
    }
    else
    {
        stderr.writeln(mdbTag.location, ": Error - Must have 'irc' tag with 'host' and 'channels' list values.");
        exit(1);
    }
    ircConfig = ircCfg;
    
    MariaDBConfig mdbCfg;
    Tag mdbTag = root.getTag("mariadb");
    if(mdbTag !is null)
    {
        //Attempt to grab the host
        try
            mdbCfg.host = mdbTag.expectTagValue!string("host");
        catch(ValueNotFoundException e)
        {
            stderr.writeln(mdbTag.location, ": Error - 'mariadb' requires a string tag value of 'host'");
            exit(1);
        }
        
        //Attempt to grab the user
        try
            mdbCfg.user = mdbTag.expectTagValue!string("user");
        catch(ValueNotFoundException e)
        {
            stderr.writeln(mdbTag.location, ": Error - 'mariadb' requires a string tag value of 'user'");
            exit(1);
        }
        
        //Attempt to grab the password
        try
            mdbCfg.password = mdbTag.expectTagValue!string("password");
        catch(ValueNotFoundException e)
        {
            stderr.writeln(mdbTag.location, ": Error - 'mariadb' requires a string tag value of 'password'");
            exit(1);
        }
    }
    else
    {
        stderr.writeln(mdbTag.location, ": Must have 'mariadb' tag with 'host', 'user' and 'password' values.");
        exit(1);
    }
    dbConfig = mdbCfg;
}

/*
Sample SDL file:

irc {
    host "irc.rizon.net"
    channels "#lelandcs"
    
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

*/