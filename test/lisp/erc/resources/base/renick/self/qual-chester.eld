;; -*- mode: lisp-data; -*-
((pass 1 "PASS :changeme"))
((nick 1 "NICK chester"))
((user 1 "USER user 0 * :chester")
 (0 ":irc.foonet.org 001 chester :Welcome to the foonet IRC Network chester")
 (0 ":irc.foonet.org 002 chester :Your host is irc.foonet.org, running version oragono-2.6.0-7481bf0385b95b16")
 (0 ":irc.foonet.org 003 chester :This server was created Sun, 13 Jun 2021 05:45:20 UTC")
 (0 ":irc.foonet.org 004 chester irc.foonet.org oragono-2.6.0-7481bf0385b95b16 BERTZios CEIMRUabefhiklmnoqstuv Iabefhkloqv")
 (0 ":irc.foonet.org 005 chester AWAYLEN=390 BOT=B CASEMAPPING=ascii CHANLIMIT=#:100 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 CHANTYPES=# ELIST=U EXCEPTS EXTBAN=,m FORWARD=f INVEX KICKLEN=390 :are supported by this server")
 (0 ":irc.foonet.org 005 chester MAXLIST=beI:60 MAXTARGETS=4 MODES MONITOR=100 NETWORK=foonet NICKLEN=32 PREFIX=(qaohv)~&@%+ STATUSMSG=~&@%+ TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 TOPICLEN=390 UTF8MAPPING=rfc8265 UTF8ONLY WHOX :are supported by this server")
 (0 ":irc.foonet.org 005 chester draft/CHATHISTORY=100 :are supported by this server")
 (0 ":irc.foonet.org 251 chester :There are 0 users and 3 invisible on 1 server(s)")
 (0 ":irc.foonet.org 252 chester 0 :IRC Operators online")
 (0 ":irc.foonet.org 253 chester 1 :unregistered connections")
 (0 ":irc.foonet.org 254 chester 1 :channels formed")
 (0 ":irc.foonet.org 255 chester :I have 3 clients and 0 servers")
 (0 ":irc.foonet.org 265 chester 3 4 :Current local users 3, max 4")
 (0 ":irc.foonet.org 266 chester 3 4 :Current global users 3, max 4")
 (0 ":irc.foonet.org 422 chester :MOTD File is missing"))

((mode-user 10 "MODE chester +i")
 (0 ":irc.foonet.org 221 chester +i")
 (0 ":irc.foonet.org NOTICE chester :This server is in debug mode and is logging all user I/O. If you do not wish for everything you send to be readable by the server owner(s), please disconnect."))

((join 14 "JOIN #chan")
 (0 ":chester!~u@yuvqisyu7m7qs.irc JOIN #chan")
 (0 ":irc.foonet.org 353 chester = #chan :tester chester @alice bob")
 (0 ":irc.foonet.org 366 chester #chan :End of NAMES list"))

((mode 10 "MODE #chan")
 (0.0 ":irc.foonet.org 324 chester #chan +nt")
 (0.0 ":irc.foonet.org 329 chester #chan 1623563121")
 (0.0 ":alice!~u@wyb9b355rgzi8.irc PRIVMSG #chan :chester, welcome!")
 (0.0 ":bob!~u@wyb9b355rgzi8.irc PRIVMSG #chan :chester, welcome!")
 (0 ":tester!~u@gq7yjr7gsu7nn.irc NICK :dummy")
 (0.1 ":bob!~u@wyb9b355rgzi8.irc PRIVMSG #chan :alice: That ever eye with sight made heart lament.")
 (0.1 ":alice!~u@wyb9b355rgzi8.irc PRIVMSG #chan :bob: The bitter past, more welcome is the sweet.")
 (0.1 ":bob!~u@wyb9b355rgzi8.irc PRIVMSG #chan :alice: Dispatch, I say, and find the forester."))

((linger 10 LINGER))
