# visualization.shadertoy addon for Kodi

This is a [Kodi](http://kodi.tv) visualization addon.

**WARNING**: This addon has been compiled for **[ODROID-C2 devices](https://www.hardkernel.com/shop/odroid-c2/)** with odroid's Ubuntu 16.04 packaged **Kodi v17.6**.

**WARNING**: Do not install on devices different from ODROID-C2 unless you know that the hardware is compatible (linux arm64, [GLESv2](https://en.wikipedia.org/wiki/OpenGL_ES)).

Not tested on versions different from Kodi v17.6.

## Motivation

Installed addons in Kodi 17 packages for ODROID-C2 do not contain any visualization addon that shows something on screen. They've been compiled against OpenGL libraries, but in ODROID-C2 only [OpenGLESv2](https://en.wikipedia.org/wiki/OpenGL_ES) libraries use the Mali Graphics Processor, and the addon cmake ignore GLESv2 if GL is found.

## Installation

* Download the zip file *[visualization.shadertoy-3.14.zip](https://github.com/circulosmeos/visualization.shadertoy/releases/download/v3.14/visualization.shadertoy-3.14.zip)* to your ODROID-C2 device
* Install from your Kodi: `Addons > box icon on top left corner > Install from zip file`

## Changes from original addon

This addon is forked from [v1.1.5 xbmc/visualization.shadertoy](https://github.com/xbmc/visualization.shadertoy/tree/v1.1.5), with additional commits from [popcornmix](https://github.com/popcornmix/visualization.shadertoy) like fixes and the **Randomise mode**.

Now new shaders can be easily added, removed or renamed using the json file `.kodi/addons/visualization.shadertoy/resources/presets_GLES.json`.

There's a problem with the time precision of Mali450 (13 bits!) that limited time duration of animations to 8 seconds before being restarted. Now there's a setting to raise that limit from 2x to 16x. As the time evolves, the animation can degrade in some shaders, but for shaders like [SHAPE](https://www.shadertoy.com/view/Mtl3WH) the multiplier runs smoothly. The time multiplier can also be set per shader in the json conf file as seventh parameter (by default is 1x, overriden by the global setting, if set).

Some shaders has been changed and other new ones have been added, like *[Alhambra](https://www.shadertoy.com/view/lss3R7)* or *[Voronoi - distances](https://www.shadertoy.com/view/ldl3W8)*.

Also, *cmake* now correctly compile against GLESv2 libraries.

OpenGLESv2 function `texture2DLodEXT` has been added to main.cpp with `#extension GL_EXT_shader_texture_lod : enable`.

## Build instructions

1. `git clone https://github.com/xbmc/xbmc.git`
2. `cd xbmc && git checkout tags/17.6-Krypton && cd ..`
3. `git clone https://github.com/circulosmeos/visualization.shadertoy.git`
4. `cd visualization.shadertoy && mkdir build && cd build`
5. `cmake -DADDONS_TO_BUILD=visualization.shadertoy -DADDON_SRC_PREFIX=../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../xbmc/kodi-build/addons -DPACKAGE_ZIP=1 ../../xbmc/project/cmake/addons`
6. `make`
7. `cd ../../xbmc/kodi-build/addons && strip visualization.shadertoy/visualization.shadertoy.so.3.14`
8. `zip -r --symlinks visualization.shadertoy-3.14.zip visualization.shadertoy/`
9. `cp visualization.shadertoy-3.14.zip /home/odroid/`

Now you can install the zip *[visualization.shadertoy-3.14.zip](https://github.com/circulosmeos/visualization.shadertoy/releases/download/v3.14/visualization.shadertoy-3.14.zip)* from your Kodi.
