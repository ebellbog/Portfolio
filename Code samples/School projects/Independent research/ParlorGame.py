from sms_notifier import SMSNotifier
from batch_handler import safeBatch
from random import randint
from copy import copy
from time import sleep

#*****************************************************************************************************************

class ParlorManager:
    def __init__(self):
        self.gameHasBegun = False
        self.playerData = {}
        self.startingPlayers = {}
        self.waitingNumber = 0
        
    def addNewPlayer(self, voice, number, name): #requires special case(s) for offline emulation
        if self.playerData.has_key(number):
            if name == self.playerData[number]['name']:
                return "You've already joined, "+name+"!"
            else:
                self.playerData[number]['name'] = name
                return "Okay, changed name to "+name+"."
        else:
            self.playerData[number] = {'name':name, 'guesses':2}
            # spy code
            if voice:
                voice.send_sms(13392259591, name+" joined the game")
            # end spy
            return "Thanks for joining the game, "+name+"! Please await further instructions."
    
    def pairPlayers(self, firstPlayer, secondPlayer):
        self.playerData[firstPlayer]['target-number'] = secondPlayer
        self.playerData[firstPlayer]['target-name'] = self.playerData[secondPlayer]['name']

        self.playerData[secondPlayer]['target-number'] = firstPlayer
        self.playerData[secondPlayer]['target-name'] = self.playerData[firstPlayer]['name']
    
    def printPlayers(self):
        participatingPlayers = "Here are the names of all participating players: "
        for key in self.startingPlayers.keys():
            participatingPlayers += key+", "
        participatingPlayers = participatingPlayers[:-2]
        return participatingPlayers


    def startGame(self, voice): #requires special case(s) for offline emulation
        if len(self.playerData) < 3:
            return "Not enough players to start."

        for v in self.playerData.values():
            self.startingPlayers[v['name']] = None
        
        
        allPlayers = self.playerData.keys()
        oddKeyOut = 0
        while len(allPlayers) > 1:
            firstPlayer = allPlayers[0]
            
            index = randint(1, len(allPlayers)-1)
            secondPlayer = allPlayers[index]
            
            self.pairPlayers(firstPlayer, secondPlayer)
            
            del allPlayers[index] #probably important to do this one first
            del allPlayers[0]
            
        if len(allPlayers) == 1:
            self.waitingNumber = allPlayers[0] #yeah, there isn't a uniform probability distribution for this; you could *maybe* guess who...
            self.playerData[self.waitingNumber]['target-number'] = 'none'
            self.playerData[self.waitingNumber]['target-name'] = 'no one'
            print "odd number"
        
        participatingPlayers = self.printPlayers()

        announcement1 = "The game is on! You have 2 attempts to guess your secret pair. You can text them like usual, or type 'guess [name]' if you think you know who they are."
        announcement2 = "You're going to start this first round sitting out, since there's an odd number of players. Keep it secret!"

        messages = {}
        messages['default'] = announcement1+" "+participatingPlayers
        messages[self.waitingNumber] = announcement2+" "+participatingPlayers

        if voice:
            safeBatch(voice, self.playerData.keys(), messages, 1)
        else:
            print "Starting game with messages: ",messages
        
        self.gameHasBegun = True
        return "Game successfully started!"
    
    def resetGame(self):
        self.gameHasBegun = False
        self.playerData = {}
        self.startingPlayers = {}
        print "Game has been reset."
        
    def pairingInfo(self):
        pairString = ""
        for key in self.playerData.keys():
            pairString += self.playerData[key]['name']+" is paired with "+self.playerData[key]['target-name']+"; "
        pairString = pairString+"(number "+str(self.waitingNumber)+" is waiting)"
        print pairString
        return pairString
        
    #**********************************
    def otherPlayerWins(self, voice, number): #requires special case(s) for offline emulation
        otherPlayerNumber = self.playerData[number]['target-number']

        self.playerData[otherPlayerNumber]['guesses'] = 2 #TODO: variable guess counts?
        reply = "Congrats! Looks like your pair ran out of guesses. You advance to the next round!"

        #end game scenario
        if len(self.playerData) == 2: #because the other player hasn't actually been deleted yet
            reply = "Your secret pair guessed wrong and you won! Like, the entire game. You guys were the last two players remaining. Go you!"
            #game gets reset on return
    
        elif self.waitingNumber:
            self.pairPlayers(otherPlayerNumber, self.waitingNumber)
            w_reply = "The wait is over! A new secret pair awaits you."
            if voice:
                voice.send_sms(self.waitingNumber, w_reply)
            else:
                print self.waitingNumber,"receives:",w_reply
            self.waitingNumber = 0
            reply += " A new partner has been selected already."
            
        else:
            self.waitingNumber = otherPlayerNumber
            self.playerData[otherPlayerNumber]['target-name'] = 'no one'
            self.playerData[otherPlayerNumber]['target-number'] = 'none'
            reply += " Hang tight, and we'll pair you with a new player as soon as they become available."
        
        if voice:
            voice.send_sms(otherPlayerNumber, reply)
        else:
            print otherPlayerNumber,"receives:",reply
        
    def otherPlayerLoses(self, voice, number): #requires special case(s) for offline emulation
        otherPlayerNumber = self.playerData[number]['target-number']
        reply = "Hate to say it, but it looks like your partner was able to figure out your identity. Better luck next time!"
        if voice:
            voice.send_sms(otherPlayerNumber, reply)
        else:
            print otherPlayerNumber,"receives:",reply
        del self.playerData[otherPlayerNumber]

    #**********************************

    def processGuess(self, voice, number, guess): #requires special case(s) for offline emulation
        answer = self.playerData[number]['target-name']
        if answer == 'no one':
            return "No point guessing until you have a new secret pair. We'll get you one soon!"
         
        if not self.startingPlayers.has_key(guess):
            return "No one by that name ever joined this game. Check your spelling maybe? "+self.printPlayers()

        if guess != answer:
            remainingGuesses = self.playerData[number]['guesses']-1
            if remainingGuesses == 0:
                self.otherPlayerWins(voice, number)
                del self.playerData[number]
                if len(self.playerData) == 1:
                    self.resetGame()
                return "I'm sorry, but you're incorrect and out of guesses! Game over, dude. Thanks for playing!"
            else:
                self.playerData[number]['guesses'] = remainingGuesses
                return "Nope! You're not texting "+guess+". You have "+str(remainingGuesses)+" guess remaining."
        
        else:
            self.playerData[number]['guesses'] = 2 #TODO: variable guess counts?
            self.otherPlayerLoses(voice, number)            

            #end game scenario
            if len(self.playerData) == 1:
                self.resetGame()
                return "Shit, you won! Like, the entire thing. You're the last player remaining. Go you!"
            elif self.waitingNumber:
                self.pairPlayers(number, self.waitingNumber)
                reply =  "The wait is over! A new secret pair awaits you."
                if voice:
                    voice.send_sms(self.waitingNumber,reply)
                else:
                    print self.waitingNumber,"receives:",reply
                self.waitingNumber = 0
                return "Hey, smart guess - you advance to the next round! A new partner has been selected."
            
            else:
                self.waitingNumber = number
                self.playerData[number]['target-name'] = 'no one'
                self.playerData[number]['target-number'] = 'none'
                return "Hey, smart guess! We'll pair you with a new player as soon as they become available."
            
    def forwardMessage(self, voice, number, content): #requires special case(s) for offline emulation
        forwardingNumber = self.playerData[number]['target-number']
        if forwardingNumber == 'none':
            reply = "You're not currently paired with anyone. Please wait for a new pair to become available."
            if voice:
                voice.send_sms(number, reply)
            else:
                print number,"receives:",reply
        else:
            if voice:
                voice.send_sms(forwardingNumber, content)
            else:
                print forwardingNumber,"receives:",content

#*****************************************************************************************************************

manager = ParlorManager()

def playParlorGame(args, voice): #requires special case(s) for offline emulation
    for sms in args:
        content = sms['content']
        number = sms['number']
        
        reply = ""
        
        if manager.gameHasBegun == False:
            tokens = content.split(" ")
            tokens[0] = tokens[0].lower()
            if len(tokens) == 2 and tokens[0] == 'parlor':
                if tokens[1].lower() == 'start':
                    reply = manager.startGame(voice)
                elif tokens[1].lower() == 'reset':
                    manager.resetGame()
                    reply = "Game has been reset."
                else:
                    reply = manager.addNewPlayer(voice, number, tokens[1])
            elif manager.playerData.has_key(number): #I don't like this, from an OOP standpoint
                reply = "Hold on a sec; we're waiting for more players."
            else:
                return
        else:
            tokens = content.split(" ")
            tokens[0] = tokens[0].lower()
            if content.lower() == 'parlor reset': 
                manager.resetGame()
                reply = "Game has been reset."
            elif content.lower() == 'parlor cheat':
                reply = manager.pairingInfo()
            elif manager.playerData.has_key(number):
                if len(tokens) == 2 and tokens[0] == 'guess':
                    reply = manager.processGuess(voice, number, tokens[1])
                else:
                    manager.forwardMessage(voice, number, content)
            else:
                reply = "Sorry; the game has already begun, and you're not participating. Please wait until the next game."
        
        if reply != "":
            if voice:
                voice.send_sms(str(number), reply)
            else:
                print number,"receives:",reply

def m(number,content):
    """
    shortcut to emulates a received SMS
    """
    sms = {'number':number,'content':content}
    playParlorGame([sms],None)

def main():
    notifier = SMSNotifier()
    notifier.startNotifications(playParlorGame)
    try:
        while True:
            pass
    except:
        print "\nForce quit"
    notifier.stopNotifications()
    
if __name__ == '__main__':
    main()
