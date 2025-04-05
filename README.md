<img src="./img/pingthing.png" width="96" />

# PingThing

A lightweight macOS menubar app that displays a scrolling graph of ICMP latency to a target host or IP of your choice. The app is written in Swift, and is compiled as a universal binary for ARM and x86_64.

<img src="./img/menu.png" width="531" />

# Requirements

PingThing requires at least macOS 13. It is codesigned and notarized, so should run without too much fuss from Gatekeeper.

# Settings

Most settings should be self-explanatory. Here is an image of the Settings dialog:

<img src="./img/settings.png" width="632" />

You can choose a ping interval between 0.1 and 60 seconds.

**History size** controls how many response times are stored and displayed in the menubar graph. If you hover your mouse over the graph, a tooltip will show the current and average values:

<img src="./img/tooltip.png" width="536" />

The graph will dim/turn gray if network connectivity is interrupted, and will automatically resume upon reconnection:

<img src="./img/gray.png" width="284" />

<img src="./img/waiting.png" width="740" />

# Bugs? 🐛

There might be bugs! Also, I didn't write the ICMP code—I'm using the [SwiftyPing](https://github.com/samiyr/SwiftyPing) library. Please report [issues](https://github.com/luckman212/pingthing/issues) and I will do my best to address them.

> Inspired by [Pingr](https://getpingr.app/), which appears to have been abandoned in 2021.
