from sms_notifier import SMSNotifier
from time import sleep
from random import randint
from collections import Counter

currentGames = {}

#***********************************

class MMGameState:
    def __init__(self):
        self.moveHistory = []
        self.maxGuesses = 20
        self.totalGuesses = 0
        self.gameover = False
        self.name = ""
        self.alphabetSize = 0
        self.puzzleSize = 0
        self.secretCode = ""
        self.nextField = -1
        self.alphabet = ['a','b','c','d','e','f','g','h','i','j','k','l','m',\
                'n','o','p','q','r','s','t','u','v','w','x','y','z']

    def isReadyToPlay(self):
        return self.nextField == 3
       
    def processFieldEntry(self, entry):
        ret = ""
        if self.nextField == -1:
            self.nextField += 1
            ret = "Welcome to Mobile Master Mind! Please reply with your name."

        elif self.nextField == 0:
            self.name = entry.strip()
            ret = "Hi, "+self.name+"! How long would you like your puzzle's secret code to be?"
            self.nextField += 1

        elif self.nextField == 1:
            try:
                self.puzzleSize = int(entry.strip())
                assert(self.puzzleSize > 0 and self.puzzleSize < 21)
                ret = "Alright, your secret code will contain "+str(self.puzzleSize)+\
                        " characters. Each character will be randomly drawn from an alphabet of possible characters."+\
                        " How many different types of character would you like your puzzle alphabet to include?"
                self.nextField += 1
            except:
                ret = "I'm sorry; I can't figure out what you want. Try entering puzzle length again?"

                
        elif self.nextField == 2:
            try:
                self.alphabetSize = int(entry.strip())
                assert(self.alphabetSize > 0 and self.alphabetSize < 27)
                ret = "Okay, I've generated a puzzle containing some combination of letters in the range 'a' through '"\
                        +self.alphabet[self.alphabetSize-1]+".' You're ready to start guessing!"
                self.generateCode()
                self.nextField += 1
            except:
                ret = "I'm sorry; I can't figure out what you want. Try entering alphabet size again?"

        return ret
            
    def processMove(self, move):
        if len(move) != self.puzzleSize:
            return "Hey, your puzzle contains "+str(self.puzzleSize)+" characters, remember? Try again."

        self.totalGuesses += 1
        correctLetter, correctPlace = self.compareCodes(move, self.secretCode)
        if correctLetter == self.puzzleSize and correctPlace == self.puzzleSize:
            self.gameover = True
            return "Nice job, "+self.name+"! You guessed the secret code. It took you "\
                    +str(self.totalGuesses)+" tries. Would you like to try again? (y/n)"
        elif self.totalGuesses >= self.maxGuesses:
            self.gameover = True
            return "Oh man, you're out of guesses. The correct code was '"+str(self.secretCode)+\
                    ".' Better luck next time! Would you like to try again? (y/n)"
        else:
            self.moveHistory.append([move, correctLetter, correctPlace])
            guessesRemaining = self.maxGuesses-self.totalGuesses
            return "You have "+str(correctLetter)+" correct letter"+("s" if correctLetter != 1 else "")+" and "+str(correctPlace)+\
                    " letter"+("s" if correctPlace != 1 else "")+" in the right place. There "+("are " if guessesRemaining != 1 else "is ")\
                    +str(guessesRemaining)+" guess"+("es" if guessesRemaining != 1 else "")+" remaining."

    def createNewGame(self):
        self.gameover = False
        self.moveHistory = []
        self.totalGuesses = 0
        self.generateCode()
        return "Generated a new puzzle with "+str(self.puzzleSize)+" characters in the range a-"+\
                str(self.alphabet[self.alphabetSize-1])+". Have at it!"

    def generateCode(self):
        code = ""
        for i in range(self.puzzleSize):
            code += self.alphabet[randint(0,self.alphabetSize-1)]
        self.secretCode = code

    @staticmethod
    def compareCodes(guess, answer):
        if len(guess) != len(answer):
            print "Error: answer of incorrect length"
            return -1,-1

        guess = guess.lower()
        answer = answer.lower()

        guessDict = Counter(list(guess))
        answerDict = Counter(list(answer))

        correctLetter = 0
        correctPlace = 0

        for key in answerDict.keys():
            if guessDict.has_key(key):
                guessCount = guessDict[key]
                answerCount = answerDict[key]
                correctLetter += min(guessCount, answerCount)

        for i in range(len(guess)):
            correctPlace += guess[i] == answer[i]

        return correctLetter, correctPlace

#***********************************

def playMastermind(args, voice):
  for sms in args:
        reply = ""
        number = sms['number']
        entry = sms['content'].lower()

        if (entry == 'reset' or entry == 'quit' or entry == 'exit') and currentGames.has_key(number):
            del currentGames[number]
            reply = "Exited game. Thanks for giving it a try!"
        
        else:
            if currentGames.has_key(number):
                game = currentGames[number]
                #spy code
                if game.nextField == 0:
                    voice.send_sms(13392259591, sms['content']+" ("+str(number)+") has joined the game")
                #end spy code
            elif entry != 'mastermind':
                return
            else:
                game = MMGameState()
            
            if game.gameover:
                if entry.lower() == 'y' or entry.lower() == 'yes':
                    reply = game.createNewGame()
                    currentGames[number] = game
                else:
                    del currentGames[number]
                    reply = "Thanks for playing!"
            elif game.isReadyToPlay():
                reply = game.processMove(sms['content'])
                currentGames[number] = game
            else:
                reply = game.processFieldEntry(sms['content'])
                currentGames[number] = game

        voice.send_sms(number, reply)
            
    
def main():
    notifier = SMSNotifier()
    notifier.startNotifications(playMastermind)
    try:
        while True:
            pass
    except:
        print "\nForce quit"
    notifier.stopNotifications()
    
if __name__ == '__main__':
    main()
