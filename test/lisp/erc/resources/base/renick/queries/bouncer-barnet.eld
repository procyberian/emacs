;; -*- mode: lisp-data; -*-
((pass 10 "PASS :barnet:changeme"))
((nick 10 "NICK tester"))
((user 10 "USER user 0 * :tester")
 (0 ":irc.barnet.org 001 tester :Welcome to the barnet IRC Network tester")
 (0 ":irc.barnet.org 002 tester :Your host is irc.barnet.org, running version oragono-2.6.0-7481bf0385b95b16")
 (0 ":irc.barnet.org 003 tester :This server was created Tue, 01 Jun 2021 07:49:23 UTC")
 (0 ":irc.barnet.org 004 tester irc.barnet.org oragono-2.6.0-7481bf0385b95b16 BERTZios CEIMRUabefhiklmnoqstuv Iabefhkloqv")
 (0 ":irc.barnet.org 005 tester AWAYLEN=390 BOT=B CASEMAPPING=ascii CHANLIMIT=#:100 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 CHANTYPES=# ELIST=U EXCEPTS EXTBAN=,m FORWARD=f INVEX KICKLEN=390 :are supported by this server")
 (0 ":irc.barnet.org 005 tester MAXLIST=beI:60 MAXTARGETS=4 MODES MONITOR=100 NETWORK=barnet NICKLEN=32 PREFIX=(qaohv)~&@%+ STATUSMSG=~&@%+ TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 TOPICLEN=390 UTF8MAPPING=rfc8265 UTF8ONLY WHOX :are supported by this server")
 (0 ":irc.barnet.org 005 tester draft/CHATHISTORY=100 :are supported by this server")
 (0 ":irc.barnet.org 251 tester :There are 0 users and 3 invisible on 1 server(s)")
 (0 ":irc.barnet.org 252 tester 0 :IRC Operators online")
 (0 ":irc.barnet.org 254 tester 1 :channels formed")
 (0 ":irc.barnet.org 255 tester :I have 3 clients and 0 servers")
 (0 ":irc.barnet.org 265 tester 3 3 :Current local users 3, max 3")
 (0 ":irc.barnet.org 266 tester 3 3 :Current global users 3, max 3")
 (0 ":irc.barnet.org 422 tester :MOTD File is missing"))

((mode-user 10 "MODE tester +i")
 ;; No mode answer
 (0 ":irc.znc.in 306 tester :You have been marked as being away")
 (0 ":tester!~u@286u8jcpis84e.irc JOIN #chan")
 (0 ":irc.barnet.org 353 tester = #chan :@joe mike rando tester")
 (0 ":irc.barnet.org 366 tester #chan :End of /NAMES list.")
 (0 ":***!znc@znc.in PRIVMSG #chan :Buffer Playback...")
 (0 ":joe!~u@286u8jcpis84e.irc PRIVMSG #chan :[09:19:19] mike: Chi non te vede, non te pretia.")
 (0 ":mike!~u@286u8jcpis84e.irc PRIVMSG #chan :[09:19:28] joe: The valiant heart's not whipt out of his trade.")
 (0 ":***!znc@znc.in PRIVMSG #chan :Playback Complete.")
 (0 ":rando!~u@95i756tt32ym8.irc PRIVMSG tester :[09:18:20] Why'd you pull that scene at the arcade?")
 (0 ":rando!~u@95i756tt32ym8.irc PRIVMSG tester :[09:18:32] I had to mess up this rentacop came after me with nunchucks.")
 (0 ":irc.barnet.org NOTICE tester :[09:13:24] This server is in debug mode and is logging all user I/O. If you do not wish for everything you send to be readable by the server owner(s), please disconnect.")
 (0 ":irc.barnet.org 305 tester :You are no longer marked as being away"))

((mode 10 "MODE #chan")
 (0 ":irc.barnet.org 324 tester #chan +nt")
 (0 ":irc.barnet.org 329 tester #chan 1622538742")
 (0.1 ":joe!~u@286u8jcpis84e.irc PRIVMSG #chan :mike: By favors several which they did bestow.")
 (0.1 ":mike!~u@286u8jcpis84e.irc PRIVMSG #chan :joe: You, Roderigo! come, sir, I am for you."))

((privmsg-a 10 "PRIVMSG rando :Linda said you were gonna kill me.")
 (0.1 ":joe!~u@286u8jcpis84e.irc PRIVMSG #chan :mike: Play, music, then! Nay, you must do it soon.")
 (0.1 ":rando!~u@95i756tt32ym8.irc PRIVMSG tester :Linda said? I never saw her before I came up here.")
 (0.1 ":mike!~u@286u8jcpis84e.irc PRIVMSG #chan :joe: Of arts inhibited and out of warrant."))

((privmsg-b 10 "PRIVMSG rando :You aren't with Wage?")
 (0.1 ":joe!~u@286u8jcpis84e.irc PRIVMSG #chan :mike: But most of all, agreeing with the proclamation.")
 (0.1 ":rando!~u@95i756tt32ym8.irc PRIVMSG tester :I think you screwed up, Case.")
 (0.1 ":mike!~u@286u8jcpis84e.irc PRIVMSG #chan :joe: Good gentleman, go your gait, and let poor volk pass. An chud ha' bin zwaggered out of my life, 'twould not ha' bin zo long as 'tis by a vortnight. Nay, come not near th' old man; keep out, che vor ye, or ise try whether your costard or my ballow be the harder. Chill be plain with you.")
 ;; Nick change
 (0.1 ":rando!~u@95i756tt32ym8.irc NICK frenemy")
 (0.1 ":joe!~u@286u8jcpis84e.irc PRIVMSG #chan :mike: Till time beget some careful remedy.")
 (0.1 ":frenemy!~u@95i756tt32ym8.irc PRIVMSG tester :I showed up and you just fit me right into your reality picture.")
 (0.1 ":mike!~u@286u8jcpis84e.irc PRIVMSG #chan :joe: For I have lost him on a dangerous sea."))
