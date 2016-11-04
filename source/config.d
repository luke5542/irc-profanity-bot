import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import core.stdc.stdlib;

import sdlang;

struct IRCConfig
{
    string host;
    string[] channels;
    ushort port;
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
        root = parseFile("./ircbot.sdl");
    }
    catch(ParseException e)
    {
        // Sample error:
        // myFile.sdl(6:17): Error: Invalid integer suffix.
        stderr.writeln("Error parsing SDL - ", e.msg);
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
        if(channelsTag !is null)
        {
            string[] channelStrings = channelsTag.values
                                    .filter!((Value v) => v.type == typeid(string))
                                    .map!((Value v) => v.get!string)
                                    .array();
            if(channelStrings.length == 0)
            {
                stderr.writeln(ircTag.location, ": Error - The 'channels' tag must have string values.");
                exit(1);
            }
            else
            {
                ircCfg.channels = channelStrings;
            }
        }
        else
        {
            stderr.writeln(ircTag.location, ": Error - Must have 'channels' tag with string values.");
            exit(1);
        }
        
        //Now grab the optionals...
        ircCfg.port = to!ushort(ircTag.getTagValue!int("port", 6667));
        ircCfg.nickname = ircTag.getTagValue!string("nickname", "ProfanityBot");
        ircCfg.password = ircTag.getTagValue!string("password", "");
    }
    else
    {
        stderr.writeln(ircTag.location, ": Error - Must have 'irc' tag with 'host' and 'channels' list values.");
        exit(1);
    }
    ircConfig = cast(immutable)ircCfg;
    
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
            mdbCfg.username = mdbTag.expectTagValue!string("user");
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
    dbConfig = cast(immutable)mdbCfg;
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