# NKTcontrol
## Matlab controller for NKT's super continuum lasers

This code gives you access to control the NKT SuperK Extreme Supercontinuum White Light Laser and accompanying SuperK Select AOTF with RF Driver directly from Matlab. This code is adopted from the fork parent repository at https://github.com/villadsegede/NKTcontrol but with functions for our SuperK Select instead of their NKT Varia filter.  The code should be self-explanatory, but here is a simple example of it's use (assuming that the matlab file is either in the same folder or in your path):

```
laser = NKTControl
laser.connect()
laser.setSelectChannels([1,2],[550,650],[100,100],[100,100])
laser.setPowerLevel(10)
laser.RFon()
laser.emissionOn() % Should produce a beam of green and red of the same intensities
```

Please note that the addresses for the laser and Select are hardcoded towards the end of the file. Furthermore, please consider contributing to this software if you are modifying it (e.g. to use with other hardware as I have here :).
