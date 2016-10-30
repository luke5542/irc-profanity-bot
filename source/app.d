/*import vibe.d;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void hello(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody("Hello, World!");
}*/

/++
    Connects to a server and joins all specified channels.
    Logs all events that occur to stdout.
+/
import core.time;
import std.functional;
import std.stdio;
import std.string;
import std.conv;

import vibe.d;
import vibeirc;

import profanitycheck;
import dbmanager;

IRCClient bot;
string host = "irc.rizon.net";;
string nickname = "ProfanityBot";
string password;
string[] channels = ["#lelandcs"];
ushort port = 6667;

shared static this()
{
    bot = new IRCClient;
    bot.nickname = nickname;
    bot.onDisconnect = toDelegate(&onDisconnect);
    bot.onLogin = toDelegate(&onLogin);
    bot.onMessage = toDelegate(&onMessage);
    bot.onNotice = toDelegate(&onMessage);
    bot.onUserJoin = toDelegate(&onUserJoin);
    bot.onUserPart = toDelegate(&onUserPart);
    bot.onUserQuit = toDelegate(&onUserQuit);
    bot.onUserRename = toDelegate(&onUserRename);
    bot.onUserKick = toDelegate(&onUserKick);
    
    //defer connection until after arguments have been processed
    runTask(toDelegate(&connect));
}

void connect()
{
    bot.connect(host, port, password);
}

void sendMessage(string message)
{
	bot.send(channels[0], message);
}

/*
 * Returns true iff the message contained a valid command.
 * Otherwise, it returns false.
 */
bool parseCommand(Message message)
{
    if(message.message[0] != '!')
    {
        return false;
    }
    if(indexOf(message.message, "!ProfanityHelp") == 0)
    {
        string messageToSend = "The available commands are:"
        ~ "\n!ProfanityHelp - display this message."
        ~ "\n!FoulestMouth  - get the worst offender and their favorite word."
        ~ "\n!TopOffenses   - list the 5 most commonly used offensive words."
        ~ "\n!MyOffenses    - list your personal stats, with your top 5 most offensive words."
    }
	else if(indexOf(message.message, "!FoulestMouth") == 0)
    {
        auto foulest = getFoulestMouth();
        if(!foulest.isNull)
        {
            string messageToSend = foulest[0].nickname ~ " has uttered " ~ to!string(foulest[0].total_offenses) ~
            " horrible things. Their favorite offense is: " ~ foulest[1].foul_word ~
            ", which they uttered " ~ to!string(foulest[1].total_uses) ~ " times.";
            sendMessage(messageToSend);
            return true;
        }
    }
    else if(indexOf(message.message, "!TopOffenses") == 0)
    {
        auto offenses = getMostCommonOffenses();
        if(offenses != null)
        {
            string messageToSend = "The most common offenses are:";
            foreach(word; offenses)
            {
                messageToSend = messageToSend ~ "\n" ~ word.foul_word ~ ": " ~ to!string(word.total_uses);
            }
            sendMessage(messageToSend);
            return true;
        }
    }
    else if(indexOf(message.message, "!MyOffenses") == 0)
    {
        auto user = getUser(message.sender);
        auto offenses = getMyOffenses(message.sender);
        if(offenses != null)
        {
            if(offenses.length != 0)
            {
                string messageToSend;
                if(!user.isNull)
                {
                    messageToSend = messageToSend ~ "Stats for " ~ user.nickname ~ ":";
                    messageToSend = messageToSend ~ "\nTotal Offenses - " ~ user.total_offenses;
                    messageToSend = messageToSend ~ "\nThis Year's Offenses - " ~ user.year_offenses;
                    messageToSend = messageToSend ~ "\nThis Month's Offenses - " ~ user.month_offenses;
                    messageToSend = messageToSend ~ "\nThis Week's Offenses - " ~ user.week_offenses;
                }
                
                messageToSend = messageToSend ~ "\nYour top offenses are:";
                foreach(word; offenses)
                {
                    messageToSend = messageToSend ~ "\n" ~ word.foul_word ~ ": " ~ to!string(word.total_uses);
                }
                sendMessage(messageToSend);
                return true;
            }
        }
    }
    
    
	return false;
}

void onDisconnect(string reason)
{
    writeln("Disconnected: ", reason);
    sleep(10.seconds);
    writeln("Attempting to reconnect");
    connect;
}

void onLogin()
{
    writeln("Logged in");
    
    foreach(channel; channels)
    {
        writeln("Joining ", channel);
        bot.join(channel);
    }
}

void onMessage(Message message)
{
    string bodyFormat;
    string bracketText;
    
    if(message.isCTCP)
    {
        if(message.ctcpCommand != "ACTION")
        {
            writefln(
                "%s sends CTCP %s",
                message.sender.nickname,
                message.ctcpCommand,
            );
            
            return;
        }
        
        bodyFormat = "* %s %s";
    }
    else
        bodyFormat = "<%s> %s";
    
    if(message.target == bot.nickname)
        bracketText = "Private Message";
    else
        bracketText = message.target;
    
    writefln(
        "[%s] " ~ bodyFormat,
        bracketText,
        message.sender.nickname,
        message.message,
    );
	
	if(!parseCommand(message))
		if(parseMessageProfanity(message))
        	sendMessage(message.sender.nickname ~ ", wash your mouth of that filth!");
}

void onUserJoin(User user, string channel)
{
    writefln(
        "[%s] %s joined",
        channel,
        user.nickname,
    );
}

void onUserPart(User user, string channel, string reason)
{
    writefln(
        "[%s] %s left (%s)",
        channel,
        user.nickname,
        reason == null ? "No reason given" : reason,
    );
}

void onUserQuit(User user, string reason)
{
    writefln(
        "%s quit (%s)",
        user.nickname,
        reason == null ? "No reason given" : reason,
    );
}

void onUserRename(User user, string newNick)
{
    writefln(
        "%s is now known as %s",
        user.nickname,
        newNick,
    );
}

void onUserKick(User kicker, string kickee, string channel, string reason)
{
    writefln(
        "[%s] %s kicked %s (%s)",
        channel,
        kicker.nickname,
        kickee,
        reason == null ? "No reason given" : reason,
    );
}
