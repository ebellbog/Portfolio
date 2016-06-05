#
# SMS Notifier by Elana Bell Bogdan
# built on pygooglevoice
# includes extractSMS function by John Nagle (nagle@animats.com)
#

from voice import *
from time import sleep, time
from random import uniform
import sys, string, copy, threading
import BeautifulSoup

class NotificationThread(threading.Thread):
    def __init__(self, notifier):
        threading.Thread.__init__(self)
        self.target = notifier.notify
        self.args = (0)
    def run(self):
        self.target(self.args)
        

class SMSNotifier:
    def __init__(self):
        self.smsArchive = {}
        self.shouldRun = 0 # notifications thread terminates when this value is changed to 0
       
        self.idleDelay = 15 # amount of time, in seconds, between checking GVoice when there has been no recent activity ("idle mode")
        self.activeDelay = 1 # amount of time when there has been recent activity ("active mode")
        self.activePeriod = 120 # amount of time of no activity before SMSNotifier relapses into idle mode
        self.isIdle = True
        self.lastMessageArrived = 0
    
    def addSMStoArchive(self, newSMSdata):
        """
        parses HTML data for SMS content and adds any new SMSes to archive, based on a four-part hash:
        time, from, text, and count
        
        this method is sufficiently robust to handle fast successions of duplicate messages under most circumstances
        (unless ~30 other messages are sent within the same minute)
        
        returns list of new messages
        """
        newSMSes = [] #list of sms dictionaries to return
        newArchive = {} #temporary dictionary used for holding counts of duplicate messages
        
        #first pass to count and consolidate
        for sms in self.extractSMS(newSMSdata):
            if sms['from'] == 'Me:': #ignore outgoing messages
                continue
            
            key = hash(sms['time']+sms['from']+sms['text']) #id gets reused for all messages from a given number, so hash on this more unique key instead
                                                            #(yeah, this basically means that hash function gets applied twice)
            if newArchive.has_key(key):
                newArchive[key] = [sms, 1+newArchive[key][1]] #increment count of duplicated messages
            else:
                newArchive[key] = [sms, 0]
        
        #second pass to integrate into main archive
        for key in newArchive.keys():
            sms = newArchive[key][0]
            count = newArchive[key][1]
            
            if not self.smsArchive.has_key(key): 
            #entirely new entry; (will treat multiple messages sent within the last 1 sec as the same message)
                smsDict = {'time':sms['time'], 'number':sms['from'][1:-1], 'content':sms['text'], 'count':count}
                self.smsArchive[key] = smsDict
                newSMSes.append(smsDict)
            else:
                old_count = self.smsArchive[key]['count']
                self.smsArchive[key]['count'] = count
                if old_count < count: #i.e. there is a new (duplicate) message
                    newSMSes.append(self.smsArchive[key])
                    print "Received another copy - number",count,"- of message from",self.smsArchive[key]['number'],"."
            
        print "Added",len(newSMSes),"new message(s) to archive."
        return newSMSes
    
    def cleanedHTML(self, html) :
        """
        removes fields in HTML which change on each refresh; these include:
        -usage tip
        -relative timestamps
        
        returns the cleaned HTML
        """
        start = string.find(html, '<div class=\"gc-user-tip\"')
        end = string.find(html, '</div></div>', start)
        html = html[:start]+html[end+12:]
        
        start = string.find(html, '<span class=\"gc-message-relative\">')
        while (start >= 0):
            end = string.find(html, '</span>', start)
            html = html[:start]+html[end+7:]
            start = string.find(html, '<span class=\"gc-message-relative\">')
        
        return html
    
    def receivedNewSMS(self, savedHTML, newHTML):
        """
        performs a quick heuristic pass to determine whether any next texts may have arrived;
        returns True or False
        """
        return self.cleanedHTML(savedHTML) != self.cleanedHTML(newHTML)
    
    def extractSMS(self, htmlsms) :
        """    
        extractSMS  --  extract SMS messages from BeautifulSoup tree of Google Voice SMS HTML.
        Output is a list of dictionaries, one per message.
        
        (this function was borrowed from John Nagle, nagle@animats.com)
        """
        msgitems = [] # accum message items here
        # Extract all conversations by searching for a DIV with an ID at top level.
        tree = BeautifulSoup.BeautifulSoup(htmlsms) # parse HTML into tree
        conversations = tree.findAll("div",attrs={"id" : True},recursive=False)
        for conversation in conversations :
            # For each conversation, extract each row, which is one SMS message.
            rows = conversation.findAll(attrs={"class" : "gc-message-sms-row"})
            for row in rows :
                # For each row, which is one message, extract all the fields.
                msgitem = {"id" : conversation["id"]} # tag this message with conversation ID
                spans = row.findAll("span",attrs={"class" : True}, recursive=False)
                for span in spans : # for all spans in row
                    cl = span["class"].replace('gc-message-sms-', '')
                    msgitem[cl] = (" ".join(span.findAll(text=True))).strip() # put text in dict
                msgitems.append(msgitem) # add msg dictionary to list
        return msgitems
    
    def startNotifications(self, handler):
        """
        begins checking for new texts
        handler: function that gets called when a text is received; must take exactly two arguments:
                    1) an array of SMS dictionaries
                    2) a reference to the active Voice object
        """
        self.shouldRun = 1
        self.isIdle = False
        self.lastMessageArrived = time()
        notifierThread = threading.Thread(target=self.notify, args=(handler,))
        notifierThread.start()
        
    def stopNotifications(self):
        """
        tells the notifications thread to stop after it has finished its current loop;
        """
        self.shouldRun = 0

    def notify(self, handler):
        print "Starting notifications..."
        voice = Voice()
        voice.login()
        
        voice.sms()
        saved_sms = voice.sms.html
        self.addSMStoArchive(saved_sms)

        print "Waiting..."
        while self.shouldRun:
            voice.sms()
            sms_data = voice.sms.html
            if self.receivedNewSMS(saved_sms, sms_data):
                newMessages = self.addSMStoArchive(sms_data)
                saved_sms = sms_data
                if len(newMessages) > 0:
                    print "Received new message(s)!"
                    #handlerThread = threading.Thread(target=handler, args=(newMessages,voice))
                    #handlerThread.start()
                    handler(newMessages, voice)
                    print "Handler returned."

                self.lastMessageArrived = time()
                if self.isIdle:
                    self.isIdle = False
                    print "Notifier has become active."
                print "Waiting..."
            else:
                if not self.isIdle and time()-self.lastMessageArrived > self.activePeriod:
                    self.isIdle = True
                    print "Notifier has gone idle."
                # randomization with uniform() in feeble attempt not to look like a bot...
                sleep(self.idleDelay*uniform(0.85,1.15) if self.isIdle else self.activeDelay)
        print "Stopping notifications..."
        voice.logout()
