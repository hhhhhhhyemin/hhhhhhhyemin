class DataScientist:
    def __init__(self):
        self.name = "HyeMin Park"
        self.role = "Data Scientist"
        self.age = "24"
        self.major = "statistics"
        
    def say_hi(self):
        print(f'Hi! My name is {self.name}.')
        print(f'I\'m a {self.age}-year-old bachelor\'s student in {self.major} who wants to become a {self.role}.')
        print("Thanks for dropping by, hope you find some of my work interesting.")
        
me = DataScientist()
me.say_hi()
