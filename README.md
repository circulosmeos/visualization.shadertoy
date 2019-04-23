# visualization.shadertoy addon for Kodi

This is a [Kodi](http://kodi.tv) visualization addon.

You can either install this version for [ODROID-C2](https://www.hardkernel.com/shop/odroid-c2/) with Kodi 17, or compile yourself for other platforms that has Kodi 17 installed (see [Build instructions](https://github.com/circulosmeos/visualization.shadertoy#build-instructions)).

**NOTE**: A version for [Raspberry Pi](https://www.raspberrypi.org/) 32-bits is available for testing purposes: see *[Installation of the zip file addon](https://github.com/circulosmeos/visualization.shadertoy#installation-of-the-zip-file-addon)*.

Tested on Kodi, from versions v14 to v17.6.

## Motivation

Installed addons in Kodi 17 packages for ODROID-C2 do not contain any visualization addon that shows something on screen. They've been compiled against OpenGL libraries, but in ODROID-C2 only [OpenGLESv2](https://en.wikipedia.org/wiki/OpenGL_ES) libraries use the Mali Graphics Processor, and the addon cmake ignored GLESv2 if GL is found.

## Installation of the zip file addon

**WARNING**: This addon has been compiled for **[ODROID-C2 devices](https://www.hardkernel.com/shop/odroid-c2/)** with odroid's Ubuntu 16.04 packaged **Kodi v17.6**.

**WARNING**: Do not install the zip file addon on devices different from ODROID-C2 unless you know that the hardware is compatible (linux arm64, [GLESv2](https://en.wikipedia.org/wiki/OpenGL_ES)). Nonetheless, you can compile it to produce your own zip file addon: see the [Build instructions](https://github.com/circulosmeos/visualization.shadertoy#build-instructions).

**NOTE**: A version for [Raspberry Pi 2](https://www.raspberrypi.org/products/) 32-bits (not tested on [RPi 1 or RPi 3](https://www.raspberrypi.org/products/)) is available for testing purposes: [go to the release info for RPi](https://github.com/circulosmeos/visualization.shadertoy/releases/tag/v3.14). The addon is stable, **but please, note that some shaders may hang the RPi** (RAM and GPU are different from those of ODROID-C2): if somebody do the work of deleting these ones from the json, I'd happily patch the zip!.

Tested on Kodi, from versions v14 to v17.6.

* Download the zip file *[visualization.shadertoy-3.14.zip](https://github.com/circulosmeos/visualization.shadertoy/releases/download/v3.14/visualization.shadertoy-3.14.zip)* to your ODROID-C2 device
* Install from your Kodi: `Addons > box icon on top left corner > Install from zip file`


If looking for the **RPi instructions**, please [go to the release info for RPi](https://github.com/circulosmeos/visualization.shadertoy/releases/tag/v3.14).

## shaders (visualizations)

More than 50 new shaders (visualizations) have been tested (and modified when needed) to run under the GPU Mali450 (ODROID-C2).   

See a [complete list of included shaders here](https://github.com/circulosmeos/visualization.shadertoy/wiki), including thumbnails in most cases!

Shaders can be easily added, removed or renamed modifying the json file `.kodi/addons/visualization.shadertoy/resources/presets_GLES.json`. If you are not using GLESv2, you must modify the file `presets.json` instead.

Please, note that filename or shader's name cannot exceed 41 chars.   

You can **search for, compile and test new shaders at [shadertoy.com](https://www.shadertoy.com)** - please, note that your browser will use your PC's GPU capabilities, so if you're gonna use the shader file on another hardware like [ODROID-C2](https://www.hardkernel.com/shop/odroid-c2/) or [RPi](https://www.raspberrypi.org/products/), you have to later test it there: [GLESv2](https://en.wikipedia.org/wiki/OpenGL_ES) and GPU's hardware will impose serious computation and language restrictions: take a look at your GPU capabilities and see this [quick reference to GLESv2](https://www.khronos.org/opengles/sdk/docs/reference_cards/OpenGL-ES-2_0-Reference-card.pdf) to start.

## Changes from original addon

This addon is forked from [v1.1.5 xbmc/visualization.shadertoy](https://github.com/xbmc/visualization.shadertoy/tree/v1.1.5), with additional commits from [popcornmix](https://github.com/popcornmix/visualization.shadertoy) like fixes and the **Randomise mode**.

Now new shaders can be easily added, removed or renamed modifying the json file `.kodi/addons/visualization.shadertoy/resources/presets_GLES.json`.

There's a problem with the time precision of Mali450 (13 bits!) that limited time duration of animations to 8 seconds before being restarted. Now there's a setting to raise that limit from 2x to 16x. As the time evolves, the animation can degrade in some shaders, but for shaders like [SHAPE](https://www.shadertoy.com/view/Mtl3WH) the multiplier runs smoothly. The time multiplier can also be set per shader in the json conf file as seventh parameter (by default is 1x, overriden by the global setting, if set).

Some shaders has been changed and other new ones have been added, like *[Alhambra](https://www.shadertoy.com/view/lss3R7)* or *[Voronoi - distances](https://www.shadertoy.com/view/ldl3W8)*.

Also, *cmake* now correctly compile against GLESv2 libraries.

OpenGLESv2 function `texture2DLodEXT` has been added to main.cpp with `#extension GL_EXT_shader_texture_lod : enable`.

**Notes for RPi version**: time multiplier (7th parameter) has been deleted from json file as it is not needed.

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

Now you can install the newly generated zip file *visualization.shadertoy-3.14.zip* from your Kodi.

## License

This project uses code from [jsmn JSON parser](https://github.com/zserge/jsmn) by Serge A. Zaitsev (see [src/jsmn](https://github.com/circulosmeos/visualization.shadertoy/tree/odroid-c2/src/jsmn)), under [MIT license](https://github.com/zserge/jsmn/blob/master/LICENSE):

	Copyright (c) 2010 Serge A. Zaitsev

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.

The rest, following the "GPL v2 or later" indication of [the original project at xbmc](https://github.com/xbmc/visualization.shadertoy), is [licensed under GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html).
