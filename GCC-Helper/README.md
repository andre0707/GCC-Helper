# GCC-Helper

## Introduction

GCC-Helper (GeoCachingChallenge-Helper) is a small simple app to help you check if the geocacher who logged your challenge caches actually did qualify to log your cache. To check if a geocacher qualified, the challenge cache needs to have a valid challenge checker on project-gc.com.
You will need a valid geocaching.com account to use this app. Please log in with your account in the main browser view on the left side of the app.
A geocaching.com premium account is optional, but for some geocache listings required.
A project-gc.com premium account is also optional, however there is a challenge checker use limit for none-premium members.


## Manual

The app has mainly two parts. On the left hand there is a big browser with a textfield above to enter a url. On the right hand you find several actions in form of buttons as well as a table view. The table view will include geocacher who wrote logs on a geocache website you analysed. 
There is also a log view at the bottom which will give some feedback about actions and potential occuring errors.

### Fill the table

Visit any geocache on a geocaching.com website and use the *Read Logs* button to receive the visible logs from the website. The website will not load all logs initially. So you first may need to scroll down to load all the logs you are interested in.
All found logs on the website will be analysed and filtered by their log type. Only _found it_ logs will be considered. The geocacher who wrote this log will be listed in the table view.

### Geocacher actions

Once you filled the table view, you have the option to select a geocacher in the table. You can then use the
- _Open Log_ button to open the log this geocacher wrote in the main browser window on the left
- _Message User_ button to open the geocaching.com message center in the main browser window on the left to message this geocacher

To check if the selected user actually qualified for the challenge, open the challenge checker website on project-gc.com. If a valid project-gc.com website is opened in the browser, the check functionalities will also enable
- _Check User_ button will use the geocacher name of the selected row in the table view and set it into the challenge checker and then automatically perform the challenge check
- _Check All User_ button will start with the top of the list and then automatically perform the challenge check for all users in the table view. The checker needs some time to execute, so there is an option to pick a waiting time to wait for the checker. For most accurate results use 60 seconds, that is the longest the checker should run. Depending on traffic and your account status the checker may run a while. Waiting long enough will make sure that GCC-Helper reads the result for the correct user.

 In both check cases, GCC-Helper will display the checker result with a green checkmark or red x in the table view. This way you can easily see who actually qualified for the challenge.


## Technical information

GCC-Helper uses some javascript injection to interact with the websites. All injections are user initiated.
Please check source code for further information.
