#Instruction to build / test Cyren container

# run docker-compose up -d 

# cd to test folder, run following command:
perl cyren_test.pl --stream msg_spam.eml

# you should expect response similar to following:
~/g/email/xgemail-infrastructure/orchestrator/cyren/./msg_spam.eml [200 OK]
X-CTCH-PVer: 0000001
X-CTCH-Spam: Confirmed
X-CTCH-VOD: Unknown
X-CTCH-Flags: 0
X-CTCH-RefID: str=0001.0A02020C.5B96E816.007F,ss=1,re=0.000,recu=0.000,reip=0.000,pt=F_4810712,cl=4,cld=1,fgs=0
X-CTCH-Score: 0.000
X-CTCH-ScoreCust: 0.000
X-CTCH-Rules: 

# Check following wiki link for more information
https://wiki.sophos.net/display/NSG/CYREN+Integration