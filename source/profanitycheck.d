import std.array;
import std.file;
import std.stdio;
import std.uni;
import std.string;

import vibeirc.data;
import dbmanager;

string[string] profanity;

immutable PROFANITY_FILE = "./public/profanity.txt";

shared static this()
{
    assert(exists(PROFANITY_FILE));
    auto words = readText(PROFANITY_FILE).split("\n");
    
    foreach(word; words)
    {
        profanity[word] = word;
    }
}

bool parseMessageProfanity(Message message) {
    bool profanityFound = false;
    /*auto messageWords = message.message.split();
    foreach(word; messageWords)
    {
        if(word.toLower() in profanity) {
            writeln("Found profanity: ", word);
            profanityFound = true;
        }
    }*/
    
    foreach(word; profanity)
    {
        if(indexOf(message.message, word, CaseSensitive.no) >= 0)
        {
            writeln("Found profanity: ", word);
            profanityFound = true;
            if(!storeProfanityUsage(message.sender.nickname, word))
            {
                writeln("Error storing message to database.");
            }
            else
            {
                writeln("Successfully stored message to database.");
            }
        }
    }
    
    return profanityFound;
}